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
- **Token absent** → auto-disable `SEMGREP_FINDINGS_DISABLED`, `SEMGREP_SCAN_REMOTE_DISABLED`, `SEMGREP_SCAN_SUPPLY_CHAIN_DISABLED` (only if user hasn't already set them). OSS mode.
- **Token present + Pro binary cached** → use cached binary, skip install.
- **Token present + binary missing + `INSTALL_PRO_ON_START=true` (default)** → run `semgrep install-semgrep-pro` inline (~376MB, 30-120s). On success: Pro active. On 401/403/network fail: log warning, fall back OSS (or exit if `REQUIRE_PRO=true`).
- **Token present + `INSTALL_PRO_ON_START=false`** → forward token only, Pro tools fail until binary installed manually.
- **`REQUIRE_PRO=true` + no token** → exit 1.
- **`REQUIRE_PRO=true` + install fails** → exit 1.

Pro binary path resolved dynamically via `semgrep.semgrep_core.SemgrepCore.path(pro=True)` with fallback to `$(dirname $(which semgrep-core))/semgrep-core-proprietary`. NOT persisted across `docker rm` (binary lives in site-packages, not a named volume). Each fresh container re-downloads if Pro wanted — intentional, avoids version-stamp drift on image upgrades.

Healthcheck `start-period=240s` to absorb Pro install on first boot.

## Universal posture

No thesis/clinical/domain-specific rules baked in. Default `SEMGREP_RULES=p/default` (exported in `start_mcp_server()`; offline-safe, no project-URL leak to `auto`). Users override with space-separated list to stack multiple registry packs + local files:

```
SEMGREP_RULES="p/default p/python p/owasp-top-ten /opt/custom-rules/local.yaml"
```

Wired via upstream `cli/src/semgrep/commands/scan.py:632` (Click `-f/--config` with `envvar=SEMGREP_RULES`, `multiple=True`). Consumed by `semgrep_scan` / `semgrep_scan_remote` subprocess. Ignored by `semgrep_scan_with_custom_rule` (rule-string wins) and `semgrep_scan_supply_chain` (hardcoded). Users mount own rules via `/opt/custom-rules:ro`. Works OSS day-1.

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

## Active upstream patches

Build-time Python patches applied to installed `semgrep` package, stored under `build_data/patches/`. Each one is **anchor-checked** — the build aborts loudly if the upstream function body drifts, forcing human review on every semgrep version bump.

| Patch file | Target | Upstream issue | Retire when |
|------------|--------|----------------|-------------|
| `fix_mcp_multirule.py` | `semgrep/mcp/server.py::get_semgrep_scan_args` | [#11644](https://github.com/semgrep/semgrep/issues/11644) (osemgrep Cmdliner SEMGREP_RULES envvar doesn't split whitespace — note: issue title mentions `--x-mcp` but real root cause is osemgrep envvar handling; correction pending) | vanilla `semgrep_scan` MCP tool accepts multi-value `SEMGREP_RULES` without the patch |

### Retirement probe

CI workflow `.github/workflows/check-patch-retirement.yml` runs weekly (+ manual dispatch). It:
1. Installs latest `semgrep` from PyPI into a clean venv (no image build, no patch applied).
2. Exercises vanilla `get_semgrep_scan_args("/tmp", None)` with `SEMGREP_RULES="p/default p/python"` env.
3. Inspects returned args: ≥2 `--config` entries ⇒ upstream fixed ⇒ opens a retirement issue on this repo.

### Renovate PR checklist

On each semgrep version-bump PR opened by Renovate:
- [ ] Anchor check still passes (build green) — if red, update anchor or retire
- [ ] Read release notes / CHANGELOG for any osemgrep envvar-handling change
- [ ] Run the retirement probe locally if unsure: `python3 -c "from semgrep.mcp.server import get_semgrep_scan_args; import os; os.environ['SEMGREP_RULES']='p/a p/b'; print(get_semgrep_scan_args('/tmp', None))"` (inside a venv with vanilla semgrep, NOT the patched image)

## Version pin

`build_data/version` = `1.159.0` (latest as of 2026-04-18). Renovate auto-bumps via custom.regex manager in `renovate.json`.
