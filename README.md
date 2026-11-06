# opencode-box

Run [OpenCode 2](https://opencode.ai/v2/docs/) inside a Docker container that
**only sees the project you are working on**. Your `$HOME`, SSH keys,
dotfiles and every other project stay out of the agent's reach.

- **Isolated**: the project is the only host directory the agent can write
  to. Its `.git` is read-only, and the container runs without `sudo`,
  without capabilities and without access to Docker.
- **Services on demand**: databases, caches, queues, test email, tracing,
  API mocks, a simulated Kubernetes API and more, each in its own
  container, with separate data for every project.
- **Per-project tools**: languages and tools are installed with
  [mise](https://mise.jdx.dev) from the project's `mise.toml`.
- **Semantic code navigation**, optionally, with
  [Serena](https://github.com/oraios/serena).
- **Shareable**: your settings live in `~/.config/ocbox`, outside this
  repository, and can be kept in a private repository of their own.

## Quick start

1. Install Docker with the Compose plugin: see
   [Installation](docs/installation.md) for Arch, Debian, Ubuntu and others.
2. Install opencode-box:

   ```fish
   git clone https://github.com/bameda/opencode-box.git ~/src/opencode-box
   ~/src/opencode-box/install.sh
   ```

3. Start it in a project, building the image the first time:

   ```fish
   cd ~/src/my-project
   ocbox --build
   ```

   Inside opencode, run `/connect` once to log in to your model provider.

Then follow [First steps](docs/first-steps.md) to set up a project with its
services and tools.

## Everyday use

```fish
ocbox                            # opencode in the current project
ocbox -- opencode --continue     # resume the last session
ocbox -s postgres,mailpit        # with a database and a test mail server
ocbox -p 5173                    # publish the dev server on 127.0.0.1:5173
ocbox --shell                    # bash inside the box
ocbox --list                     # available services
ocbox --down                     # stop the project's services (keeps data)
ocbox --help                     # every option
```

Each project keeps its services, ports and other options in its own
directory, `~/.config/ocbox/projects/<name>/`, so day to day `ocbox` is
usually enough.

## Documentation

| Guide | What you will find |
|---|---|
| [Installation](docs/installation.md) | Docker on each distribution, installing and updating opencode-box, rootless Docker |
| [First steps](docs/first-steps.md) | Step-by-step tutorial: adding a project |
| [Usage](docs/usage.md) | Every `ocbox` option, ports, git workflow, stopping and resetting |
| [Configuration](docs/configuration.md) | `~/.config/ocbox`, keeping it in a private repo, per-project settings, opencode, tools, settings reference |
| [Services](services/README.md) | The service catalog, how to use each one and how to add your own |
| [Example projects](examples/projects/README.md) | Ready-made configurations: Ansible, Helm, Python, Node.js, Go, Rust, Rails, Spring Boot, Clojure |
| [Serena](docs/serena.md) | Semantic code navigation and editing |
| [Security](docs/security.md) | What the container can and cannot reach |
| [Troubleshooting](docs/troubleshooting.md) | Common problems, known limitations and maintenance |

## Security in a nutshell

The agent can read and write the project, but nothing else on your
machine. It **can** reach the network, including your LAN and VPN, and
anything it writes runs on your host if you later run it there: review the
diff before running the project's scripts or committing. Read
[Security](docs/security.md) for the details.

## License

[MIT](LICENSE) © David Barragán Merino
