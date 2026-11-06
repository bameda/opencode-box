# Example: reference

Not a kind of project, but an example of **every piece** a project's
directory can have, to copy from:

- **`project.env`**: services from the catalog (`postgres`, `valkey`,
  `mailpit`) plus the project's own (`elasticsearch`), ports, Serena, and
  service variables.
- **`compose.yaml`**: a catalog service tweaked for this project (PostGIS
  instead of PostgreSQL), and how to mount files from the project's
  directory with `${ROKE_PROJECT_CONFIG}`.
- **`AGENTS.md`**: private instructions for the agent.
- **`services/elasticsearch/`**: a service only this project uses, with the
  same layout as the catalog's.

A `secrets.env` would hold the project's secrets; it is not included here
because it should never be committed.
