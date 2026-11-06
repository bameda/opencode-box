# Spring Boot service

- Build and test with the project's wrapper: `./mvnw test` (or
  `./gradlew test`). Before considering a task done, the tests must pass.
- There is no Docker in this box: tests that use Testcontainers cannot run
  here. Exclude them (for example `./mvnw test -DexcludedGroups=containers`)
  and tell the user which ones to run on their machine; never try to make
  Docker available.
- The database and Kafka are already configured through `SPRING_*`
  environment variables; do not hardcode their addresses in
  `application.yml`.
- Start the app with `./mvnw spring-boot:run`; it listens on port 8080.
