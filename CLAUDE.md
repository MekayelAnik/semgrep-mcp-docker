# Agent guide — semgrep-mcp-docker

Scope: produces `mekayelanik/semgrep-mcp-server` Docker image. Wraps upstream `semgrep mcp` (built-in since Semgrep 1.146.0) with supergateway (stdio → HTTP/SSE/WS) and HAProxy L7 (TLS, H2, H3/QUIC, CORS, Bearer auth, rate limit, IP ACL).

## Architecture

```
Client ──► HAProxy :7055 (TLS/H2/H3, Bearer, CORS, rate) ──► supergateway :37055 (loopback, /healthz) ──► stdio ──► semgrep mcp -t stdio
```

## File responsibilities

| File | Role |
|:-----|:-----|
| `DockerfileModifier.sh` | Generates `Dockerfile.semgrep-mcp-server` from `build_data/`. Reads `version`, `base-image`, `haproxy-image`. |
| `build_data/version` | Pinned semgrep PyPI version (Renovate bumps). |
| `build_data/base-image` | Base python image tag. |
| `build_data/haproxy-image` | HAProxy source image (QUIC build). |
| `build_data/publication` | Presence = CI publication build (tag-only, no rebuild). |
| `resources/entrypoint.sh` | Orchestrates: validate env → handle first run → Pro-mode gate → launch supergateway+semgrep → launch HAProxy → wait. |
| `resources/haproxy.cfg.template` | L7 template with placeholders substituted by entrypoint. |
| `resources/banner.sh` | Startup banner. |
| `resources/healthcheck.sh` | Smart healthcheck — tolerates HAProxy bootstrap gap. |

## Pro Engine gate

`resolve_pro_mode()` in entrypoint:
- Token present → `semgrep login` + full 9 tools
- Token absent → auto-disable `SEMGREP_FINDINGS_DISABLED`, `SEMGREP_SCAN_REMOTE_DISABLED`, `SEMGREP_SCAN_SUPPLY_CHAIN_DISABLED` (only if user hasn't already set them)
- `REQUIRE_PRO=true` + no token → exit 1

## Universal posture

No thesis/clinical/domain-specific rules baked in. Default `SEMGREP_RULES=p/default`. Users mount own rules via `/opt/custom-rules:ro`. Works OSS day-1.

## Upstream CLI contract (do not drift)

`semgrep mcp` accepts only: `-t/--transport {stdio,streamable-http}`, `-p/--port`, `-k/--hook`, `-a/--agent`, `-v/--version`. **No `--config` flag.** Rules flow per-tool-call.

Transports natively supported by upstream: `stdio` + `streamable-http` only. No SSE / WS / HTTP/1 — those are supergateway-provided by wrapping stdio.

Upstream binds `localhost` hard-coded. Loopback HAProxy backend works.

## Workflow chain

Full reusable chain (forked from openapi-mcp-docker pattern):
- `.github/workflows/monitor-pypi-releases.yml` — daily PyPI poll + orchestrate
- `.github/workflows/reusable-build-versions.yml` — build+push per version
- `.github/workflows/reusable-promote-latest.yml` — retag `latest`/`stable`
- `.github/workflows/update-dockerhub-readme.yml` — sync README to Docker Hub
- `.github/actions/*` — setup-build-env, registry-login, build-push-retry, promote-latest, registry-sync, resolve-build-profile, preflight-shell-tests

Build arg contract: `BASE_IMAGE`, `SEMGREP_MCP_VERSION`.

## Gotchas

- `# MCP requires Pro Engine` appears in upstream source. Some scan paths may fail without token — test before committing OSS claim.
- `stateless_http = False` required in upstream server for streamable-http session integrity.
- Rule registry fetches from `raw.githubusercontent.com` + `semgrep.dev` — must allow egress.
- FastMCP has built-in JWT auth via Semgrep API (OAuth routes at `/.well-known/oauth-*`). Our HAProxy Bearer gate stacks on top.
- Port 7055 external + 37055 loopback. Renovate won't bump these — hard-coded.

## Version pin

`build_data/version` = `1.159.0` (latest as of 2026-04-18). Renovate auto-bumps via custom.regex manager in `renovate.json`.
