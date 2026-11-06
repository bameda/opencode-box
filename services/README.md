# Services

The catalog of auxiliary services: databases, caches, mail, storage, queues
and test infrastructure. Each one lives in its own directory under
`services/`, with a `compose.yaml` that defines it and a `README.md` that
explains how to use it. `ocbox --list` shows what is available.

## Catalog

| Service | What for | Inside the box | On your host |
|---|---|---|---|
| [`postgres`](postgres/README.md) | PostgreSQL database | `postgres:5432`, `DATABASE_URL`, `PG*` | |
| [`mariadb`](mariadb/README.md) | MySQL-compatible database | `mariadb:3306`, `MYSQL_URL`, `MYSQL_*` | |
| [`mongodb`](mongodb/README.md) | Document database | `mongodb:27017`, `MONGODB_URL` | |
| [`redis`](redis/README.md) | Cache, sessions, queues | `redis:6379`, `REDIS_URL` | |
| [`valkey`](valkey/README.md) | Open-source Redis fork | `valkey:6379`, `VALKEY_URL` | |
| [`memcached`](memcached/README.md) | Key-value cache | `memcached:11211`, `MEMCACHED_SERVERS` | |
| [`mailpit`](mailpit/README.md) | Catches outgoing email | `mailpit:1025`, `SMTP_HOST`, `SMTP_PORT` | inbox at `127.0.0.1:8025` |
| [`minio`](minio/README.md) | S3-compatible storage | `minio:9000`, `S3_ENDPOINT`, `AWS_*` | console at `127.0.0.1:9001` |
| [`rabbitmq`](rabbitmq/README.md) | Message broker | `rabbitmq:5672`, `AMQP_URL` | UI at `127.0.0.1:15672` |
| [`kafka`](kafka/README.md) | Kafka-compatible broker (Redpanda) | `kafka:9092`, `KAFKA_BOOTSTRAP_SERVERS` | |
| [`nats`](nats/README.md) | Messaging with JetStream | `nats:4222`, `NATS_URL` | |
| [`jaeger`](jaeger/README.md) | OpenTelemetry traces | `jaeger:4318`, `OTEL_EXPORTER_OTLP_ENDPOINT` | UI at `127.0.0.1:16686` |
| [`wiremock`](wiremock/README.md) | Mock of external HTTP APIs | `wiremock:8080`, `WIREMOCK_URL` | |
| [`caddy`](caddy/README.md) | Reverse proxy | `PROXY_URL` | `127.0.0.1:8080` |
| [`kwok`](kwok/README.md) | Simulated Kubernetes API, for charts and manifests | `kwok:8080`, `KUBECONFIG` | |
| [`registry`](registry/README.md) | OCI registry, for Helm charts and artifacts | `registry:5000`, `OCI_REGISTRY` | `127.0.0.1:5000` |
| [`ssh-target`](ssh-target/README.md) | Disposable host for Ansible tests | `ssh-target:22`, `SSH_TARGET_*`, `ANSIBLE_*` | |

## How services work

Paths such as `projects/<name>/project.env` refer to your configuration
directory, `~/.config/ocbox` (see [Configuration](../docs/configuration.md)).

**Enable** services per project in `projects/<name>/project.env` (or one-off
with `ocbox -s`):

```dotenv
OCBOX_SERVICES=postgres,redis,mailpit
```

**Each service runs in its own container**, from its official image, and is
reachable from the box by its name (`postgres`, `redis`...). Its connection
details are set as environment variables in the box, so your
app and the agent find them without configuration. Run `env` in
`ocbox --shell` to see them all.

**Credentials** default to `dev`/`dev`: everything is local and never exposed
beyond your machine.

**Settings** (versions, credentials, ports) are changed through variables:
in `ocbox.env` for every project, or in `projects/<name>/project.env` for
one. Each service's README lists them with their defaults.

**Data** is per project: two projects using `postgres` get separate
databases. Services keep running when you exit the agent.

| Command | Effect |
|---|---|
| `ocbox --down` | Stops the project's services. Data in volumes is kept. |
| `ocbox --purge` | Stops them and deletes all their data. |

**From your host.** Services with a web UI publish it on `127.0.0.1` (see
each section). Databases are not published by default; to connect a desktop
tool (DBeaver, TablePlus, RedisInsight...), publish the port in
`projects/<name>/compose.yaml`:

```yaml
services:
  postgres:
    ports:
      - "127.0.0.1:15432:5432"
```

Use a host port that does not clash with other projects or with services
running on your machine.

## Adding your own service

Any image can become a service. Copy `services/_template/` and fill in its
two files: `compose.yaml` (the service) and `README.md` (how to use it).
Where you put the copy decides who can use it:

| Location | Available to |
|---|---|
| `~/.config/ocbox/projects/<project>/services/<name>/` | that project only |
| `~/.config/ocbox/services/<name>/` | all your projects |
| `services/<name>/` in this repository | everyone using opencode-box (send a pull request) |

They are looked up in that order and the first one found wins, so a
project's service can replace one of yours, and yours can replace one from
the catalog. `ocbox --list` marks them as `[project]` or `[yours]`.

The rules are few:

1. The service has the same name as its directory; that is its hostname.
2. It must be in the `depends_on` of `box`, which is what makes `ocbox`
   start it (with `service_healthy` if it has a healthcheck).
3. Connection variables go in the `environment` of `box`.
4. Volumes without `name:` are per project. Ports are published on
   `127.0.0.1` through a variable, so they can be changed.
5. The first comment line is the description shown by `ocbox --list`.
6. Relative paths resolve against the opencode-box repository. To refer to
   files in your configuration, use `${OCBOX_CONFIG_DIR}` or, for the
   project's directory, `${OCBOX_PROJECT_CONFIG}`.
7. Document it in its `README.md`, following the structure of the existing
   ones. In the catalog, also add a row to the table above.

This way you can add Keycloak, Elasticsearch/OpenSearch, Kafka, NATS,
ClickHouse, Meilisearch, an API mock or whatever you need. The
[`reference`](../examples/projects/reference/services/elasticsearch/) example
project has a complete one.
