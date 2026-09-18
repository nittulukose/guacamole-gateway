This directory only ships `02-groups-and-connections.sql`.

`01-schema.sql` (the official Guacamole JDBC/PostgreSQL schema — tables,
enums, indexes) is generated automatically the first time you run
`docker compose up`, by the one-off `schema-generator` service defined in
`docker-compose.yml`. It runs:

    /opt/guacamole/bin/initdb.sh --postgresql

from the official `guacamole/guacamole` image and writes the result into the
`guac-db-init` named volume as `01-schema.sql`. Postgres then executes
everything in that volume (plus this bind-mounted `02-...sql`) in filename
order on first startup, so the schema always lands before our group/
connection data. You never need to run this by hand.
