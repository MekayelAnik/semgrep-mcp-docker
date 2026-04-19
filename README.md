<p align="center"><img src="https://semgrep.dev/build/assets/semgrep-logo-dark-F_zJCZNg.svg" alt="Semgrep Logo" width="260"></p>

<p align="center">
  <a href="https://hub.docker.com/r/mekayelanik/semgrep-mcp-server"><img alt="Docker Pulls" src="https://img.shields.io/docker/pulls/mekayelanik/semgrep-mcp-server?style=flat-square&logo=docker"></a>
  <a href="https://hub.docker.com/r/mekayelanik/semgrep-mcp-server"><img alt="Platforms" src="https://img.shields.io/badge/Platforms-amd64%20%7C%20arm64-lightgrey?style=flat-square"></a>
  <a href="https://github.com/MekayelAnik/semgrep-mcp-docker/blob/main/LICENSE"><img alt="License: GPL v3" src="https://img.shields.io/badge/License-GPLv3-blue?style=flat-square"></a>
  <a href="https://github.com/MekayelAnik/semgrep-mcp-docker/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/MekayelAnik/semgrep-mcp-docker?style=flat-square"></a>
  <a href="https://github.com/MekayelAnik/semgrep-mcp-docker/issues"><img alt="Issues" src="https://img.shields.io/github/issues/MekayelAnik/semgrep-mcp-docker?style=flat-square"></a>
  <a href="https://github.com/MekayelAnik/semgrep-mcp-docker/commits/main"><img alt="Last Commit" src="https://img.shields.io/github/last-commit/MekayelAnik/semgrep-mcp-docker?style=flat-square"></a>
</p>

# Semgrep MCP Server

## Unofficial Multi-Architecture Docker Image for Semgrep's MCP Server

> **⚠️ Unofficial image** — community-maintained, packages the official [Semgrep CLI](https://github.com/semgrep/semgrep) (LGPL-2.1). **Not affiliated with / endorsed by Semgrep Inc.** Official: [semgrep.dev](https://semgrep.dev). Semgrep® is a trademark of Semgrep Inc.; nominative use only.

Runs official `semgrep mcp` (built into Semgrep ≥ 1.146.0) wrapped with [supergateway](https://github.com/supercorp-ai/supergateway) for stdio→HTTP/SSE/WS bridging, fronted by HAProxy L7 with TLS, HTTP/2, HTTP/3 (QUIC), CORS, rate limit, IP ACL, Bearer auth.

## Table of Contents

- [Overview](#overview)
- [Supported Architectures](#supported-architectures)
- [Available Tags](#available-tags)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [MCP Client Configuration](#mcp-client-configuration)
- [Pro Engine Mode](#pro-engine-mode)
- [Ruleset Selection](#ruleset-selection)
- [Custom Rules](#custom-rules)
- [Network Configuration](#network-configuration)
- [Updating](#updating)
- [Troubleshooting](#troubleshooting)
- [Additional Resources](#additional-resources)
- [Support & License](#support--license)

## 😎 Buy Me a Coffee ☕︎
**Your support encourages me to keep creating/supporting my open-source projects.** If you found value in this project, you can buy me a coffee to keep me inspired.

<p align="center">
  <a href="https://07mekayel07.gumroad.com/coffee" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="217" height="60">
  </a>
</p>

## Overview

Semgrep MCP exposes Semgrep's security scanner as Model Context Protocol tools any AI coding assistant (Claude Code, Cursor, Windsurf, VS Code, Claude Desktop, ChatGPT) can call directly. This image packages the official upstream server in a production-ready container — OSS works with no cloud dependencies.

### Key Features

- **Official upstream** — uses `semgrep mcp` built into Semgrep CLI (≥ 1.146.0)
- **9 MCP Tools + 2 Prompts + 2 Resources** (see [Tool Reference](#tool-reference))
- **Universal OSS + Pro** — works without a token; auto-unlocks Pro when `SEMGREP_APP_TOKEN` is set
- **Multi-arch** — native `linux/amd64` + `linux/arm64`
- **Multiple transports** — SHTTP (streamable HTTP), SSE, WebSocket via supergateway
- **Secure defaults** — Alpine base, HAProxy TLS (auto self-signed), Bearer auth, CORS, rate limit, IP ACL
- **HTTP/2 + HTTP/3 (QUIC)** — auto-negotiate or explicit version
- **PUID/PGID** — non-root with configurable UID/GID
- **Health checks** — `/healthz` endpoint through HAProxy
- **Persistent cache** — rule registry cached across restarts

### Tool Reference

| Tool | OSS | Pro |
|:-----|:---:|:---:|
| `semgrep_scan` | ✅ | ✅ |
| `semgrep_scan_with_custom_rule` | ✅ | ✅ |
| `get_abstract_syntax_tree` | ✅ | ✅ |
| `semgrep_rule_schema` | ✅ | ✅ |
| `get_supported_languages` | ✅ | ✅ |
| `semgrep_whoami` | ✅ (returns anonymous) | ✅ (returns user) |
| `semgrep_findings` | ❌ (auto-disabled) | ✅ |
| `semgrep_scan_remote` | ❌ (auto-disabled) | ✅ |
| `semgrep_scan_supply_chain` | ❌ (auto-disabled) | ✅ |

**Prompts:** `write_custom_semgrep_rule`, `setup_semgrep_mcp`

**Resources:** `semgrep://rule/schema`, `semgrep://rule/{rule_id}/yaml`

## Supported Architectures

| Architecture | Tag Prefix | Status |
|:-------------|:-----------|:------:|
| **x86-64** | `amd64-<version>` | Stable |
| **ARM64** | `arm64v8-<version>` | Stable |

> Multi-arch images automatically select the correct architecture for your system.

## Available Tags

| Tag | Description |
|:----|:------------|
| `latest` | Tracks upstream semgrep latest release |
| `stable` | Last known-good release |
| `1.159.0` | Specific version |
| `amd64-1.159.0` | Arch-pinned version |
| `arm64v8-1.159.0` | Arch-pinned version |

### System Requirements

- Docker ≥ 24.0 · Linux kernel ≥ 5.4 (QUIC/HTTP3 UDP)
- RAM: ≥ 512 MB small codebases; ≥ 2 GB large repos
- Outbound HTTPS to `semgrep.dev` + `raw.githubusercontent.com` for rule registry

## Quick Start

### Docker Compose (Recommended)

```yaml
services:
  semgrep-mcp:
    image: mekayelanik/semgrep-mcp-server:latest
    container_name: semgrep-mcp
    restart: unless-stopped
    environment:
      PORT: 7055
      PUID: 1000
      PGID: 1000
      TZ: UTC
      PROTOCOL: SHTTP
      ENABLE_HTTPS: "false"
      SEMGREP_RULES: "p/default"
      # Unlock Pro tools:
      # SEMGREP_APP_TOKEN: "${SEMGREP_APP_TOKEN}"
      # Protect endpoint:
      # API_KEY: "your-long-random-token"
    ports:
      - "7055:7055/tcp"
      - "7055:7055/udp"
    volumes:
      - ./code:/code:ro
      - ./custom-rules:/opt/custom-rules:ro
      - semgrep-cache:/home/semgrep/.semgrep
      - semgrep-registry:/home/semgrep/.cache/semgrep

volumes:
  semgrep-cache:
  semgrep-registry:
```

### Docker CLI

```bash
docker run -d --name semgrep-mcp --restart unless-stopped \
  -p 7055:7055/tcp -p 7055:7055/udp \
  -e PUID=1000 -e PGID=1000 -e TZ=UTC -e PROTOCOL=SHTTP \
  -v "$PWD/code:/code:ro" -v "$PWD/custom-rules:/opt/custom-rules:ro" \
  -v semgrep-cache:/home/semgrep/.semgrep -v semgrep-registry:/home/semgrep/.cache/semgrep \
  mekayelanik/semgrep-mcp-server:latest
```

### Access Endpoints

| Transport | Endpoint |
|:----------|:---------|
| SHTTP (streamable HTTP) | `http://host-ip:7055/mcp` |
| SSE | `http://host-ip:7055/sse` + `/message` |
| WebSocket | `ws://host-ip:7055/message` |
| Health | `http://host-ip:7055/healthz` |

## Configuration

### Environment Variables

#### Container Configuration

| Variable | Default | Description |
|:---------|:-------:|:------------|
| `PORT` | `7055` | External HAProxy port |
| `INTERNAL_PORT` | `37055` | Internal supergateway port (loopback) |
| `PUID` | `1000` | User ID for file permissions |
| `PGID` | `1000` | Group ID for file permissions |
| `TZ` | `UTC` | Container timezone ([TZ database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)) |
| `PROTOCOL` | `SHTTP` | Transport: `SHTTP` / `SSE` / `WS` |

#### Semgrep Configuration

| Variable | Default | Description |
|:---------|:-------:|:------------|
| `SEMGREP_APP_TOKEN` | _(unset)_ | AppSec Platform token — enables Pro tools |
| `REQUIRE_PRO` | `false` | If `true`, exits 1 when token is missing |
| `SEMGREP_RULES` | `p/default` | Default ruleset(s) — **space-separated** list (see [Ruleset Selection](#ruleset-selection)) |
| `SEMGREP_METRICS` | `off` | Telemetry (`on` / `off`) |
| `SEMGREP_SEND_METRICS` | `off` | Telemetry (`on` / `off`) |
| `USE_SEMGREP_RPC` | _(unset)_ | Set `true` to use RPC backend over pysemgrep CLI |

#### Per-Tool Overrides

Set any of these to `true` to disable the corresponding MCP tool. In OSS mode, the last three are auto-enabled-as-disabled when `SEMGREP_APP_TOKEN` is unset.

| Variable | Default |
|:---------|:-------:|
| `SEMGREP_RULE_SCHEMA_DISABLED` | `false` |
| `GET_SUPPORTED_LANGUAGES_DISABLED` | `false` |
| `SEMGREP_SCAN_WITH_CUSTOM_RULE_DISABLED` | `false` |
| `SEMGREP_SCAN_DISABLED` | `false` |
| `GET_ABSTRACT_SYNTAX_TREE_DISABLED` | `false` |
| `SEMGREP_FINDINGS_DISABLED` | auto |
| `SEMGREP_SCAN_REMOTE_DISABLED` | auto |
| `SEMGREP_SCAN_SUPPLY_CHAIN_DISABLED` | auto |

#### TLS / HTTPS Configuration

| Variable | Default | Description |
|:---------|:-------:|:------------|
| `ENABLE_HTTPS` | `false` | Enable TLS at HAProxy frontend |
| `TLS_CERT_PATH` | `/etc/haproxy/certs/server.crt` | Custom cert path |
| `TLS_KEY_PATH` | `/etc/haproxy/certs/server.key` | Custom key path |
| `TLS_CN` | `localhost` | Common Name for auto-generated cert |
| `TLS_SAN` | `DNS:<TLS_CN>` | Subject Alternative Name |
| `TLS_DAYS` | `365` | Self-signed cert validity (days) |
| `TLS_MIN_VERSION` | `TLSv1.3` | `TLSv1.2` or `TLSv1.3` |
| `HTTP_VERSION_MODE` | `auto` | `auto` / `h1` / `h2` / `h3` / `h1+h2` / `all` |

#### Security Configuration

| Variable | Default | Description |
|:---------|:-------:|:------------|
| `API_KEY` | _(unset)_ | Bearer-token required on all requests except `/healthz` |
| `CORS` | _(unset)_ | Allowed origins: `*` / `all` / comma-separated list |
| `RATE_LIMIT` | `0` | Max requests per period (`0` = disabled) |
| `RATE_LIMIT_PERIOD` | `10s` | Period: `10s` / `1m` / `1h` / `1d` |
| `MAX_CONNECTIONS_PER_IP` | `0` | Concurrent connections cap per source IP |
| `IP_ALLOWLIST` | _(unset)_ | Comma-separated CIDRs (only these may connect) |
| `IP_BLOCKLIST` | _(unset)_ | Comma-separated CIDRs (denied) |

### HTTPS and HTTP Version Notes

- `ENABLE_HTTPS=false` → always HTTP/1.1 (TLS required for HTTP/2 and HTTP/3)
- `HTTP_VERSION_MODE=auto` with TLS → negotiates HTTP/1.1 + HTTP/2 + HTTP/3 (QUIC build required)
- HTTP/3 requires UDP mapping (`-p 7055:7055/udp`)

### API Key Authentication Notes

Clients send `Authorization: Bearer <API_KEY>`. `/healthz` bypasses auth. Constant-time validation in HAProxy. Length 5-256 chars; no whitespace/control chars.

### User & Group IDs

Find yours: `id $USER`

### Timezone Examples

`UTC`, `America/New_York`, `Europe/Berlin`, `Asia/Dhaka`, `Asia/Tokyo`, `Australia/Sydney`

## MCP Client Configuration

### Transport Support

| Transport | URL Format |
|:----------|:-----------|
| SHTTP | `http[s]://host:7055/mcp` |
| SSE | `http[s]://host:7055/sse` (events), `http[s]://host:7055/message` (POST) |
| WebSocket | `ws[s]://host:7055/message` |

### CLI-based clients

```bash
# Claude Code
claude mcp add --transport http semgrep http://host-ip:7055/mcp
# with auth: append --header "Authorization: Bearer your-token"

# Codex CLI
codex mcp add semgrep --url http://host-ip:7055/mcp --transport http
```

### JSON-config clients (Claude Desktop / Cursor / Windsurf / VS Code)

Config paths: Claude Desktop → `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows) · Cursor → `~/.cursor/mcp.json` · Windsurf → `~/.codeium/windsurf/mcp_config.json`.

```json
{
  "mcpServers": {
    "semgrep": {
      "transport": { "type": "http", "url": "http://host-ip:7055/mcp" }
    }
  }
}
```

Key varies per client: Claude Desktop uses `transport.url`, Cursor uses `url`, Windsurf uses `serverUrl`. **VS Code (Cline / Roo-Cline):** Settings → MCP Servers → Add → Name=`semgrep`, Transport=`http`, URL=`http://host-ip:7055/mcp`.

### Testing

```bash
npx -y @modelcontextprotocol/inspector http://host-ip:7055/mcp
```

## Pro Engine Mode

Semgrep Pro (AppSec Platform) unlocks 3 additional tools. To enable:

1. Get a token from [semgrep.dev/orgs/-/settings/tokens](https://semgrep.dev/orgs/-/settings/tokens)
2. Set `SEMGREP_APP_TOKEN=<your-token>` in compose or via `-e`
3. Restart container — entrypoint forwards token to `semgrep mcp` subprocess (read directly from env every tool call; **no `semgrep login`**), auto-downloads Pro Engine binary (~376 MB) if missing, and unlocks `semgrep_findings` (AppSec platform findings), `semgrep_scan_remote` (hosted repo scan), `semgrep_scan_supply_chain` (SCA).

**Pro binary auto-install:** `INSTALL_PRO_ON_START` (default `true`). On 401/403/network fail → OSS fallback with three Pro tools auto-disabled. Binary lives in `site-packages`, not in `/home/semgrep/.semgrep` volume — intentional, keeps binary version matched to Semgrep CLI on image upgrade.

**Strict mode:** `REQUIRE_PRO=true` — exits 1 if token missing OR Pro install fails. For CI / prod.

**OSS mode** works without any setup. Default ruleset is `p/default` (curated by Semgrep); change via `SEMGREP_RULES` env.

## Ruleset Selection

`SEMGREP_RULES` stacks any number of registry packs, local YAMLs, or HTTPS URLs in a single scan. Wired to upstream `-f/--config` (Click `multiple=True`). Rules auto-dedup by ID.

### Syntax — space-separated (NOT comma)

```bash
SEMGREP_RULES="p/default p/python"
SEMGREP_RULES="p/default p/python p/owasp-top-ten /opt/custom-rules/local_rules.yaml"
```

Equivalent CLI: `semgrep scan --config p/default --config p/python --config /opt/custom-rules/local_rules.yaml`

### Value types

| Form | Example | Meaning |
|:-----|:--------|:--------|
| `p/<pack>` | `p/python` | Registry ruleset |
| `r/<rule-id>` | `r/python.lang.security.audit.eval-detected` | Single registry rule |
| Absolute path | `/opt/custom-rules/local.yaml` | Local YAML inside container |
| HTTPS URL | `https://example.com/rules.yaml` | Remote YAML |
| `auto` | `auto` | Cloud auto-config (logs project URL) |
| `supply-chain` | `supply-chain` | SCA scan (Pro) |

> Local paths must be **absolute + valid inside the container**. Mount host rules at `/opt/custom-rules` → reference as `/opt/custom-rules/<file>.yaml`. No spaces, no `~` expansion.

### Usage

```yaml
# docker-compose
environment:
  SEMGREP_RULES: "p/default p/python p/django /opt/custom-rules/local_rules.yaml"
volumes:
  - ./my-rules:/opt/custom-rules:ro
```

```bash
# docker CLI
docker run -d -e SEMGREP_RULES="p/default p/python p/owasp-top-ten" \
  -v "$PWD/my-rules:/opt/custom-rules:ro" -p 7055:7055/tcp -p 7055:7055/udp \
  mekayelanik/semgrep-mcp-server:latest

# verify
docker exec semgrep-mcp sh -c 'echo $SEMGREP_RULES'
docker exec semgrep-mcp semgrep scan --dry-run /code 2>&1 | head -20
```

### Curated registry packs (official, by Semgrep)

**Top-level:** `p/default` (2852) · `p/owasp-top-ten` (2283) · `p/cwe-top-25` (1452) · `p/r2c-security-audit` (225, alias `p/security-audit`) · `p/r2c-best-practices` (125) · `p/secure-defaults` (62) · `p/r2c-bug-scan` (44) · `p/comment` (1556, noisy)

**Languages:** `p/python` (1069) · `p/javascript` (316) · `p/typescript` (316) · `p/nodejs` (248) · `p/java` (239) · `p/csharp` (178) · `p/golang` (113) · `p/kotlin` (71) · `p/ruby` (66) · `p/swift` (64) · `p/rust` (60) · `p/c` (53, also C++) · `p/php` (53) · `p/apex` (22) · `p/ocaml` (27) · `p/elixir` (14) · `p/scala` (12)

**Frameworks:** `p/expressjs` (279) · `p/flask` (220) · `p/django` (183) · `p/fastapi` (152) · `p/koa` (145) · `p/hapi` (141) · `p/nestjs` (31) · `p/play` (23) · `p/brakeman` (19, Rails) · `p/php-laravel` (15) · `p/react-best-practices` (13) · `p/nextjs` (6) · `p/react` (5)

**Vulnerability categories:** `p/sql-injection` (320) · `p/secrets` (269) · `p/gitleaks` (175) · `p/shadow-ai` (140) · `p/command-injection` (100) · `p/xss` (83) · `p/agent-skills` (63) · `p/security-headers` (37) · `p/ai-best-practices` (27) · `p/jwt` (25) · `p/mcp` (19)

**IaC / config:** `p/terraform` (63) · `p/kubernetes` (11) · `p/docker` / `p/dockerfile` (7, Hadolint port) · `p/docker-compose` (6)

**Meta / misc:** `p/c-audit-banned-functions` (100, MS banned-fn list) · `p/phpcs-security-audit` (9) · `p/cpp-audit` (6) · `p/semgrep-rule-lints` (6) · `p/semgrep-misconfigurations` (1)

### High-quality community / third-party packs

| Pack | Rules | Author | Focus |
|:-----|:-----:|:-------|:------|
| `p/gitlab` | 544 | GitLab | Multi-language security |
| `p/findsecbugs` | 286 | Semgrep+GitLab | Java security (FindSecBugs port) |
| `p/trailofbits` | 120 | Trail of Bits | Python/Go/Rust audit rules ([repo](https://github.com/trailofbits/semgrep-rules)) |
| `p/bandit` / `p/gitlab-bandit` | 90 | GitLab+Semgrep | Python security (Bandit port) |
| `p/semgrep-go-correctness` | 66 | Damian Gryski | Go correctness ([repo](https://github.com/dgryski/semgrep-go)) |
| `p/flawfinder` | 64 | GitLab | C security (Flawfinder port) |
| `p/insecure-transport` | 53 | Colleen Dai | Cross-language HTTP leaks |
| `p/smart-contracts` | 50 | Decurity | Solidity / Vyper |
| `p/mobsfscan` | 43 | MobSF | Android / iOS |

> `p/elttam` is NOT a registry shortcut (only hidden `ben-elttam.*` internal packs exist). Closest equivalent: `p/trailofbits + p/r2c-security-audit`. Live index: [semgrep.dev/api/registry/rulesets](https://semgrep.dev/api/registry/rulesets) · browse: [semgrep.dev/explore](https://semgrep.dev/explore)

### Starter combinations

```bash
# Python web (Django/Flask/FastAPI)
SEMGREP_RULES="p/default p/python p/django p/flask p/fastapi p/owasp-top-ten p/secrets"
# Node.js / TypeScript
SEMGREP_RULES="p/default p/typescript p/javascript p/nodejs p/expressjs p/owasp-top-ten p/secrets"
# Go
SEMGREP_RULES="p/default p/golang p/semgrep-go-correctness p/owasp-top-ten p/secrets"
# Java / Spring
SEMGREP_RULES="p/default p/java p/findsecbugs p/owasp-top-ten p/secrets"
# Rust
SEMGREP_RULES="p/default p/rust p/trailofbits p/secrets"
# Audit-grade Python
SEMGREP_RULES="p/default p/python p/r2c-security-audit p/trailofbits p/owasp-top-ten p/cwe-top-25"
# IaC (Terraform + K8s + Docker)
SEMGREP_RULES="p/terraform p/kubernetes p/dockerfile p/docker-compose p/secrets"
# Smart contracts
SEMGREP_RULES="p/default p/smart-contracts p/secrets"
# AI / LLM apps
SEMGREP_RULES="p/default p/ai-best-practices p/shadow-ai p/agent-skills p/mcp p/secrets"
```

### Precedence

- `SEMGREP_RULES` drives every `semgrep_scan` / `semgrep_scan_remote` via env-inherited `-f`.
- `semgrep_scan_with_custom_rule(code_files, rule)` — explicit `rule` YAML **overrides** (not appends) `SEMGREP_RULES`. Stack rules in one `rules:` list.
- `semgrep_scan_supply_chain` — hardcoded `--config supply-chain`; `SEMGREP_RULES` ignored.
- Unset → default `p/default`. `auto` → cloud fetch (leaks project URL).

> **Multi-value note:** upstream osemgrep does not split `SEMGREP_RULES` on whitespace; this image bakes a build-time patch (`build_data/patches/fix_mcp_multirule.py`, anchor-checked) so multi-value works transparently for all MCP tools.

## Code & Rules Directories

Scan target + custom-rules dirs are env-configurable via `.env` or shell env. Compose auto-loads `.env` next to `docker-compose.yml`.

| Variable | Default | Description |
|:---------|:-------:|:------------|
| `CODE_DIR` | `./code` | Host path mounted read-only at `/code` |
| `CUSTOM_RULES_DIR` | `./custom-rules` | Host path mounted read-only at `/opt/custom-rules` |

```bash
cp .env.example .env
# edit to:
#   CODE_DIR=/home/user/projects/myapp
#   CUSTOM_RULES_DIR=/home/user/semgrep-rules
docker compose up -d
# client: semgrep_scan(path="/code/src/main.py")

# no .env — shell override:
CODE_DIR=/path/to/code docker compose up -d
```

### Custom rules

Clients invoke `semgrep_scan_with_custom_rule` with inline YAML, OR reference paths under `/opt/custom-rules/`. See [semgrep.dev/docs/writing-rules](https://semgrep.dev/docs/writing-rules/overview) for syntax.

## Network Configuration

### Comparison

| Network | Isolation | Exposed |
|:--------|:---------:|:--------|
| Bridge (default) | ✅ | Host:`7055` → Container:`7055` |
| Host (Linux) | ❌ | Direct on container port |
| MACVLAN | ✅ | Dedicated IP on LAN |

### Bridge Network (Default)

```yaml
services:
  semgrep-mcp:
    image: mekayelanik/semgrep-mcp-server:latest
    ports:
      - "7055:7055/tcp"
      - "7055:7055/udp"
```

**Access:** `http://localhost:7055/mcp`

### Host Network (Linux Only)

```yaml
services:
  semgrep-mcp:
    image: mekayelanik/semgrep-mcp-server:latest
    network_mode: host
```

### MACVLAN Network (Advanced)

See the [Docker MACVLAN docs](https://docs.docker.com/network/macvlan/) for setup. Give the container its own LAN IP to avoid port collisions.

## Updating

### Docker Compose

```bash
docker compose pull && docker compose up -d
```

### Docker CLI

```bash
docker pull mekayelanik/semgrep-mcp-server:latest
docker stop semgrep-mcp && docker rm semgrep-mcp
# re-run with same args
```

### One-Time Update with Watchtower

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower --run-once semgrep-mcp
```

## Troubleshooting

### Pre-Flight Checklist

1. `docker ps` shows `healthy`
2. `curl http://host-ip:7055/healthz` returns 200
3. `docker logs semgrep-mcp` — banner shown, no errors
4. Outbound: container reaches `semgrep.dev` + `raw.githubusercontent.com`

### Common Issues

#### Container Won't Start

- Port 7055 already bound on host
- PUID/PGID not positive integers
- `API_KEY` wrong length (must be 5–256, no whitespace)

#### Permission Errors

- Volume owned by wrong UID: `chown -R 1000:1000 ./custom-rules`
- Or match host: `PUID=$(id -u) PGID=$(id -g)`

#### Client Cannot Connect

- Firewall blocking 7055/tcp or 7055/udp
- TLS on but client uses `http://` — switch to `https://`
- `API_KEY` set but client missing `Authorization: Bearer ...`
- Wrong endpoint: SHTTP=`/mcp`, SSE=`/sse`+`/message`, WS=`/message`

#### Slow First Scan

First scan downloads + caches rule registry. Mount persistent volume (see compose).

#### Pro Tools Disabled

- Token unset → three Pro tools auto-disabled
- Token invalid (401/403) → check logs for `Pro Engine install failed`; regenerate at [semgrep.dev/orgs/-/settings/tokens](https://semgrep.dev/orgs/-/settings/tokens). **Container does NOT run `semgrep login`** — token consumed from env per-call; no login-failed line exists
- Pro binary install fail (egress blocked / deployment lacks Pro) → OSS fallback. `REQUIRE_PRO=true` to exit 1
- `INSTALL_PRO_ON_START=false` skips the 376 MB download; install manually via `docker exec semgrep-mcp semgrep install-semgrep-pro`

### Debug Information

```bash
docker exec semgrep-mcp semgrep --version
docker exec semgrep-mcp semgrep mcp --help
docker logs --tail 200 semgrep-mcp
```

## Additional Resources

**Docs:** [Semgrep](https://semgrep.dev/docs/) · [Semgrep MCP upstream](https://github.com/semgrep/semgrep/tree/develop/cli/src/semgrep/mcp) · [MCP protocol](https://modelcontextprotocol.io/) · [supergateway](https://github.com/supercorp-ai/supergateway)

**Project:** [DockerfileModifier](./DockerfileModifier.sh) · [compose example](./docker-compose.yml) · [GitHub repo](https://github.com/mekayelanik/semgrep-mcp-docker)

**Monitoring:** `/healthz` returns 200 with supergateway status — wire into Prometheus blackbox, Uptime Kuma, etc.

## 😎 Buy Me a Coffee ☕︎

Image saved you time? [Buy me a coffee](https://buymeacoffee.com/mekayelanik).

## Support & License

### Getting Help

- Issues: [github.com/mekayelanik/semgrep-mcp-docker/issues](https://github.com/mekayelanik/semgrep-mcp-docker/issues)
- Discussions: [github.com/mekayelanik/semgrep-mcp-docker/discussions](https://github.com/mekayelanik/semgrep-mcp-docker/discussions)

### Contributing

PRs welcome. Keep changes minimal, match existing code style, preserve universal (non-opinionated) defaults.

### License & Attribution

Docker packaging: **GPL-3.0-or-later** — see [LICENSE](./LICENSE). Packaged software retains its original licensing:
- **Semgrep CLI** — LGPL-2.1 ([license](https://github.com/semgrep/semgrep/blob/develop/LICENSE))
- **Semgrep Registry rules** (fetched at runtime, not bundled) — Semgrep ToS, [semgrep.dev/legal](https://semgrep.dev/legal/)
- **Semgrep Pro Engine** (requires your own token, not bundled) — proprietary, [semgrep.dev/legal](https://semgrep.dev/legal/)
- **supergateway** — MIT ([repo](https://github.com/supercorp-ai/supergateway))
- **HAProxy** — GPL-2.0-or-later ([haproxy.org](https://www.haproxy.org/))

### Trademark Notice

**Semgrep®** is a registered trademark of Semgrep Inc. Unofficial community packaging, not affiliated with or endorsed by Semgrep Inc. Name/logo used nominatively to identify packaged software. Official Semgrep: [semgrep.dev](https://semgrep.dev).
