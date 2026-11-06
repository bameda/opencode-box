# Troubleshooting

- [Common problems](#common-problems)
- [Known limitations](#known-limitations)
- [Maintenance](#maintenance)

## Common problems

### `ocbox: only one project directory is allowed`

An action was written without dashes, such as `ocbox build`. Every action
is an option: `ocbox --build`.

### `configuration directory not found`

Run `ocbox --init`, or `./install.sh` from the repository, to create
`~/.config/ocbox`.

### My settings are ignored

The project's configuration directory must be named after the project's
directory: for `~/src/my-app`, `~/.config/ocbox/projects/my-app/`, with its
settings in `project.env`. The line `[ocbox] project: ...` printed on start
shows the services and options that were applied, and `ocbox --list` marks
the project's own services as `[project]`.

### The app does not load in the browser

Publish its port (`-p 5173` or `OCBOX_PORTS`) and make the dev server
listen on `0.0.0.0`, not `localhost`.

### `port is already allocated`

Another project, or something on your host, is using that port. For
service UIs, change their port in the project's settings (for example
`MAILPIT_UI_PORT=18025`); each service's README lists its variables.

### `choose a coding agent`

Several agents are installed in the image and none is selected. Choose the
default one with `ocbox --default-agent NAME` (or a project's own with
`--set-agent NAME`), or pass `--agent` for a single run. See
[Agents](../agents/README.md).

### `the agent '<name>' is not in OCBOX_AGENTS` / `is not installed in the image`

The agent you chose is not in the image. Add it to `OCBOX_AGENTS` in
`ocbox.env` and run `ocbox --build`.

### `WARNING: <path> exists in the box's volume and hides yours`

A file in the agent's configuration directory inside the box, left from an
older setup or created by the agent, takes precedence over the same file in
your configuration. Remove it: `ocbox --shell`, then `rm <path>`.

### Permission errors on files in the box's home

Usually after changing UID or switching to rootless Docker. Reset the
box's home with `docker volume rm ocbox-home` (you will need to log in
again, and caches and tools are downloaded again).

## Known limitations

- **Dragging images into the terminal** passes a host path that does not
  exist in the box. Copy the image into the project and refer to it from
  there.
- **No SSH keys in the box**: `git push` and `git pull` happen on the host.
- **Agent-specific limitations** are listed in each
  [agent's README](../agents/README.md), for example the lack of language
  servers in OpenCode 2.
- **No systemd** in the box or in `ssh-target`.

## Maintenance

```fish
ocbox --rebuild                        # update the image and the agents
docker volume ls | grep ocbox          # the box's home and each project's data
docker volume rm ocbox-home            # reset the box's home: login, caches, tools
cd ~/src/my-app && ocbox --purge       # delete one project's services and data
```
