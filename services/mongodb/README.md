# MongoDB (`mongodb`)

Part of the [service catalog](../README.md). See
[How services work](../README.md#how-services-work) for what is common
to every service: enabling, data, `--down`/`--purge` and host access.

**Enable**: `OCBOX_SERVICES=mongodb` in `~/.config/ocbox/projects/<name>/project.env`, or `ocbox -s mongodb`.

MongoDB document database.

**Inside the box**

| Variable | Value |
|---|---|
| `MONGODB_URL` | `mongodb://dev:dev@mongodb:27017/?authSource=admin` |

The user is created as an administrator in the `admin` database, hence
`authSource=admin`. To pick a default database in the URL, put it before the
query string: `mongodb://dev:dev@mongodb:27017/myapp?authSource=admin`.

**Explore it.** The image has no MongoDB shell; `npx` fetches it on first use:

```bash
npx -y mongosh "$MONGODB_URL"
npx -y mongosh "$MONGODB_URL" --quiet --eval 'db.adminCommand({ listDatabases: 1 })'
```

**Data**: persisted in the project's `mongodb-data` volume.

**Settings**

| Variable | Default |
|---|---|
| `MONGO_VERSION` | `8` |
| `MONGO_USER` / `MONGO_PASSWORD` | `dev` / `dev` |
