# Clojure app

- The REPL is shared with the user, who connects their editor to it. Start
  it with `clojure -M:nrepl` (it listens on `0.0.0.0:7888`) and do not stop
  it or restart it without asking: the user may be using it.
- Prefer evaluating in the REPL to check a change before running the whole
  test suite.
- Before considering a task done, run `clojure -M:test` and
  `clj-kondo --lint src test`, and fix new warnings.
- Database access goes through next.jdbc with `JDBC_DATABASE_URL`.
