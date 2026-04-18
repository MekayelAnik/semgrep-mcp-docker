#!/bin/bash
set -euxo pipefail
# Set variables first
REPO_NAME='semgrep-mcp-server'
BASE_IMAGE=$(cat ./build_data/base-image 2>/dev/null || echo "python:3.13-alpine")
HAPROXY_IMAGE=$(cat ./build_data/haproxy-image 2>/dev/null || echo "haproxy:lts-alpine")
SEMGREP_MCP_VERSION=$(cat ./build_data/version 2>/dev/null || exit 1)
SEMGREP_PKG="semgrep==${SEMGREP_MCP_VERSION}"
SUPERGATEWAY_PKG='supergateway@latest'
DOCKERFILE_NAME="Dockerfile.$REPO_NAME"

# Create a temporary file safely
TEMP_FILE=$(mktemp "${DOCKERFILE_NAME}.XXXXXX") || {
    echo "Error creating temporary file" >&2
    exit 1
}

# Check if this is a publication build
if [ -e ./build_data/publication ]; then
    # For publication builds, create a minimal Dockerfile that just tags the existing image
    {
        echo "ARG BASE_IMAGE=$BASE_IMAGE"
        echo "ARG SEMGREP_MCP_VERSION=$SEMGREP_MCP_VERSION"
        echo "FROM $BASE_IMAGE"
    } > "$TEMP_FILE"
else
    # Write the Dockerfile content to the temporary file first
    {
        echo "ARG BASE_IMAGE=$BASE_IMAGE"
        echo "ARG SEMGREP_MCP_VERSION=$SEMGREP_MCP_VERSION"
        cat << EOF
FROM $HAPROXY_IMAGE AS haproxy-src
FROM $BASE_IMAGE AS build

# Author info:
LABEL org.opencontainers.image.authors="MOHAMMAD MEKAYEL ANIK <mekayel.anik@gmail.com>"
LABEL org.opencontainers.image.source="https://github.com/mekayelanik/semgrep-mcp-docker"
LABEL org.opencontainers.image.description="Semgrep MCP server (official \`semgrep mcp\`) wrapped with supergateway stdio\u2192streamableHttp/SSE/WS bridge, fronted by HAProxy L7 with TLS, HTTP/2, HTTP/3 (QUIC), CORS, rate limiting, IP ACL, Bearer-token API key auth."
LABEL org.opencontainers.image.documentation="https://github.com/mekayelanik/semgrep-mcp-docker/blob/main/README.md"
LABEL org.opencontainers.image.licenses="MIT"

ARG SEMGREP_MCP_VERSION
RUN echo "Built on: \$(date -u '+%Y-%m-%d %H:%M:%S UTC') | semgrep v\${SEMGREP_MCP_VERSION}" > /tmp/build-timestamp.txt

# Copy resources into the container and make them executable
COPY ./resources/ /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/banner.sh /usr/local/bin/healthcheck.sh \\
    && mv -f /tmp/build-timestamp.txt /usr/local/bin/build-timestamp.txt \\
    && chmod +r /usr/local/bin/build-timestamp.txt \\
    && mkdir -p /etc/haproxy \\
    && mv -vf /usr/local/bin/haproxy.cfg.template /etc/haproxy/haproxy.cfg.template \\
    && ls -la /etc/haproxy/haproxy.cfg.template

# Install required APK packages
# Runtime: bash (scripts), shadow (usermod), su-exec (drop root), tzdata,
#          haproxy (replaced by QUIC build below), netcat-openbsd (healthcheck),
#          openssl (TLS self-signed), ca-certificates (rule registry HTTPS),
#          nodejs+npm (supergateway), git (semgrep registry fetch)
# Build:   build-base + libffi-dev (compile semgrep native extensions on ARM)
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/main" > /etc/apk/repositories && \\
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \\
    apk --update-cache --no-cache add \\
        bash shadow su-exec tzdata haproxy netcat-openbsd openssl ca-certificates \\
        nodejs npm git && \\
    apk --update-cache --no-cache add --virtual .build-deps build-base libffi-dev && \\
    rm -rf /var/cache/apk/*

# HAProxy with native QUIC/H3 support from official image (overrides apk haproxy)
COPY --from=haproxy-src /usr/local/sbin/haproxy /usr/sbin/haproxy
RUN mkdir -p /usr/local/sbin && ln -sf /usr/sbin/haproxy /usr/local/sbin/haproxy

# Install semgrep from PyPI (cache mount reuses pip downloads across builds)
RUN --mount=type=cache,target=/root/.cache/pip \\
    echo "Installing package: ${SEMGREP_PKG}" && \\
    pip install --no-cache-dir "${SEMGREP_PKG}" && \\
    semgrep --version && \\
    apk del .build-deps && \\
    echo "Package installed successfully"

# Install Supergateway (cache mount shares npm cache with previous step)
RUN --mount=type=cache,target=/root/.npm \\
    echo "Installing Supergateway..." && \\
    npm install -g ${SUPERGATEWAY_PKG} --omit=dev --no-audit --no-fund --loglevel error && \\
    rm -rf /tmp/* /var/tmp/* && \\
    rm -rf /usr/local/lib/node_modules/npm/man /usr/local/lib/node_modules/npm/docs /usr/local/lib/node_modules/npm/html

# Default ports and args
ARG PORT=7055
ARG INTERNAL_PORT=37055
ARG API_KEY=""

ENV PORT=\${PORT} \\
    INTERNAL_PORT=\${INTERNAL_PORT} \\
    API_KEY=\${API_KEY} \\
    PROTOCOL=SHTTP \\
    ENABLE_HTTPS=false \\
    HTTP_VERSION_MODE=auto \\
    SEMGREP_METRICS=off \\
    SEMGREP_SEND_METRICS=off \\
    PYTHONUNBUFFERED=1 \\
    PUID=1000 \\
    PGID=1000 \\
    TZ=UTC

EXPOSE \${PORT}/tcp \${PORT}/udp

# L7 health check via supergateway /healthz through HAProxy frontend
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \\
    CMD /usr/local/bin/healthcheck.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

EOF
    } > "$TEMP_FILE"
fi

# Atomically replace the target file with the temporary file
if mv -f "$TEMP_FILE" "$DOCKERFILE_NAME"; then
    echo "Dockerfile for $REPO_NAME created successfully."
else
    echo "Error: Failed to create Dockerfile for $REPO_NAME" >&2
    rm -f "$TEMP_FILE"
    exit 1
fi
