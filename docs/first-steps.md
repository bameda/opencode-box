# First steps: adding a project

This guide walks through adding a project to opencode-box, using a concrete
example: a Node app in `~/src/shop` that uses PostgreSQL and Redis and runs a
dev server on port 5173.

## 0. Before you start

You need opencode-box installed and its image built, and to have logged in
with `/connect` once: see [Installation](installation.md). The login is
shared by every project.

## 1. Decide what the project needs

Before configuring anything, answer four questions:

- **Which services does it use?** Check the catalog with `ocbox --list`.
  The [service catalog](../services/README.md) links to a guide for each one
  explaining how your app connects to it.
- **Is there a port you want to open in your browser?** For example, the dev
  server's.
- **Do you want Serena?** It pays off in medium and large repos.
- **Should the agent be allowed to commit?** Recommended: no. You review the
  diff and commit yourself.

## 2. Create its directory in your configuration

Each project has a directory in your configuration, `~/.config/ocbox`, named
after the **project's directory**: for `~/src/shop`, `projects/shop/`. Start
from the closest [example project](../examples/projects/README.md), here
the Node.js one, and edit its settings in `project.env`:

```fish
cp -r ~/src/opencode-box/examples/projects/node-app ~/.config/ocbox/projects/shop
cd ~/.config/ocbox
$EDITOR projects/shop/project.env
```

```dotenv
OCBOX_SERVICES=postgres,redis
OCBOX_PORTS="5173"
OCBOX_SERENA=1
POSTGRES_DB=shop
```

If a service of this project publishes a web UI, such as Mailpit, and you
will have another project open at the same time, change its port here (for
example, `MAILPIT_UI_PORT=18025`).

If you keep your configuration in a
[private repository](configuration.md#keeping-it-in-a-private-repository)
(recommended), commit the directory there:

```fish
git add projects/shop
git commit -m "chore: add shop project"
```

Either way it stays out of the agent's reach: `ocbox` never mounts your
configuration directory.

## 3. (Optional) Everything else the project needs

The project's directory can hold more than its settings. Add only what you
need; the [`reference`](../examples/projects/reference/) example has a
sample of each:

- `secrets.env`, for secrets only this project uses;
- `AGENTS.md`, with private instructions for the agent in this project;
- `compose.yaml`, to tweak a service (for example, PostGIS instead of
  PostgreSQL);
- `services/<name>/`, for services that are not in the catalog and only
  this project needs.

See [per-project settings](configuration.md#per-project-settings) for the
details of each one.

## 4. Declare the language tools

In the project itself, create a `mise.toml`. It is installed automatically on
startup and cached for next time.

```toml
# ~/src/shop/mise.toml
[tools]
node = "22"
```

If you skip this, the agent can add it itself with `mise use node@22`.

## 5. Make the app work inside the box

Two things to check:

- **Service connections.** The app must read the variables that already
  exist inside the container, such as `DATABASE_URL` and `REDIS_URL`, instead
  of pointing to `localhost`.
- **Dev server.** It must listen on `0.0.0.0`. With Vite, for example:
  `vite --host 0.0.0.0`.

The box's instructions already explain both to the agent, so you can simply
ask it to do this.

## 6. First start and checks

```fish
cd ~/src/shop
ocbox --shell
```

The line `[ocbox] project: ... services: postgres,redis ... serena: yes`
confirms your settings were picked up. Inside the shell, check that
everything responds:

```bash
env | grep -E 'DATABASE_URL|REDIS_URL|OCBOX'
psql -c 'select 1'
redis-cli -u "$REDIS_URL" ping
exit
```

## 7. First opencode session

```fish
ocbox
```

Inside, run `/init` so the agent analyses the project and generates its own
`AGENTS.md`, with conventions, build and test commands and structure. Review
it and commit it from the host.

If you enabled Serena, a `.serena/` directory will appear. Decide whether to
commit it or add it to `.gitignore`.

## 8. Day to day

```fish
cd ~/src/shop
ocbox                            # new session
ocbox -- opencode --continue     # resume the last one
git diff                         # on the host: review what it did
git commit -am "feat: ..."       # and commit it yourself
ocbox --down                     # when done, stop PostgreSQL and Redis
```

The database keeps its data between sessions, even after `--down`. See
[Usage](usage.md) for every option.

## 9. Removing a project

```fish
cd ~/src/shop
ocbox --purge                    # stops the services and deletes their data
rm -r ~/.config/ocbox/projects/shop
```

If you keep your configuration in a repository, commit the removal there
too.
