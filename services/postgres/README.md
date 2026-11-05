# PostgreSQL (`postgres`)

Part of the [service catalog](../../SERVICES.md). See
[How services work](../../SERVICES.md#how-services-work) for what is common
to every service: enabling, data, `--down`/`--purge` and host access.

**Enable**: `OCBOX_SERVICES=postgres` in `~/.config/ocbox/projects/<name>.env`, or `ocbox -s postgres`.

PostgreSQL relational database. Requires PostgreSQL 18 or newer.

**Inside the box**

| Variable | Value |
|---|---|
| `DATABASE_URL` | `postgres://dev:dev@postgres:5432/app` |
| `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE` | the same, split up |

Most frameworks and drivers read `DATABASE_URL` directly. The `PG*` variables
make the client tools connect without arguments.

**Explore it**

```bash
psql                                   # interactive shell on the project DB
psql -c '\dt'                          # list tables
createdb app_test                      # extra database, e.g. for tests
psql -c 'CREATE EXTENSION IF NOT EXISTS pg_trgm'
pg_dump -Fc -f .db.dump                # backup
pg_restore --clean -d "$PGDATABASE" .db.dump
dropdb --force "$PGDATABASE" && createdb "$PGDATABASE"   # empty the DB
```

**Data**: persisted in the project's `pgdata` volume.

**Settings**

| Variable | Default |
|---|---|
| `POSTGRES_VERSION` | `18` |
| `POSTGRES_CLIENT_VERSION` | `18` (client tools in the image; rebuild after changing) |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | `dev` / `dev` |
| `POSTGRES_DB` | `app` |

**Initial SQL.** To run scripts when the database is created, mount them in
`projects/<name>.yaml`. They only run on an empty database:

```yaml
services:
  postgres:
    volumes:
      - ${OCBOX_CONFIG_DIR}/projects/<name>-initdb:/docker-entrypoint-initdb.d:ro
```

**PostGIS or other images.** Swap the image in `projects/<name>.yaml`, as in
`projects/example.yaml`. It must be based on PostgreSQL 18 or newer.

## Major upgrades

The major version is pinned instead of following `latest`, because each
major keeps its data in its own subdirectory: moving to a new major starts
with an **empty database**. For a development DB, the simplest option is to
re-run your migrations and seeds. To keep the data, dump it first:

```fish
cd ~/src/my-project
ocbox -s postgres -- pg_dumpall -f .pg-upgrade.sql      # with the old version
# set POSTGRES_VERSION=19 and POSTGRES_CLIENT_VERSION=19 in ocbox.env, then:
ocbox --build -s postgres -- psql -d postgres -f .pg-upgrade.sql
rm .pg-upgrade.sql
```

Errors about the role or database already existing are expected. The old
major's files stay in the volume until you run `ocbox --purge`.
