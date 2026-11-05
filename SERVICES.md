# Services

The catalog of auxiliary services: databases, caches, mail, storage, queues
and test infrastructure. Each one lives in its own directory under
`services/`, with a `compose.yaml` that defines it and a `README.md` that
explains how to use it. `ocbox --list` shows what is available.

## Catalog

| Service | What for | Inside the box | On your host |
|---|---|---|---|
| [`postgres`](services/postgres/README.md) | PostgreSQL database | `postgres:5432`, `DATABASE_URL`, `PG*` | |
| [`mariadb`](services/mariadb/README.md) | MySQL-compatible database | `mariadb:3306`, `MYSQL_URL`, `MYSQL_*` | |
| [`mongodb`](services/mongodb/README.md) | Document database | `mongodb:27017`, `MONGODB_URL` | |
| [`redis`](services/redis/README.md) | Cache, sessions, queues | `redis:6379`, `REDIS_URL` | |
| [`valkey`](services/valkey/README.md) | Open-source Redis fork | `valkey:6379`, `VALKEY_URL` | |
| [`memcached`](services/memcached/README.md) | Key-value cache | `memcached:11211`, `MEMCACHED_SERVERS` | |
| [`mailpit`](services/mailpit/README.md) | Catches outgoing email | `mailpit:1025`, `SMTP_HOST`, `SMTP_PORT` | inbox at `127.0.0.1:8025` |
| [`minio`](services/minio/README.md) | S3-compatible storage | `minio:9000`, `S3_ENDPOINT`, `AWS_*` | console at `127.0.0.1:9001` |
| [`rabbitmq`](services/rabbitmq/README.md) | Message broker | `rabbitmq:5672`, `AMQP_URL` | UI at `127.0.0.1:15672` |
| [`caddy`](services/caddy/README.md) | Reverse proxy | `PROXY_URL` | `127.0.0.1:8080` |
| [`ssh-target`](services/ssh-target/README.md) | Disposable host for Ansible tests | `ssh-target:22`, `SSH_TARGET_*`, `ANSIBLE_*` | |

## How services work

**Enable** services per project in `projects/<name>.env` (or one-off with
`ocbox -s`):

```dotenv
OCBOX_SERVICES=postgres,redis,mailpit
```

**Each service runs in its own container**, from its official image, and is
reachable from the box by its name (`postgres`, `redis`...). Its connection
details are set as environment variables in the opencode container, so your
app and the agent find them without configuration. Run `env` in
`ocbox --shell` to see them all.

**Credentials** default to `dev`/`dev`: everything is local and never exposed
beyond your machine.

**Settings** (versions, credentials, ports) are changed through variables:
in `.env` for every project, or in `projects/<name>.env` for one. Each
section below lists them with their defaults.

**Data** is per project: two projects using `postgres` get separate
databases. Services keep running when you exit opencode.

| Command | Effect |
|---|---|
| `ocbox --down` | Stops the project's services. Data in volumes is kept. |
| `ocbox --purge` | Stops them and deletes all their data. |

**From your host.** Services with a web UI publish it on `127.0.0.1` (see
each section). Databases are not published by default; to connect a desktop
tool (DBeaver, TablePlus, RedisInsight...), publish the port in
`projects/<name>.yaml`:

```yaml
services:
  postgres:
    ports:
      - "127.0.0.1:15432:5432"
```

Use a host port that does not clash with other projects or with services
running on your machine.

## Adding your own service

Any image can join the catalog. Copy `services/_template/` to
`services/<name>/` and fill in its two files: `compose.yaml` (the service)
and `README.md` (how to use it). The rules are few:

1. The service has the same name as the directory; that will be its hostname.
2. It must be in the `depends_on` of `opencode`, which is what makes `ocbox`
   start it (with `service_healthy` if it has a healthcheck).
3. Connection variables go in the `environment` of `opencode`.
4. Volumes without `name:` are per project. Ports are published on
   `127.0.0.1` through a variable, so they can be changed.
5. The first comment line is the description shown by `ocbox --list`.

6. Document it in its `README.md`, following the structure of the existing
   ones, and add a row to the catalog table above.

This way you can add Keycloak, Elasticsearch/OpenSearch, Kafka, NATS, ClickHouse,
Meilisearch, an API mock or whatever you need, and they become available to
every project.

For a service only one project needs, put it in `projects/<name>.yaml`
instead (see `projects/example.yaml`).
