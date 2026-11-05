# Example: Clojure app

For a Clojure app (deps.edn) with PostgreSQL and Valkey, where both you and
the agent work against the same running REPL.

## What it sets up

- **`project.env`**: `postgres` and `valkey`, port 8080 for the app and port
  7888 for nREPL, and Serena.
- **`compose.yaml`**: a JDBC URL for the database, plus `REDIS_URL` pointing
  to Valkey, for libraries that expect it.
- **`AGENTS.md`**: how to start the REPL and run the tests and the linter.

## In the project

Add a `mise.toml`, so the box has Java and the Clojure CLI. Serena also
needs Java to run Clojure's language server:

```toml
[tools]
java = "temurin-21"
clojure = "latest"
clj-kondo = "latest"
```

Add an nREPL alias to `deps.edn` that listens on all interfaces, so it can
be reached from outside the box:

```clojure
{:aliases
 {:nrepl {:extra-deps {nrepl/nrepl {:mvn/version "1.3.1"}
                       cider/cider-nrepl {:mvn/version "0.52.1"}}
          :main-opts ["-m" "nrepl.cmdline"
                      "--middleware" "[cider.nrepl/cider-middleware]"
                      "--bind" "0.0.0.0" "--port" "7888"]}}}
```

Read the database settings from the environment: `JDBC_DATABASE_URL` for
next.jdbc and similar, and `REDIS_URL` (or `VALKEY_URL`) for Carmine.

## Connect your editor to the REPL in the box

Ask the agent to start the REPL (`clojure -M:nrepl`), or start it yourself
from `ocbox --shell`. Then connect your editor on the host to
`127.0.0.1:7888` (in Calva, *Connect to a running REPL*; in CIDER,
`cider-connect-clj`). nREPL also writes `.nrepl-port` to the project, which
most editors pick up automatically.

The REPL runs inside the box, so the code you evaluate from your editor runs
there too, with the box's limits.

## Check it

From `ocbox --shell`:

```bash
clojure -M:test
clj-kondo --lint src test
```
