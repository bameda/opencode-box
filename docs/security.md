# Security

opencode-box limits what the agent can touch on your machine. It is not a
full sandbox: read what it protects and what it does not.

- [What the container sees](#what-the-container-sees)
- [How it is locked down](#how-it-is-locked-down)
- [What it does NOT protect](#what-it-does-not-protect)

## What the container sees

| Path in the container | Comes from | Access |
|---|---|---|
| `<project path>` (same as on the host) | the project | read-write |
| `<project>/.git` | the project | **read-only** (unless `--git-rw`) |
| `/home/dev` | the `ocbox-home` volume | read-write; the box's own home |
| `/run/ocbox/agent-config` | `~/.config/ocbox/agents/<agent>` | read-only |
| `/run/ocbox/user-AGENTS.md` | `~/.config/ocbox/AGENTS.md`, if any | read-only |
| `/run/ocbox/project-AGENTS.md` | the project's `AGENTS.md` in your configuration, if any | read-only |
| `/opt/ocbox/agents` | the repository's `agents/` (setup scripts, the box's instructions) | read-only |

Nothing else from your host is mounted: not your `$HOME`, not your SSH keys,
not your other projects, not your ocbox settings or secrets.

The `ocbox-home` volume is shared by all projects and agents. It holds each
agent's login and sessions, tools installed with mise and caches (npm,
maven, cargo...).

## How it is locked down

- The container runs with **your UID/GID** (files it creates are yours),
  **without `sudo`**, without Linux capabilities (`cap_drop: ALL`) and with
  `no-new-privileges`.
- **The Docker socket is never mounted**, so the agent cannot start
  containers or reach the Docker daemon.
- **`.git` is read-only** by default. Otherwise the agent could plant hooks,
  or settings such as `core.fsmonitor`, that would run on your host the next
  time you used git there.
- **Settings live outside the project.** `ocbox` only reads compose files
  and settings from `~/.config/ocbox` and from its own repository, and
  refuses to mount a project that contains either of them. A compose file
  written by the agent could otherwise mount any host path.
- **Published ports** listen on `127.0.0.1` by default, never on your
  network. Only a full mapping you write yourself (such as `-p 3000:3000`
  or `ports:` in a compose file) can change that.

## What it does NOT protect

- **The network.** The box has internet access, since it needs it to talk
  to the model provider. By default it also reaches everything your host
  reaches: your LAN and **your corporate VPN** while it is up, since traffic
  goes out through your machine. If that worries you, block private networks
  for containers with rules in the `DOCKER-USER` iptables chain, keeping the
  ranges Docker itself uses.
- **What you run on the host afterwards.** The agent can edit any file in
  the project: `package.json`, `Makefile`, `.envrc`, scripts, tests... If
  you later run them outside the box, you run whatever it wrote. Review the
  diff first.
- **The `docker` group.** Being in it is equivalent to being root on the
  host. [Rootless Docker](installation.md#rootless-docker) avoids that.
- **Separation between projects.** The box's home is shared, so an agent
  could leave something there (a `.bashrc`, a cache) that affects another
  project's session.
- **Secrets you give it.** API keys in `secrets.env` and the agents' logins
  are available inside the box, so the agent can read them. Use keys with
  spending limits where your provider offers them.
