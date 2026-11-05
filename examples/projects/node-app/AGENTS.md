# Node.js app

- Use pnpm, never npm or yarn: `pnpm add <package>`, `pnpm install`.
- Start the dev servers listening on `0.0.0.0`: the frontend on port 5173
  (`pnpm dev --host 0.0.0.0` for Vite) and the API on port 3000.
- Run `pnpm lint` and `pnpm test` before considering a task done.
- Emails are caught by Mailpit. To check one was sent, query
  `$MAILPIT_API/v1/messages` instead of assuming it worked, and clean up with
  `curl -X DELETE "$MAILPIT_API/v1/messages"`.
