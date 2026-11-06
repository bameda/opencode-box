# Rails app

- **Always** run tests and anything touching the test database with
  `DATABASE_URL="$TEST_DATABASE_URL"` in front, for example
  `DATABASE_URL="$TEST_DATABASE_URL" bin/rails test`. Without it, Rails
  would run the tests against the development database and could reset it.
- Start the server with `bin/rails server -b 0.0.0.0 -p 3000`.
- Schema changes go through a new migration (`bin/rails generate
  migration`); never edit a migration that has already been applied.
- Before considering a task done, run the tests and `bundle exec rubocop`
  if the project uses it.
- Emails are caught by Mailpit: check them with
  `curl -s "$MAILPIT_API/v1/messages"`.
