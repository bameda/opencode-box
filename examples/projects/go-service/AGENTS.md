# Go service

- Before considering a task done, run `go build ./...`, `go test ./...`
  and `golangci-lint run`, and fix what they report.
- Format with `gofmt` (golangci-lint checks it). Add dependencies with
  `go get`, then run `go mod tidy`.
- The service listens on `:8080`. Configuration comes from the environment:
  `DATABASE_URL` and `NATS_URL`.
