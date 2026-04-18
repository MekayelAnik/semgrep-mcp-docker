#!/bin/sh
# Smart healthcheck: probes supergateway /healthz via HAProxy frontend.
# During first-run bootstrap (TLS gen / login), HAProxy may not be up yet —
# reports healthy so the container doesn't bounce during startup.
set -eu

PORT="${PORT:-7055}"
ENABLE_HTTPS="${ENABLE_HTTPS:-false}"

# If HAProxy isn't listening yet (startup gap), report healthy
if ! nc -z 127.0.0.1 "${PORT}" >/dev/null 2>&1; then
    exit 0
fi

# HAProxy is up — probe real /healthz
SCHEME=$([ "${ENABLE_HTTPS}" = "true" ] && echo https || echo http)
exec wget -q --spider --no-check-certificate "${SCHEME}://127.0.0.1:${PORT}/healthz"
