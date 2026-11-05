# Per-project settings

Files are looked up by the **project directory name**. For `~/src/my-app`
they would be `my-app.env` and `my-app.yaml`.

They live here, not inside the project, on purpose: a compose file can mount
any host path, so if `ocbox` read a file from the project itself, the agent
could write one and escape the container the next time you launched it.

- `<name>.env`: `ocbox` defaults for that project (command-line options take
  precedence), plus any service variable (versions, credentials, ports...).
- `<name>.yaml`: a compose override merged on top of `compose.yaml`.

See `example.env` and `example.yaml`.
