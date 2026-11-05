# Valkey (`valkey`)

Part of the [service catalog](../../SERVICES.md). See
[How services work](../../SERVICES.md#how-services-work) for what is common
to every service: enabling, data, `--down`/`--purge` and host access.

**Enable**: `OCBOX_SERVICES=valkey` in `projects/<name>.env`, or `ocbox -s valkey`.

Valkey, the open-source fork of Redis. It speaks the same protocol, so Redis
clients and `redis-cli` work with it unchanged.

**Inside the box**

| Variable | Value |
|---|---|
| `VALKEY_URL` | `redis://valkey:6379/0` |

If your app expects `REDIS_URL`, map it in `projects/<name>.yaml`:

```yaml
services:
  opencode:
    environment:
      REDIS_URL: redis://valkey:6379/0
```

**Explore it**: as with [redis](../redis/README.md), using `"$VALKEY_URL"`.

**Data**: not persisted, as with redis.

**Settings**

| Variable | Default |
|---|---|
| `VALKEY_VERSION` | `8` |
