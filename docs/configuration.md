# Configuration

- [The configuration directory](#the-configuration-directory)
- [Keeping it in a private repository](#keeping-it-in-a-private-repository)
- [Global settings and secrets](#global-settings-and-secrets)
- [Per-project settings](#per-project-settings)
- [Your own services](#your-own-services)
- [opencode configuration](#opencode-configuration)
- [Languages and tools](#languages-and-tools)
- [Settings reference](#settings-reference)

## The configuration directory

Everything personal lives outside the opencode-box repository, in
`~/.config/ocbox`. To use another location, set `OCBOX_CONFIG_DIR`. This
way the repository can be shared and updated with `git pull` without
conflicts.

```
~/.config/ocbox/
├── ocbox.env           global settings (versions, ports, git identity...)
├── secrets.env         API keys; never committed
├── projects/           one directory per project (see below)
├── services/           optional: your own services
└── opencode/           opencode's global configuration
    ├── opencode.jsonc
    └── AGENTS.md       your personal instructions for the agent
```

`install.sh` creates it from the repository's `examples/config`. You can
also run `ocbox --init` at any time to add missing files: it never
overwrites existing ones.

The agent never sees this directory: `ocbox` refuses to mount a project that
contains it or is inside it, so the agent cannot change its own settings.

## Keeping it in a private repository

The configuration directory is meant to be a git repository of its own.
That gives you history for your settings and lets you use them on other
machines.

**Create it** (once):

```fish
cd ~/.config/ocbox
git init -b main
git add -A
git status          # no secrets.env may be listed
git commit -m "chore: initial ocbox configuration"
```

Create an **empty, private** repository on GitHub (or any git host), then
push to it:

```fish
git remote add origin git@github.com:<you>/ocbox-config.git
git push -u origin main
```

**Day to day**, commit whenever you add a project or change a setting:

```fish
cd ~/.config/ocbox
git add projects/my-app
git commit -m "chore: add my-app project"
git push
```

**On another machine**, pass the repository's URL to `install.sh` (or to
`ocbox --init`). It clones it into `~/.config/ocbox` and adds any missing
file from the examples:

```fish
~/src/opencode-box/install.sh git@github.com:<you>/ocbox-config.git
```

**What stays out of it**:

- Every `secrets.env`, the global one and the projects', is listed in the
  directory's `.gitignore`. Recreate them by hand on each machine (or log in
  with `/connect` instead of using an API key).
- The login, sessions and caches of the box live in the `ocbox-home` Docker
  volume, not here, so they are not synced either.

Keep the repository **private**: it lists your projects and their settings.

## Global settings and secrets

- **`ocbox.env`**: settings for every project, such as the OpenCode version,
  service versions, ports or your git identity. It is loaded first, so
  per-project settings take precedence. Safe to commit.
- **`secrets.env`**: API keys and other secrets. It is loaded after
  `ocbox.env` and has permissions `600`. Not needed if you log in with
  `/connect`.

Both are also passed as environment variables to the opencode container.
Each one documents its own options in comments.

## Per-project settings

Each project has its own directory in `projects/`, named after the
**project's directory**: for `~/src/my-app`, `projects/my-app/`. Every file
in it is optional:

```
projects/my-app/
├── project.env         settings: services, ports, Serena... and service variables
├── secrets.env         the project's secrets; never committed
├── compose.yaml        compose override: tweak a service for this project
├── AGENTS.md           private instructions for the agent in this project
├── services/<name>/    services only this project uses
└── ...                 any file the above refer to (initdb/, a Caddyfile...)
```

- **`project.env`**: the project's defaults (services, ports, Serena, `.git`
  access...) plus any service variable (database name, versions, UI
  ports...). Command-line options take precedence.

  ```dotenv
  OCBOX_SERVICES=postgres,mailpit
  OCBOX_PORTS="5173"
  OCBOX_SERENA=1
  POSTGRES_DB=myapp
  ```

- **`secrets.env`**: secrets only this project uses, such as the key of an
  external API it talks to. It is ignored by git, like the global one.
- **`compose.yaml`**: a Docker Compose override, merged on top of the box's
  own, to tweak a service for this project (for example, PostGIS instead of
  plain PostgreSQL).
- **`AGENTS.md`**: instructions for the agent that apply only to this
  project and that should not go into the project's own repository, because
  it belongs to your team or a client. They are added after the box's
  instructions and your personal ones.
- **`services/`**: services only this project needs, with the same layout as
  the [catalog](../services/README.md). See
  [your own services](#your-own-services).

The settings files are loaded in this order, and the last one wins:
`ocbox.env`, `secrets.env`, the project's `project.env`, the project's
`secrets.env`. All of them are also passed to the opencode container as
environment variables.

`ocbox --init` creates `projects/example/`, which uses every piece. To add a
project, copy it and keep only what you need:

```fish
cd ~/.config/ocbox
cp -r projects/example projects/my-app
```

Two details:

- **Paths.** In compose files, relative paths resolve against the
  opencode-box repository. To refer to files in the project's directory, use
  `${OCBOX_PROJECT_CONFIG}`, for example `${OCBOX_PROJECT_CONFIG}/initdb`.
- **Names.** Two projects with the same directory name share these settings.
  Their data and services are still separate, because those are keyed by the
  full path.

These files live here, and not inside the project, on purpose. A compose
file can mount any host path, so if `ocbox` read one from the project, the
agent could write one that mounted `/` and escaped the container the next
time you launched it. For the same reason, only `AGENTS.md` is visible
inside the box: the rest of the project's directory, secrets included, is
not.

## Your own services

Services are looked up in three places, and the first one found wins:

1. the project's `services/` (`projects/<name>/services/<service>/`);
2. your `services/` (`~/.config/ocbox/services/<service>/`);
3. the opencode-box [catalog](../services/README.md).

Your services work exactly like the catalog's: `ocbox -s <name>` and
`OCBOX_SERVICES` find them, and `ocbox --list` marks them as `[project]` or
`[yours]`. Put a service in the project when only that project needs it,
and in yours when you use it in several projects. A service with the same
name as one further down the list replaces it. See
[adding your own service](../services/README.md#adding-your-own-service).

## opencode configuration

The `opencode/` directory holds opencode's global configuration:
`opencode.jsonc` (model, agents, permissions, MCP servers...), plus
`agents/`, `commands/` and `skills/` if you use them.

- It is **mounted read-only** in the box and linked into
  `~/.config/opencode`, so edit it on your host, not from inside opencode.
  The files the TUI writes itself (such as `cli.json`) stay in the box's
  volume.
- The agent's **`AGENTS.md`** is built on every start from two parts: the
  box's own instructions, followed by your `opencode/AGENTS.md`. The box's
  instructions live in the repository (`docker/AGENTS.md`) and tell the agent
  it is in a container, that `.git` is read-only and how to find the
  services. Improvements to them arrive with `git pull` without touching
  yours.
- **Automatic updates** are disabled (`"update": "disable"`): the image
  decides the OpenCode version. See [Updating](installation.md#updating).

The image installs OpenCode 2, from the `@opencode/cli` npm package.
OpenCode 2 does not run language servers, so the box's instructions ask the
agent to validate changes with the project's lint, typecheck and tests;
[Serena](serena.md) fills that gap for code navigation.

## Languages and tools

The image includes:

- git, ripgrep, fd, jq and build-essential;
- python3, node and uv;
- the PostgreSQL client tools, from PostgreSQL's official repository;
- the mariadb/mysql, redis-cli and sqlite3 clients.

Everything else is installed per project with [mise](https://mise.jdx.dev).
If the project has a `mise.toml` or `.tool-versions`, `mise install` runs on
every start:

```toml
# mise.toml in the project
[tools]
node = "22"
java = "temurin-21"
clojure = "latest"
"pipx:ansible" = "latest"
```

Tools are kept in the `ocbox-home` volume, so they are downloaded only once.
The agent can add tools itself with `mise use`. To skip the automatic
install, set `OCBOX_MISE_INSTALL=0`.

If you always need something that mise does not provide, add it to the
`apt-get install` in the `Dockerfile` and run `ocbox --rebuild`.

## Settings reference

The variables ocbox itself reads. Set them in `ocbox.env` (every project) or
`projects/<name>/project.env` (one project). Each service has its own variables,
documented in its README in [services](../services/README.md).

| Variable | Default | Description |
|---|---|---|
| `OCBOX_SERVICES` | — | Services to start, comma-separated (`-s`) |
| `OCBOX_PORTS` | — | Ports to publish on 127.0.0.1, space-separated (`-p`) |
| `OCBOX_GIT_RW` | `0` | `1` mounts `.git` read-write (`--git-rw`) |
| `OCBOX_SERENA` | `0` | `1` enables Serena (`--serena`) |
| `OCBOX_SERENA_DASHBOARD` | `0` | `1` publishes Serena's web dashboard |
| `OCBOX_SERENA_DASHBOARD_PORT` | `24282` | Host port for that dashboard |
| `OCBOX_SERENA_CODEMODE` | `0` | `1` exposes Serena's tools through Code Mode |
| `OCBOX_MISE_INSTALL` | `1` | `0` skips `mise install` on start |
| `OCBOX_HOST_UID` / `OCBOX_HOST_GID` | your UID/GID | Container user; `0` for rootless Docker |
| `OCBOX_CONFIG_DIR` | `~/.config/ocbox` | Configuration directory (set it in your shell, not in these files) |
| `OCBOX_PROJECT_CONFIG` | set by `ocbox` | The project's configuration directory, for paths in compose files |
| `OPENCODE_VERSION` | `latest` | `@opencode/cli` version in the image (rebuild after changing) |
| `POSTGRES_CLIENT_VERSION` | `18` | PostgreSQL client tools in the image (rebuild after changing) |
| `SERENA_VERSION` | see `ocbox.env` | Serena version in the image (rebuild after changing) |
| `INSTALL_SERENA` | `1` | `0` builds the image without Serena |
