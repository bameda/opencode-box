# Rust API

- Before considering a task done, run `cargo fmt`, `cargo test` and
  `cargo clippy --all-targets -- -D warnings`, and fix what they report.
- sqlx checks queries against the database at compile time. After adding
  or changing a query or a migration, run `sqlx migrate run` and then
  `cargo sqlx prepare`, and keep the `.sqlx/` directory in the change.
- Schema changes go through a new migration (`sqlx migrate add <name>`);
  never edit a migration that has already been applied.
- The API listens on `0.0.0.0:8080`.
