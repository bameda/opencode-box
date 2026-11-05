# opencode-box

Run [OpenCode 2](https://opencode.ai/v2/docs/) inside a Docker container that
**only sees the project you are working on**. Your `$HOME`, SSH keys, dotfiles
and every other project stay out of its reach.

```fish
cd ~/src/my-project
ocbox                                 # opencode in the current project
ocbox -s postgres,redis,mailpit       # ...with a DB, cache and test SMTP
ocbox -s mariadb,minio,caddy          # ...or whatever you need (see ocbox --list)
ocbox -p 3000 --shell                 # bash inside the box, port 3000
```

Auxiliary services (databases, caches, mail, queues, storage, proxy...) form a
**pluggable catalog** in `services/`: one file per service, and adding a new
image is a matter of copying a template. Optionally,
[Serena](https://github.com/oraios/serena) gives the agent symbol-level code
navigation and editing.

New here? [FIRST_STEPS.md](FIRST_STEPS.md) walks through adding a project
step by step.

## What the container sees

| Path in the container | Source | Access |
|---|---|---|
| `<project path>` (same as on the host) | the project | read-write |
| `<project>/.git` | the project | **read-only** (unless `--git-rw`) |
| `/home/dev` | `ocbox-home` volume | read-write (the box's own) |
| `/home/dev/.config/opencode` | this repo's `config/opencode` | read-write |

The container runs with your UID/GID (files it creates are owned by you),
without `sudo`, without capabilities (`cap_drop: ALL`) and with
`no-new-privileges`. The Docker socket is not mounted.

The `ocbox-home` volume is shared by all projects: it holds the opencode
login (`~/.local/share/opencode/auth.json`), sessions, tools installed with
mise and caches (npm, maven, cargo...).

## What it does NOT protect (read this)

- **Network.** The container has internet access (it needs it to talk to the
  model provider) and, by default, it also reaches everything your host
  reaches: your LAN and **corporate VPN networks** while the VPN is up, since
  traffic is NATed through your machine. If that worries you, block private
  networks from containers with a rule in the `DOCKER-USER` chain (for
  example, drop destinations `10.0.0.0/8` and `192.168.0.0/16` except what
  you need).
- **Whatever you run on the host afterwards.** The agent can edit any file
  in the project: `package.json`, `Makefile`, `.envrc`, scripts, tests... If
  you later run them outside the box, you run whatever it wrote. Review the
  diff first. That is why `.git` is read-only by default: hooks or a
  `core.fsmonitor` in `.git/config` would run on your host the next time you
  ran `git status`, without you noticing.
- **The `docker` group.** Being in the `docker` group is equivalent to being
  root on the host. To reduce that, use rootless Docker (see below).
- **Across projects.** The box's `$HOME` is shared, so an agent could leave
  something there (a `.bashrc`, a cache) that affects another project's
  session. If you need full separation, use another volume.

## Requirements (CachyOS)

```fish
sudo pacman -S docker docker-compose docker-buildx
sudo systemctl enable --now docker.service
sudo usermod -aG docker $USER   # log out and back in
```

Docker Compose ≥ 2.24 is required. All scripts are bash with a shebang, so
they work the same from fish.

## Installation

```fish
git clone git@github.com:<you>/opencode-box.git ~/src/opencode-box
cd ~/src/opencode-box
./install.sh            # links ~/.local/bin/ocbox and creates .env
$EDITOR .env            # opencode version, API keys (optional)
ocbox --build ~/src/my-project
```

If `~/.local/bin` is not in your PATH: `fish_add_path ~/.local/bin`.

The first time, run `/connect` inside opencode to authenticate with your
provider. Credentials are stored in the `ocbox-home` volume, not in your real
`$HOME`. Alternatively, put the keys (`ANTHROPIC_API_KEY`, etc.) in `.env`.

## Usage

```text
ocbox [options] [PROJECT_DIR] [-- COMMAND...]

  -s, --services LIST    catalog services: postgres,redis,mailpit...
  -l, --list             show the catalog
  -p, --port PORT        publish an opencode port on 127.0.0.1 (repeatable)
      --git-rw           let the agent write to .git (commits)
      --serena           enable Serena (--no-serena to disable it)
      --shell            bash instead of opencode
      --build / --rebuild
      --down             stop the project's services (keeps data)
      --purge            stop the services and delete their volumes
```

Examples:

```fish
ocbox -- opencode --continue                  # resume the last session
ocbox -s postgres -- psql                     # psql against the project's DB
ocbox -s postgres,valkey,caddy -p 5173 .      # app with DB, cache and proxy
ocbox --down                                  # stop the services when done
```

Each project gets its own compose project (`ocbox-<name>-<hash>`), so its
services and data are **independent** from other projects and you can have
several open at once. When you exit opencode the services keep running for
the next session; stop them with `ocbox --down`.

## Services

`ocbox --list` shows the catalog. Included out of the box:

| Service | Type | Hostname:port | Variables in the box | UI on the host |
|---|---|---|---|---|
| `postgres` | DB | `postgres:5432` | `DATABASE_URL`, `PG*` | |
| `mariadb` | DB (MySQL) | `mariadb:3306` | `MYSQL_URL`, `MYSQL_*` | |
| `mongodb` | document DB | `mongodb:27017` | `MONGODB_URL` | |
| `redis` | cache | `redis:6379` | `REDIS_URL` | |
| `valkey` | cache | `valkey:6379` | `VALKEY_URL` | |
| `memcached` | cache | `memcached:11211` | `MEMCACHED_SERVERS` | |
| `mailpit` | mail (SMTP) | `mailpit:1025` | `SMTP_HOST`, `SMTP_PORT` | `127.0.0.1:8025` |
| `minio` | S3 | `minio:9000` | `S3_ENDPOINT`, `AWS_*` | `127.0.0.1:9001` |
| `rabbitmq` | queues | `rabbitmq:5672` | `AMQP_URL` | `127.0.0.1:15672` |
| `caddy` | reverse proxy | — | `PROXY_URL` | `127.0.0.1:8080` |
| `ssh-target` | test SSH host | `ssh-target:22` | `SSH_TARGET_*`, `ANSIBLE_*` | |

Each service is reachable from the box by its name and exposes its
connection details as environment variables in the opencode container. The
`OCBOX_SERVICES` variable lists the active ones, and the global `AGENTS.md`
explains this to the agent. Credentials default to `dev`/`dev` (everything is
local).

PostgreSQL defaults to 18, the latest stable major, and requires 18 or newer
(see below for major upgrades).

Versions, credentials and ports are changed through variables: for all
projects in `.env`, or for one in `projects/<name>.env`. If you open two
projects at once with services that publish a UI, change the port in one of
them (`MAILPIT_UI_PORT=18025`, for example).

### PostgreSQL major upgrades

The major version is pinned (`POSTGRES_VERSION=18`) rather than following
`latest`, because each major keeps its data in its own subdirectory: when you
move to a new major, the project starts with an **empty database**. For a
development DB the simplest option is to re-run your migrations and seeds. To
keep the data, dump it first:

```fish
cd ~/src/my-project
ocbox -s postgres -- pg_dumpall -f .pg-upgrade.sql   # with the old version
# set POSTGRES_VERSION=19 and POSTGRES_CLIENT_VERSION=19 in .env, then:
ocbox --build -s postgres -- psql -f .pg-upgrade.sql
rm .pg-upgrade.sql
```

The old major's files stay in the volume until you run `ocbox --purge`.

`caddy` proxies to the dev server the agent starts (`opencode:3000` by
default, changed with `PROXY_UPSTREAM`). Edit `services/caddy/Caddyfile` for
routes to other services, headers, etc.

### Adding any other image

Copy `services/_template.yaml` to `services/<name>.yaml` and fill it in. The
rules are few:

1. The service has the same name as the file; that will be its hostname.
2. It must be in the `depends_on` of `opencode`, which is what makes `ocbox`
   start it (with `service_healthy` if it has a healthcheck).
3. Connection variables go in the `environment` of `opencode`.
4. Volumes without `name:` are per project. Ports are published on
   `127.0.0.1` through a variable, so they can be changed.
5. The first comment line is the description shown by `--list`.

This way you can add Keycloak, Elasticsearch/OpenSearch, Kafka, NATS,
ClickHouse, Meilisearch, an API mock or whatever you need, and they become
available to every project.

### Per-project settings

In `projects/` you can keep, by project directory name:

- `<name>.env`: default services, ports and `.git` rw, plus any service
  variable (versions, DB, UI ports...).
- `<name>.yaml`: a compose override for services only that project uses, or
  to tweak a catalog service (for example, PostGIS instead of PostgreSQL).

See `projects/example.*`. They live here and not inside the project on
purpose: if `ocbox` read a compose file from the project, the agent could
write one that mounted `/` and escaped.

### Languages and tools

The image ships the basics (git, ripgrep, fd, jq, build-essential, python3,
node, uv, the PostgreSQL 18 client tools from the official PGDG repository,
and the mysql/mariadb, redis-cli and sqlite3 clients) plus
[mise](https://mise.jdx.dev) for everything else. If the project has a
`mise.toml` or `.tool-versions`, `mise install` runs automatically on start:

```toml
# mise.toml in the project
[tools]
node = "22"
java = "temurin-21"
clojure = "latest"
rust = "stable"
```

Tools are kept in the `ocbox-home` volume, so they are downloaded only once.

If you always need something that is not available through mise, add it to
the `apt-get install` in the `Dockerfile` and run `ocbox --rebuild`.

### opencode configuration

`config/opencode/` is mounted as `~/.config/opencode`. That is where
`opencode.jsonc`, agents, commands and the global `AGENTS.md` go; the latter
already tells the agent it is in a box, that `.git` is read-only and how to
find the services. Since it is in the repo, it is versioned.

Automatic updates are disabled (see "OpenCode 2").

## Testing Ansible playbooks

The box works well for Ansible projects: the agent writes roles and
playbooks and validates them with `ansible-lint` and `--syntax-check`. The
`ssh-target` service adds a disposable machine to **run them for real**
without touching your infrastructure.

What it provides:

- A Debian container reachable as `ssh-target`, with SSH, Python and a user
  `ansible` with passwordless sudo, so `become: true` works.
- A test key pair generated per project and mounted read-only in the box. The
  key only opens these targets; your real SSH keys never enter the box.
- `ANSIBLE_PRIVATE_KEY_FILE`, `ANSIBLE_REMOTE_USER` and
  `ANSIBLE_HOST_KEY_CHECKING` preset inside the box, so a minimal inventory is
  enough.

### Setup

In `projects/<name>.env`:

```dotenv
OCBOX_SERVICES=ssh-target
```

In the project's `mise.toml`, so ansible is installed in the box:

```toml
[tools]
python = "3.13"
"pipx:ansible" = "latest"
"pipx:ansible-lint" = "latest"
```

And a test inventory in the project, for example `inventories/test/hosts.ini`:

```ini
[web]
ssh-target
```

The first `ocbox` builds the target's image; after that it starts in a
couple of seconds.

### Usage

Ask the agent to test the playbook against the test inventory, or do it
yourself from `ocbox --shell`:

```bash
ansible -i inventories/test all -m ping
ansible-playbook -i inventories/test site.yml
ansible-playbook -i inventories/test site.yml   # 2nd run: changed=0
ssh -i "$SSH_TARGET_KEY" ansible@ssh-target    # look around by hand
```

The second run is the idempotence check: a well-written playbook must
report no changes. To start again from a clean machine, run `ocbox --down`:
the target's filesystem is not persisted.

Once it works, apply it to your real infrastructure **from the host**,
first with `--check --diff`. The vault password and the real SSH keys stay
outside the box.

### Several targets or another distribution

To test against Ubuntu or another Debian release, set the base image in
`projects/<name>.env` (it must use apt) and rebuild with `ocbox --build`:

```dotenv
SSH_TARGET_BASE_IMAGE=ubuntu:24.04
```

For several hosts (for example, a web and a db group), add more targets in
`projects/<name>.yaml`; they share the same test key:

```yaml
services:
  opencode:
    depends_on:
      ssh-target-2:
        condition: service_healthy
  ssh-target-2:
    build:
      context: ./services/ssh-target
      args:
        BASE_IMAGE: ${SSH_TARGET_BASE_IMAGE:-debian:trixie-slim}
    environment:
      KEY_OWNER_UID: ${HOST_UID:-1000}
    volumes:
      - ssh-target-keys:/keys
```

### Limitations

- There is no systemd in the targets, so tasks such as
  `systemd: name=nginx state=started enabled=true` fail there. Validate those
  parts with `--check` against a real or virtual machine.
- Only Debian/Ubuntu bases are supported, since the image is built with apt.
- Molecule's Docker driver is not usable: it needs the Docker socket, which
  the box never gets.

## Serena

[Serena](https://github.com/oraios/serena) is an MCP server that runs the
project's language servers and gives the agent symbol-level tools: find a
definition, list references, inspect a file's structure or replace the body
of a specific function. In large repos it saves a lot of context compared to
`grep` and reading whole files. It is especially useful with OpenCode 2,
which does not run language servers itself.

It is installed in the image (under `/opt`, out of the agent's reach) and
**enabled per project**:

```fish
ocbox --serena                                # one-off
echo OCBOX_SERENA=1 >> projects/my-app.env    # always for that project
```

When enabled, the entrypoint generates `/etc/opencode/opencode.json`
(OpenCode's system config, which has the highest precedence) with Serena as a
local MCP server, launched with the `ide` context and pinned to the current
project. That file is regenerated on every start, so there is nothing to
change in `config/opencode`.

Details:

- **Language servers.** Serena downloads many of them by itself and keeps
  them in `~/.serena` (`ocbox-home` volume), so only the first run is slow.
  Some need the language runtime: for Clojure/Java, declare `java` and
  `clojure` in the project's `mise.toml`. See the
  [language support docs](https://oraios.github.io/serena/01-about/020_programming-languages.html).
- **Project data.** Serena stores `project.yml` and its "memories" (notes the
  agent writes about the project) in `.serena/` inside the project. Decide
  whether to commit it or add it to `.gitignore`.
- **Dashboard.** Disabled, since there is no browser inside the box. To use
  it, set `OCBOX_SERENA_DASHBOARD=1` in `.env` or `projects/<name>.env` and
  open `http://127.0.0.1:24282/dashboard/` (port configurable with
  `OCBOX_SERENA_DASHBOARD_PORT`).
- **Code Mode.** By default OpenCode 2 groups MCP tools behind its Code Mode.
  It is disabled for Serena so its tools show up directly and the model uses
  them more. `OCBOX_SERENA_CODEMODE=1` reverts that.
- **Version.** `SERENA_VERSION` in `.env` and `ocbox --build`. With
  `INSTALL_SERENA=0` the image is built without it.

## OpenCode 2

The image installs the `@opencode/cli` npm package, which is OpenCode 2
(`opencode` command). Notes about v2 relevant here:

- The global config lives in `config/opencode/opencode.jsonc` (native v2
  format), and the terminal client config (`cli.json`) is created by the TUI
  in that same directory.
- It does not run language servers or provide LSP diagnostics; hence Serena
  and the instruction in `AGENTS.md` to validate with lint/typecheck/tests.
- `update` is set to `"disable"`: the image pins the version. To update,
  change `OPENCODE_VERSION` in `.env` and run `ocbox --build`, or
  `ocbox --rebuild` if you are on `latest`.

## Rootless Docker

With rootless Docker, the container's root maps to your host user and every
other UID to subuids. In that case, to keep project files owned by you, set
`OCBOX_HOST_UID=0` and `OCBOX_HOST_GID=0` in `.env` and run `ocbox --rebuild`.
There is still no `sudo`, and the container's root is not root on your
machine.

## Known limitations

- Dragging images into the terminal passes the host path, which does not
  exist inside the container. Copy the image into the project and reference it
  from there.
- Without `--git-rw` the agent cannot commit, branch or stash; you do that
  from the host after reviewing the diff.
- There are no SSH keys inside: `git push` and `git pull` happen on the host.
- If you change UID or rebuild with another user, you may need to fix the
  volume's permissions: `docker volume rm ocbox-home` (you will lose the
  login and caches).

## Maintenance

```fish
ocbox --rebuild                     # update the image and opencode
docker volume ls | grep ocbox       # volumes (home + per-project DBs)
docker volume rm ocbox-home         # full reset of the box's $HOME
```
