# The project's gateway: the only container with a route out of the
# project's internal network. It enforces the network policy for the box
# (which shares its network namespace) and publishes ports on the host.
FROM debian:trixie-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      nftables dnsmasq-base socat iproute2 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --no-create-home --shell /usr/sbin/nologin dnsmasq

COPY --chmod=0755 gateway.sh /usr/local/bin/roke-gateway

HEALTHCHECK --interval=1s --timeout=3s --retries=60 CMD test -f /run/roke-gateway.ready
ENTRYPOINT ["/usr/local/bin/roke-gateway", "start"]
