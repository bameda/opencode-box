# Usage

- [Command line](#command-line)
- [Choosing the agent](#choosing-the-agent)
- [Projects and their services](#projects-and-their-services)
- [Opening the app in your browser](#opening-the-app-in-your-browser)
- [Running other commands](#running-other-commands)
- [Git workflow](#git-workflow)

## Command line

```text
ocbox [options] [PROJECT_DIR] [-- COMMAND...]
```

`PROJECT_DIR` defaults to the current directory. All actions are options,
so they start with dashes: `ocbox --build`, not `ocbox build`.

| Option | Description |
|---|---|
| `-a`, `--agent NAME` | The coding agent to run this time; defaults to `OCBOX_AGENT` |
| `--set-agent NAME` | The current project's own agent; `default` to use the default again |
| `--default-agent NAME` | The default agent, for projects without their own |
| `-s`, `--services LIST` | Services to start, comma-separated: `-s postgres,redis` |
| `-l`, `--list` | List the available agents and services |
| `-p`, `--port PORT` | Publish a port of the box on `127.0.0.1` (repeatable) |
| `--git-rw` | Mount `.git` read-write, so the agent can commit |
| `--serena` / `--no-serena` | Enable or disable [Serena](serena.md) |
| `--shell` | Open bash in the box instead of the agent |
| `--build` | Rebuild the images (pulling newer base images) before starting |
| `--rebuild` | Same, without cache: also updates agents installed from a channel |
| `--down` | Stop and remove the project's services; their data is kept |
| `--purge` | Like `--down`, and also delete the project's data |
| `--init [GIT_URL]` | Create the [configuration directory](configuration.md), optionally cloning it |
| `-h`, `--help` | Show the help |

Anything after `--` replaces the default command, which is the agent:

```fish
ocbox -- claude --continue        # resume Claude Code's last session
ocbox -- opencode --continue      # resume OpenCode's last session
ocbox -s postgres -- psql         # a single command in the box
```

Options given on the command line take precedence over the project's
[settings](configuration.md#per-project-settings). Use them to try something
once; for a project you work on every day, put them in
`projects/<name>/project.env` and just run `ocbox`.

## Choosing the agent

No agent is the default. The one that runs comes from, in order of
precedence:

1. `--agent NAME` on the command line;
2. `OCBOX_AGENT` in the project's `project.env`;
3. `OCBOX_AGENT` in `ocbox.env`.

If none is set and the image has a single agent, that one runs.
`ocbox --list` shows which agent will run in the current project and where
that choice comes from.

To change the agent without editing files:

```fish
ocbox --default-agent claude     # the default (ocbox.env)
ocbox --set-agent opencode       # this project's own (project.env)
ocbox --set-agent default        # this project uses the default again
```

All agents share the box's home volume, so you can switch between them
freely: each keeps its own login and sessions. See
[switching between agents](../agents/README.md#switching-between-agents) for
what carries over and what does not.

## Projects and their services

Each project gets its own set of containers, named `ocbox-<name>-<hash>`
after its path. Two projects using `postgres` therefore get two separate
databases, and you can have several projects open at once.

When you exit the agent, the project's services **keep running**, so the
next session starts instantly with the same data. Stop them when you are
done:

| Command | Services | Data (databases, buckets, queues...) |
|---|---|---|
| exit the agent | keep running | kept |
| `ocbox --down` | stopped and removed | kept |
| `ocbox --purge` | stopped and removed | **deleted** |

Some services do not keep data at all (Redis, Mailpit...); each
[service's README](../services/README.md) says what it keeps.

## Opening the app in your browser

When the agent starts a dev server, it runs inside the box. To open it from
your browser, publish its port, either once with `-p` or for good with
`OCBOX_PORTS` in the project's settings:

```fish
ocbox -p 5173
```

Then open `http://127.0.0.1:5173`. The server must listen on `0.0.0.0`, not
`localhost` (for example `vite --host 0.0.0.0`); the box's instructions
already tell the agent so.

Services with a web UI (Mailpit, MinIO, RabbitMQ...) publish it themselves;
do not add their ports to `-p`. See the [service catalog](../services/README.md).

## Running other commands

```fish
ocbox --shell                     # interactive bash in the box
ocbox -- psql                     # one command, then exit
```

The shell has the same environment as the agent: the project's tools, the
services' variables (`DATABASE_URL`...) and network access to the services
by name. It is the place to check things by hand or to run what the agent
would run.

## Git workflow

By default the project's `.git` is **read-only** inside the box. The agent
can run `git status`, `git diff` or `git log`, but it cannot commit,
switch branches, stash or change the git configuration. You review its
changes and commit them from your host:

```fish
git diff
git commit -am "feat: ..."
```

This also protects your host: hooks or settings planted in `.git` would run
the next time you used git outside the box (see [Security](security.md)).

To let the agent commit, use `--git-rw`, or `OCBOX_GIT_RW=1` in the
project's settings. Set your git identity in `ocbox.env` (`GIT_AUTHOR_NAME`
and friends). There are no SSH keys in the box, so `git push` and
`git pull` always happen on the host.
