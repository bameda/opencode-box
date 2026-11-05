# My ocbox configuration

Personal configuration for [opencode-box](https://github.com/bameda/opencode-box):
the settings of each project, global settings and my opencode configuration.
It lives in `~/.config/ocbox` (or wherever `OCBOX_CONFIG_DIR` points) and is
meant to be its own private git repository.

```
~/.config/ocbox/
├── ocbox.env           global settings (versions, ports, git identity...)
├── secrets.env         API keys; never committed
├── projects/           one <name>.env (and optional <name>.yaml) per project,
│                       named after the project's directory
├── services/           optional: your own services, same layout as the catalog
└── opencode/           opencode's global configuration
    ├── opencode.jsonc  model, agents, permissions, MCPs...
    └── AGENTS.md       personal instructions for the agent
```

- **Projects**: see `projects/README.md`.
- **Services**: a `services/<name>/compose.yaml` here is available to
  `ocbox -s <name>`, and replaces a catalog service with the same name. To
  refer to files in this directory from a compose file, use
  `${OCBOX_CONFIG_DIR}` (relative paths resolve against the opencode-box
  repo).
- **opencode**: mounted read-only in the box, so change it here, not from
  inside opencode. Files the TUI writes (like `cli.json`) stay in the box's
  own volume.

The agent cannot read or modify this directory: `ocbox` refuses to mount a
project that contains it or is inside it.
