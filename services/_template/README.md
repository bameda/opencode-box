# Service name (`myservice`)

Part of the [service catalog](../README.md). See
[How services work](../README.md#how-services-work) for what is common
to every service: enabling, data, `--down`/`--purge` and host access.

**Enable**: `OCBOX_SERVICES=myservice` in `~/.config/ocbox/projects/<name>.env`, or `ocbox -s myservice`.

One or two sentences: what the service is and what a project uses it for.

**Inside the box**

| Variable | Value |
|---|---|
| `MYSERVICE_URL` | `http://myservice:8080` |

How an app connects: which variables it reads, driver options to watch out
for.

**Explore it**

```bash
# commands to inspect or reset it from ocbox --shell
```

**From your host**: web UI address, if it publishes one.

**Data**: persisted in the project's `myservice-data` volume, or not
persisted.

**Settings**

| Variable | Default |
|---|---|
| `MYSERVICE_VERSION` | `latest` |
