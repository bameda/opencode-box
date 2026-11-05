# Serena

[Serena](https://github.com/oraios/serena) is an MCP server that runs the
project's language servers and gives the agent symbol-level tools: find a
definition, list references, inspect a file's structure or replace the body
of a specific function. In large repositories it saves a lot of context
compared to `grep` and reading whole files. It is especially useful with
OpenCode 2, which does not run language servers itself.

## Enabling it

Serena is installed in the image, under `/opt` and out of the agent's reach,
and **enabled per project**:

```fish
ocbox --serena                     # once
```

To enable it for good, add `OCBOX_SERENA=1` to the project's settings,
`~/.config/ocbox/projects/<name>/project.env`.

When enabled, the box registers Serena as a local MCP server in OpenCode's
system configuration, pinned to the current project. It is regenerated on
every start, so there is nothing to add to your opencode configuration.

## Details

- **Language servers.** Serena downloads many of them by itself and keeps
  them in `~/.serena`, in the box's volume, so only the first run is slow.
  Some need the language's runtime: for Java or Clojure, declare `java` and
  `clojure` in the project's `mise.toml`. See Serena's
  [language support](https://oraios.github.io/serena/01-about/020_programming-languages.html).
- **Project data.** Serena stores `project.yml` and its "memories" (notes
  the agent writes about the project) in `.serena/` inside the project.
  Decide whether to commit it or add it to `.gitignore`.
- **Dashboard.** Disabled, since there is no browser in the box. To use it,
  set `OCBOX_SERENA_DASHBOARD=1` and open
  `http://127.0.0.1:24282/dashboard/` (the port can be changed with
  `OCBOX_SERENA_DASHBOARD_PORT`).
- **Code Mode.** OpenCode 2 groups MCP tools behind its Code Mode by
  default. It is disabled for Serena, so its tools show up directly and the
  model uses them more. `OCBOX_SERENA_CODEMODE=1` reverts that.
- **Version.** Set `SERENA_VERSION` in `ocbox.env` and run `ocbox --build`.
  With `INSTALL_SERENA=0`, the image is built without Serena.
