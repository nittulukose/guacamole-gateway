-- =====================================================================
-- This runs AFTER 01-schema.sql (generated at container start, see the
-- README in this folder). It wires up group-based RBAC on top of the
-- identities Guacamole will pull live from LDAP:
--
--   1. Create USER_GROUP entities in the Guacamole DB whose names
--      EXACTLY match the LDAP group cn values ("ssh-users",
--      "desktop-users"). Guacamole merges group membership reported
--      by the LDAP extension with permissions granted to a
--      same-named group in the database extension - no user rows,
--      roles, or per-user bindings are created here at all.
--   2. Create the 3 target-machine connections.
--   3. Give each connection its NPA (Non-Personal Account) login
--      parameters - a fixed local service account on the target
--      machine, completely independent of the caller's own LDAP
--      identity/password.
--   4. Grant READ on the SSH connections to "ssh-users" and READ on
--      the RDP connection to "desktop-users".
-- =====================================================================

-- 1. Group entities -----------------------------------------------------
INSERT INTO guacamole_entity (name, type) VALUES ('ssh-users', 'USER_GROUP');
INSERT INTO guacamole_entity (name, type) VALUES ('desktop-users', 'USER_GROUP');
INSERT INTO guacamole_entity (name, type) VALUES ('guac-admins', 'USER_GROUP');

INSERT INTO guacamole_user_group (entity_id, disabled)
SELECT entity_id, FALSE
FROM guacamole_entity
WHERE type = 'USER_GROUP' AND name IN ('ssh-users', 'desktop-users', 'guac-admins');

-- 2. Connections ----------------------------------------------------------
INSERT INTO guacamole_connection (connection_name, protocol)
VALUES ('Linux Server 1 (SSH)', 'ssh');

INSERT INTO guacamole_connection (connection_name, protocol)
VALUES ('Linux Server 2 (SSH)', 'ssh');

INSERT INTO guacamole_connection (connection_name, protocol)
VALUES ('Linux Desktop (RDP)', 'rdp');

-- 3a. SSH Server 1 parameters (NPA login) ---------------------------------
INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'hostname', 'target-ssh-1'
FROM guacamole_connection WHERE connection_name = 'Linux Server 1 (SSH)';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'port', '22'
FROM guacamole_connection WHERE connection_name = 'Linux Server 1 (SSH)';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'username', 'npa-svc'
FROM guacamole_connection WHERE connection_name = 'Linux Server 1 (SSH)';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'password', 'NpaPass123!'
FROM guacamole_connection WHERE connection_name = 'Linux Server 1 (SSH)';

-- 3b. SSH Server 2 parameters (NPA login) ---------------------------------
INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'hostname', 'target-ssh-2'
FROM guacamole_connection WHERE connection_name = 'Linux Server 2 (SSH)';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'port', '22'
FROM guacamole_connection WHERE connection_name = 'Linux Server 2 (SSH)';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'username', 'npa-svc'
FROM guacamole_connection WHERE connection_name = 'Linux Server 2 (SSH)';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'password', 'NpaPass123!'
FROM guacamole_connection WHERE connection_name = 'Linux Server 2 (SSH)';

-- 3c. Linux Desktop RDP parameters (NPA login) ----------------------------
INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'hostname', 'target-desktop'
FROM guacamole_connection WHERE connection_name = 'Linux Desktop (RDP)';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'port', '3389'
FROM guacamole_connection WHERE connection_name = 'Linux Desktop (RDP)';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'username', 'npa-desktop'
FROM guacamole_connection WHERE connection_name = 'Linux Desktop (RDP)';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'password', 'NpaPass123!'
FROM guacamole_connection WHERE connection_name = 'Linux Desktop (RDP)';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'ignore-cert', 'true'
FROM guacamole_connection WHERE connection_name = 'Linux Desktop (RDP)';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'security', 'any'
FROM guacamole_connection WHERE connection_name = 'Linux Desktop (RDP)';

-- 4. RBAC: group -> connection permissions --------------------------------
-- ssh-users -> both SSH connections
INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission)
SELECT e.entity_id, c.connection_id, 'READ'
FROM guacamole_entity e
JOIN guacamole_connection c
  ON c.connection_name IN ('Linux Server 1 (SSH)', 'Linux Server 2 (SSH)')
WHERE e.type = 'USER_GROUP' AND e.name = 'ssh-users';

-- desktop-users -> the RDP connection
INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission)
SELECT e.entity_id, c.connection_id, 'READ'
FROM guacamole_entity e
JOIN guacamole_connection c
  ON c.connection_name = 'Linux Desktop (RDP)'
WHERE e.type = 'USER_GROUP' AND e.name = 'desktop-users';


-- 5. Guacamole administration -------------------------------------------
-- guac-admins -> full Guacamole administration privileges

INSERT INTO guacamole_system_permission (entity_id, permission)
SELECT e.entity_id, p.permission::guacamole_system_permission_type
FROM guacamole_entity e
CROSS JOIN (
    VALUES
        ('ADMINISTER'),
        ('CREATE_CONNECTION'),
        ('CREATE_CONNECTION_GROUP'),
        ('CREATE_SHARING_PROFILE'),
        ('CREATE_USER'),
        ('CREATE_USER_GROUP')
) AS p(permission)
WHERE e.type = 'USER_GROUP'
  AND e.name = 'guac-admins';
