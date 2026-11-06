# Example: Ruby on Rails

For a Rails app with PostgreSQL, Redis (for Sidekiq or caching) and email.

## What it sets up

- **`project.env`**: `postgres`, `redis` and `mailpit`, port 3000, and
  Serena.
- **`compose.yaml`**: a separate URL for the test database (see below).
- **`AGENTS.md`**: running the app and, above all, the tests.

## In the project

Add a `mise.toml`:

```toml
[tools]
ruby = "3.4"
node = "22"        # only if the app builds JavaScript with Node
```

mise compiles Ruby from source, so the first start takes a few minutes;
after that it is cached in the box's volume, along with your gems.

**Careful with the test database.** Rails uses `DATABASE_URL` for whichever
environment is running, tests included. Since the box always sets it,
`bin/rails test` would run against the development database, mixing test
data into it or even resetting it when Rails prepares the test schema. Run
the tests with the test database's URL instead, which `compose.yaml`
provides:

```bash
DATABASE_URL="$TEST_DATABASE_URL" bin/rails test
```

The `AGENTS.md` tells the agent to always do so.

Configure Action Mailer to use SMTP on `ENV["SMTP_HOST"]` and
`ENV["SMTP_PORT"]` in development: emails then show up in Mailpit, at
`http://127.0.0.1:8025`. Sidekiq reads `REDIS_URL` by itself. The server
must listen on `0.0.0.0`: `bin/rails server -b 0.0.0.0`.

## Check it

From `ocbox --shell`:

```bash
bundle install
bin/rails db:prepare
DATABASE_URL="$TEST_DATABASE_URL" bin/rails db:prepare test
```
