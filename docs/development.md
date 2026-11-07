# Development

## Tests

The tests run the real `roke` command against a fake `docker`
(`tests/fakes/docker`), which records every call instead of running it, so
they need neither Docker nor any container. Each test gets an isolated home,
configuration and projects in a temporary directory.

```fish
uvx pytest                 # with uv
python3 -m pytest          # or with pytest installed
```

The tests that check the resolved configurations of the example projects,
and `roke urls`, also need a real Docker Compose binary; they are skipped
when there is none. GitHub Actions runs every test, plus ShellCheck on the
scripts, on each push (`.github/workflows/test.yml`).

The tests describe what roke does from the outside, so they do not depend on
how it is written: any change to `bin/roke` must keep them passing.

## Trying a change

Run `./install.sh` from your clone: it links `roke` to that clone, so your
changes apply at once. The scripts that run inside the containers
(`docker/entrypoint.sh`, `docker/gateway/gateway.sh`, the agents'
`setup.sh`) are mounted from the repository, so they apply on the next
start too; the `Dockerfile`s and the agents' `install.sh` need
`roke build`.
