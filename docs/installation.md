# Installation

- [Requirements](#requirements)
- [Install Docker](#install-docker)
- [Install roke](#install-roke)
- [Updating](#updating)
- [Rootless Docker](#rootless-docker)
- [Uninstalling](#uninstalling)

## Requirements

- Linux with **Docker Engine** and the **Docker Compose plugin ≥ 2.24**.
- **git**.
- Your user in the `docker` group, or [rootless Docker](#rootless-docker).

All scripts are bash with a shebang, so they work the same from fish, zsh or
any other shell.

## Install Docker

### Arch Linux, CachyOS, Manjaro, EndeavourOS

```bash
sudo pacman -S --needed docker docker-compose docker-buildx git
sudo systemctl enable --now docker.service
```

### Debian and Ubuntu

The Docker packages in the distribution repositories (`docker.io`,
`docker-compose`...) can be too old, so use Docker's official repository.
This block works on both, since it reads the distribution and release from
`/etc/os-release`. Run it in **bash** (from fish, type `bash` first):

```bash
# Remove unofficial packages that conflict with Docker's own
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc 2>/dev/null | cut -f1)

# Add Docker's repository
sudo apt update
sudo apt install -y ca-certificates curl git
. /etc/os-release
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL "https://download.docker.com/linux/$ID/gpg" -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/$ID
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Install Docker Engine and the Compose plugin
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

On derivatives such as Linux Mint or Pop!_OS, `$ID` is not `ubuntu`:
replace `$ID` with `ubuntu` in the two URLs, and
`${UBUNTU_CODENAME:-$VERSION_CODENAME}` with the Ubuntu release it is based
on (for example `noble`).

### Other distributions

Follow [Docker's installation guide](https://docs.docker.com/engine/install/)
and make sure the Compose plugin is installed.

### After installing Docker

Let your user run Docker without `sudo`, then **log out and back in** for it
to take effect:

```bash
sudo usermod -aG docker $USER
```

Check that everything works:

```bash
docker compose version          # must be 2.24 or newer
docker run --rm hello-world
```

Being in the `docker` group is equivalent to having root access on the
host; [rootless Docker](#rootless-docker) avoids that.

## Install roke

```fish
git clone https://github.com/bameda/roke.git ~/src/roke
~/src/roke/install.sh
```

`install.sh` does two things:

- It links `roke` into `~/.local/bin`. If that directory is not in your
  `PATH`, add it (in fish: `fish_add_path ~/.local/bin`).
- It creates your configuration directory, `~/.config/roke`, from the
  examples. It never overwrites existing files. See
  [Configuration](configuration.md).

Choose your default agent (it is written to `~/.config/roke/roke.env`):

```fish
roke --default-agent claude       # or opencode; see agents/README.md
```

Any project can use a different one later, with `roke --set-agent`.

The image installs every agent by default. To make it smaller, keep only
the ones you use in `ROKE_AGENTS` (see [Agents](../agents/README.md)).

Then build the image and start the agent in a project:

```fish
cd ~/src/my-project
roke --build
```

The first time, log in from inside the agent, as its README explains
([Claude Code](../agents/claude/README.md#log-in),
[OpenCode](../agents/opencode/README.md#log-in)). The login is stored in the
box's own volume, not in your real `$HOME`, and works for every project.

### On another machine, with your configuration repository

If you keep your configuration in a private repository (see
[Configuration](configuration.md#keeping-it-in-a-private-repository)), pass
its URL to `install.sh`. It clones the repository into `~/.config/roke` and
adds any missing file from the examples:

```fish
git clone https://github.com/bameda/roke.git ~/src/roke
~/src/roke/install.sh git@github.com:<you>/roke-config.git
```

Your secrets are not in that repository, so recreate
`~/.config/roke/secrets.env` by hand if you use it, or log in again with
logging in again from the agent.

## Updating

```fish
cd ~/src/roke
git pull
roke --build
```

Your configuration is not touched. Releases with incompatible changes are
marked with `!` in the commit history (for example
`feat(postgres)!: ...`): read their description, which explains what to
change.

`roke --build` rebuilds the image only where something changed. Agents
installed from a channel (`latest`, `stable`) are not updated by it, since
Docker reuses the cached layer: run `roke --rebuild` to fetch their newest
release, or pin versions with `ROKE_AGENT_VERSIONS` in `roke.env` and run
`roke --build` after changing them. See [Agents](../agents/README.md).

## Rootless Docker

With [rootless Docker](https://docs.docker.com/engine/security/rootless/),
the Docker daemon runs as your user instead of root, so being able to use
Docker no longer means having root on the host.

The container's root maps to your host user, and every other UID to a
subordinate one. To keep the files the agent creates owned by you, add to
`~/.config/roke/roke.env`:

```dotenv
ROKE_HOST_UID=0
ROKE_HOST_GID=0
```

Then run `roke --rebuild`. There is still no `sudo` in the box, and its
root is not root on your machine.

## Uninstalling

```fish
cd ~/src/my-project && roke --purge       # for each project: services and data
docker volume rm roke-home                # the box's home: login, caches, tools
docker image rm roke:latest
rm ~/.local/bin/roke
rm -rf ~/src/roke
```

`~/.config/roke` is left in place, so remove it too if you no longer need
your configuration.
