# Usage

- [Command line](#command-line)
- [Checking the settings](#checking-the-settings)
- [Choosing the agent](#choosing-the-agent)
- [Projects and their services](#projects-and-their-services)
- [Opening the app in your browser](#opening-the-app-in-your-browser)
- [Running other commands](#running-other-commands)
- [Git workflow](#git-workflow)

## Command line

```text
roke [options] [PROJECT_DIR] [-- COMMAND...]
```

`PROJECT_DIR` defaults to the current directory. All actions are options,
so they start with dashes: `roke --build`, not `roke build`. `roke --help`
lists them grouped like this:

**Session**

| Option | Description |
|---|---|
| `-c`, `--continue` | Resume the agent's last session in this project |
| `--shell` | Open bash in the box instead of the agent |
| `-- COMMAND...` | Run `COMMAND` in the box instead of the agent |

**Agent** (see [choosing the agent](#choosing-the-agent))

| Option | Description |
|---|---|
| `-a`, `--agent NAME` | Use `NAME` this time |
| `--set-agent NAME` | Use `NAME` in this project from now on; `default` goes back to the default agent |
| `--default-agent NAME` | Use `NAME` in every project without an agent of its own |

**Services and ports**, for this run (`ROKE_SERVICES` and `ROKE_PORTS` keep them)

| Option | Description |
|---|---|
| `-s`, `--services LIST` | Services to start, comma-separated: `-s postgres,redis` |
| `-p`, `--port PORT` | Publish a port of the box on `127.0.0.1` (repeatable) |

**Network** (see [Network](network.md))

| Option | Description |
|---|---|
| `--network MODE` | `restricted` or `open`, this time (default: `restricted`) |
| `--allow ENTRY` | Allow a destination in this project from now on |
| `--blocked` | Show what the project tried to reach and was denied |

**Access**, for this run (`ROKE_GIT_RW` and `ROKE_SERENA` keep them)

| Option | Description |
|---|---|
| `--git-rw` | Let the agent write to `.git`, so it can commit |
| `--serena` / `--no-serena` | Enable or disable [Serena](serena.md) |

**Information**

| Option | Description |
|---|---|
| `-l`, `--list` | The available agents and services |
| `--settings` | This project's settings and allowed destinations |
| `-h`, `--help` | The help |

**Maintenance**

| Option | Description |
|---|---|
| `--build` | Rebuild the images before starting |
| `--rebuild` | Rebuild them without cache: also updates the agents |
| `--down` | Stop the project's services, keeping their data |
| `--purge` | Stop them and delete all the project's data |
| `--init [GIT_URL]` | Create the [configuration directory](configuration.md), cloning it if a URL is given |
| `--update` | Update roke itself; then `--build` rebuilds the images |

Examples:

```fish
roke -c                           # resume the agent's last session
roke -s postgres -- psql          # a single command in the box
```

Options given on the command line take precedence over the project's
[settings](configuration.md#per-project-settings). Use them to try something
once; for a project you work on every day, put them in
`projects/<name>/project.env` and just run `roke`.

## Checking the settings

`roke --settings` shows what applies to the current project and where each
value comes from: the agent, the network mode, the services, the ports, the
settings files found, and the allowed network destinations, layer by layer.

```text
Project   /home/me/src/shop
Settings  /home/me/.config/roke: roke.env secrets.env projects/shop/project.env
Agent     claude (default agent, roke.env)
Network   restricted (built-in default)
Services  postgres, mailpit
Ports     5173
Serena    on  ·  .git: read-only

Allowed destinations (restricted mode), by layer:
  base       docker/gateway/allow.txt
             github.com githubusercontent.com ghcr.io ...
  agent      agents/claude/allow.txt
             api.anthropic.com claude.ai platform.claude.com
  ...
```

## Choosing the agent

No agent is the default. The one that runs comes from, in order of
precedence:

1. `--agent NAME` on the command line;
2. `ROKE_AGENT` in the project's `project.env`;
3. `ROKE_AGENT` in `roke.env`.

If none is set and the image has a single agent, that one runs.
`roke --list` shows which agent will run in the current project and where
that choice comes from.

To change the agent without editing files:

```fish
roke --default-agent claude      # the default (roke.env)
roke --set-agent opencode        # this project's own (project.env)
roke --set-agent default         # this project uses the default again
```

All the agents of a project share its home volume, so you can switch
between them freely: each keeps its own login and sessions there. See
[switching between agents](../agents/README.md#switching-between-agents) for
what carries over and what does not.

## Projects and their services

Each project gets its own set of containers, named `roke-<name>-<hash>`
after its path. Two projects using `postgres` therefore get two separate
databases, and you can have several projects open at once.

When you exit the agent, the project's services **keep running**, so the
next session starts instantly with the same data. Stop them when you are
done:

| Command | Services | Data (databases, buckets, queues...) and the box's home |
|---|---|---|
| exit the agent | keep running | kept |
| `roke --down` | stopped and removed | kept |
| `roke --purge` | stopped and removed | **deleted** |

The box's home is the project's own volume with the agents' logins and
sessions and the tools installed with mise, so after `--purge` you log in
again and tools are downloaded again.

Some services do not keep data at all (Redis, Mailpit...); each
[service's README](../services/README.md) says what it keeps.

## Opening the app in your browser

When the agent starts a dev server, it runs inside the box. To open it from
your browser, publish its port, either once with `-p` or for good with
`ROKE_PORTS` in the project's settings:

```fish
roke -p 5173
```

Then open `http://127.0.0.1:5173`. The server must listen on `0.0.0.0`, not
`localhost` (for example `vite --host 0.0.0.0`); the box's instructions
already tell the agent so.

Services with a web UI (Mailpit, RustFS, Grafana...) publish it themselves;
do not add their ports to `-p`. See the [service catalog](../services/README.md).

## Running other commands

```fish
roke --shell                      # interactive bash in the box
roke -- psql                      # one command, then exit
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

To let the agent commit, use `--git-rw`, or `ROKE_GIT_RW=1` in the
project's settings. Set your git identity in `roke.env` (`GIT_AUTHOR_NAME`
and friends). There are no SSH keys in the box, so `git push` and
`git pull` always happen on the host.
