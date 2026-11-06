# MinIO (`minio`)

Part of the [service catalog](../README.md). See
[How services work](../README.md#how-services-work) for what is common
to every service: enabling, data, `--down`/`--purge` and host access.

**Enable**: `ROKE_SERVICES=minio` in `~/.config/roke/projects/<name>/project.env`, or `roke -s minio`.

MinIO, S3-compatible object storage, for uploads and files your app would
store in S3.

**Inside the box**

| Variable | Value |
|---|---|
| `S3_ENDPOINT`, `AWS_ENDPOINT_URL` | `http://minio:9000` |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | `dev` / `devdevdev` |
| `AWS_REGION` | `us-east-1` |

AWS SDKs pick these variables up. Most SDKs also need **path-style
addressing** for MinIO: `forcePathStyle: true` in the JavaScript SDK,
`addressing_style: "path"` in boto3, and similar in others.

**Explore it.** The image has no S3 client; `uvx` fetches the AWS CLI on
first use, and it already uses `AWS_ENDPOINT_URL`:

```bash
uvx --from awscli aws s3 mb s3://uploads       # create a bucket
uvx --from awscli aws s3 ls s3://uploads
uvx --from awscli aws s3 cp README.md s3://uploads/
```

**From your host**: web console at <http://127.0.0.1:9001>, user `dev`,
password `devdevdev`.

**Data**: persisted in the project's `minio-data` volume.

**Settings**

| Variable | Default |
|---|---|
| `MINIO_USER` / `MINIO_PASSWORD` | `dev` / `devdevdev` (the password needs 8+ characters) |
| `MINIO_CONSOLE_PORT` | `9001` |
| `MINIO_VERSION` | `latest` |

**Note**: MinIO stopped publishing updated community images in 2025. It is
fine for local development; for something maintained, copy
`services/minio.yaml` and swap the image for another S3-compatible server.
