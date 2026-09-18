# SSH/RDP Gateway on Apache Guacamole

A local playground: users log into a Guacamole web portal with their LDAP
identity, see only the machines their group grants them, and click in to
SSH or RDP — without ever touching the target machine's own credentials.

## Architecture

```
                 ┌────────────┐
   Bob / Alice → │  Guacamole │──(authN)──► OpenLDAP (users, groups)
                 │   portal   │
                 │            │──(authZ)──► PostgreSQL (connections,
                 └─────┬──────┘              groups, permissions)
                       │
                       ▼
                    guacd
                       │
        ┌──────────────┼───────────────┐
        ▼              ▼               ▼
  target-ssh-1    target-ssh-2    target-desktop
   (SSH, NPA)       (SSH, NPA)       (RDP, NPA)
```

**Two separate identity stores, on purpose:**

| Store | Job |
|---|---|
| **OpenLDAP** | Who is allowed into the *portal*, and which group they're in. Bob and Alice's real passwords live only here. |
| **PostgreSQL** | What the portal contains: the 3 connections, and which *group* (not user) may see each one. Also holds the **NPA** credentials used to log into the target machines. |

Guacamole is configured with both the `guacamole-auth-ldap` and
`guacamole-auth-jdbc-postgresql` extensions loaded at once (the official
image auto-loads both when their env vars are present). LDAP does
authentication and reports each user's effective LDAP groups; the database
extension grants permissions to **USER_GROUP entities whose name matches
the LDAP group's `cn` exactly** (`ssh-users`, `desktop-users`). No
per-user role or connection binding is ever created — access is 100%
group-derived, matching the "do not bind users to access roles" requirement.

**NPA (Non-Personal Account):** each connection's login to the target
machine uses a fixed local service account (`npa-svc` for both SSH boxes,
`npa-desktop` for the RDP box) whose credentials are stored directly on
the Guacamole connection object. LDAP is never consulted for this second
hop — satisfying "no need to use LDAP to do target machine authentication."



## What gets created

| | |
|---|---|
| **Machines** | `target-ssh-1`, `target-ssh-2` (Ubuntu + OpenSSH), `target-desktop` (Ubuntu + XFCE + xrdp) |
| **LDAP groups** | `ssh-users`, `desktop-users` (`groupOfNames`, seeded via LDIF — never through the Guacamole UI) |
| **LDAP users** | `guacadm` (Administrator),`bob` (member of `ssh-users`), `alice` (member of `desktop-users`) |
| **Guacamole RBAC** | `guac-admins` - Administrator Access; `ssh-users` → READ on both SSH connections; `desktop-users` → READ on the RDP connection |




## Running it

```bash
cd guac-gateway
docker compose up -d --build
```

First boot does two things automatically before Guacamole is reachable:
1. `schema-generator` dumps the official Guacamole/PostgreSQL schema into
   a volume (see `guac-db-init/README.md`) — Postgres then applies it plus
   `02-groups-and-connections.sql` on its own init.
2. `openldap` imports `ldap/bootstrap.ldif` on first start.




## Guacamole Dashboard

**http://localhost:3000/guacamole**.

- Log in as `guacadmin` / `CHECK .env for password` → ** Gaucamole Administration **

- Log in as `bob` / `CHECK .env for password` → sees **Linux Server 1 (SSH)** and
  **Linux Server 2 (SSH)** only.

- Log in as `alice` / `CHECK .env for password` → sees **Linux Desktop (RDP)** only.



## LDAP Admin DashBoard

**http://localhost:8081**.

- Log in as `cn=admin,cn=config` / `CHECK .env for password` → sees ** Users and Groups Management **
