# Example: Node.js app

For a Node.js app with a frontend (Vite, Next.js...) and an API, using
PostgreSQL and sending emails, managed with pnpm.

## What it sets up

- **`project.env`**: `postgres` and `mailpit`, and two ports: 5173 for the
  frontend's dev server and 3000 for the API.
- **`AGENTS.md`**: package manager, dev servers, tests, and how to check
  emails.

## In the project

Add a `mise.toml`, so the box has the right versions of Node and pnpm:

```toml
[tools]
node = "22"
pnpm = "10"
```

Read the database and mail settings from the environment: `DATABASE_URL`
(Prisma, Drizzle, Knex and node-postgres accept it as is), `SMTP_HOST` and
`SMTP_PORT`, without authentication or TLS.

Both dev servers must listen on `0.0.0.0`, for example `vite --host 0.0.0.0`.
Then the frontend is at `http://127.0.0.1:5173`, the API at
`http://127.0.0.1:3000`, and the emails your app sends at
`http://127.0.0.1:8025`.

## Check it

From `ocbox --shell`:

```bash
pnpm install
pnpm test
curl -s "$MAILPIT_API/v1/messages" | jq '.total'     # emails received so far
```
