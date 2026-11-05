# Python API

- Dependencies are managed with uv: `uv add <package>` (or
  `uv add --dev <package>`), never `pip install`. Run everything through
  `uv run`.
- Start the dev server on `0.0.0.0:8000`, for example
  `uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload`.
- Tests run against the `app_test` database (`TEST_DATABASE_URL`), never the
  development one. Run `uv run pytest` before considering a task done.
- Schema changes go through a new migration (for example
  `uv run alembic revision --autogenerate -m "..."`); never edit a migration
  that has already been applied.
