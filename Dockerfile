# syntax=docker/dockerfile:1
#
# Working image for OpenCode 2. It only sees what gets mounted into it
# (the project, its own $HOME in a volume and ./config/opencode).
FROM debian:trixie-slim

# Host user's UID/GID, so files the agent creates in the project are owned
# by you. bin/ocbox passes them automatically.
ARG HOST_UID=1000
ARG HOST_GID=1000

# OpenCode 2 (npm package @opencode/cli). Pin a version for reproducible
# builds: changing it invalidates this layer's cache.
ARG OPENCODE_VERSION=latest

# PostgreSQL client tools (psql, pg_dump...) from the official PGDG repo.
# Keep it >= the server's major: pg_dump refuses to dump newer servers.
ARG POSTGRES_CLIENT_VERSION=18

# Serena (semantic code navigation/editing MCP). INSTALL_SERENA=0 skips it.
ARG INSTALL_SERENA=1
ARG SERENA_VERSION=2.1.0
ARG SERENA_PYTHON=3.13

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Base tools. Specific languages (node, python, java, clojure, rust, go...)
# are installed per project with mise.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl wget gnupg \
      git less nano vim-tiny tree file procps \
      ripgrep fd-find jq \
      unzip zip xz-utils bzip2 zstd \
      build-essential pkg-config libssl-dev \
      python3 python3-venv python3-pip \
      nodejs npm \
      mariadb-client redis-tools sqlite3 \
      ncurses-term \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# PostgreSQL client from apt.postgresql.org (Debian's is older).
RUN install -d /usr/share/postgresql-common/pgdg \
    && curl -fsSL -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
         https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    && . /etc/os-release \
    && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg main" \
         > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends "postgresql-client-${POSTGRES_CLIENT_VERSION}" \
    && rm -rf /var/lib/apt/lists/* \
    && psql --version

# mise: per-project version manager for languages and tools.
RUN curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh \
    && mise --version

# uv: required by Serena and handy for Python projects.
RUN curl -LsSf https://astral.sh/uv/install.sh \
      | env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh \
    && uv --version

# Serena, installed under /opt (outside the box's $HOME) with its own Python.
# A base config is generated with the dashboard disabled and no browser
# launch; the entrypoint copies it to ~/.serena on first use.
RUN if [ "${INSTALL_SERENA}" = "1" ]; then \
      set -eux; \
      export UV_TOOL_DIR=/opt/uv/tools UV_TOOL_BIN_DIR=/usr/local/bin \
             UV_PYTHON_INSTALL_DIR=/opt/uv/python UV_CACHE_DIR=/tmp/uv-cache; \
      uv tool install -p "${SERENA_PYTHON}" "serena-agent==${SERENA_VERSION}"; \
      tmpl="$(find /opt/uv/tools/serena-agent -name serena_config.template.yml | head -n1)"; \
      install -d /opt/serena; \
      sed -E \
        -e 's/^web_dashboard:.*/web_dashboard: False/' \
        -e 's/^web_dashboard_open_on_launch:.*/web_dashboard_open_on_launch: False/' \
        -e 's/^gui_log_window:.*/gui_log_window: False/' \
        "$tmpl" > /opt/serena/serena_config.base.yml; \
      rm -rf /tmp/uv-cache; \
      serena --help >/dev/null; \
    fi

# OpenCode 2. The npm postinstall picks the native binary for the platform.
RUN npm install -g "@opencode/cli@${OPENCODE_VERSION}" \
    && opencode --version \
    && npm cache clean --force

# Unprivileged user with the same UID/GID as on the host. No sudo.
# /etc/opencode is OpenCode's system config (highest precedence); the
# entrypoint regenerates it on every start.
RUN set -eux; \
    if ! getent group "${HOST_GID}" >/dev/null; then groupadd -g "${HOST_GID}" dev; fi; \
    if getent passwd "${HOST_UID}" >/dev/null; then \
      userdel -r "$(getent passwd "${HOST_UID}" | cut -d: -f1)" || true; \
    fi; \
    useradd -m -u "${HOST_UID}" -g "${HOST_GID}" -s /bin/bash -d /home/dev dev; \
    install -d -o "${HOST_UID}" -g "${HOST_GID}" \
      /home/dev/.config/opencode \
      /home/dev/.local/bin /home/dev/.local/share /home/dev/.local/state \
      /home/dev/.cache /home/dev/.serena \
      /etc/opencode

COPY --chmod=0755 docker/entrypoint.sh /usr/local/bin/ocbox-entrypoint

ENV HOME=/home/dev \
    SHELL=/bin/bash \
    MISE_YES=1 \
    SERENA_HOME=/home/dev/.serena \
    npm_config_cache=/home/dev/.cache/npm \
    PATH=/home/dev/.local/share/mise/shims:/home/dev/.local/bin:/home/dev/.cargo/bin:${PATH}

USER dev
WORKDIR /home/dev

ENTRYPOINT ["/usr/local/bin/ocbox-entrypoint"]
CMD ["opencode"]
