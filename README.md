<p align="center"><img src="https://semgrep.dev/build/assets/semgrep-logo-dark-F_zJCZNg.svg" alt="Semgrep Logo" width="260"></p>

<p align="center">
  <a href="https://hub.docker.com/r/mekayelanik/semgrep-mcp-server"><img alt="Docker Pulls" src="https://img.shields.io/docker/pulls/mekayelanik/semgrep-mcp-server?style=flat-square&logo=docker"></a>
  <a href="https://hub.docker.com/r/mekayelanik/semgrep-mcp-server"><img alt="Docker Stars" src="https://img.shields.io/docker/stars/mekayelanik/semgrep-mcp-server?style=flat-square&logo=docker"></a>
  <a href="https://github.com/MekayelAnik/semgrep-mcp-docker/pkgs/container/semgrep-mcp-server"><img alt="GHCR" src="https://img.shields.io/badge/GHCR-ghcr.io%2Fmekayelanik%2Fsemgrep--mcp--server-blue?style=flat-square&logo=github"></a>
  <a href="https://github.com/MekayelAnik/semgrep-mcp-docker/blob/main/LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue?style=flat-square"></a>
  <a href="https://hub.docker.com/r/mekayelanik/semgrep-mcp-server"><img alt="Platforms" src="https://img.shields.io/badge/Platforms-amd64%20%7C%20arm64-lightgrey?style=flat-square"></a>
  <a href="https://github.com/MekayelAnik/semgrep-mcp-docker/stargazers"><img alt="GitHub Stars" src="https://img.shields.io/github/stars/MekayelAnik/semgrep-mcp-docker?style=flat-square"></a>
  <a href="https://github.com/MekayelAnik/semgrep-mcp-docker/forks"><img alt="GitHub Forks" src="https://img.shields.io/github/forks/MekayelAnik/semgrep-mcp-docker?style=flat-square"></a>
  <a href="https://github.com/MekayelAnik/semgrep-mcp-docker/issues"><img alt="GitHub Issues" src="https://img.shields.io/github/issues/MekayelAnik/semgrep-mcp-docker?style=flat-square"></a>
  <a href="https://github.com/MekayelAnik/semgrep-mcp-docker/commits/main"><img alt="Last Commit" src="https://img.shields.io/github/last-commit/MekayelAnik/semgrep-mcp-docker?style=flat-square"></a>
</p>

# Semgrep MCP Server

## Unofficial Multi-Architecture Docker Image for Semgrep's Model Context Protocol Server

> **⚠️ Unofficial Image** — This is a community-maintained Docker image packaging the official [Semgrep CLI](https://github.com/semgrep/semgrep) (LGPL-2.1) with runtime tooling. It is **not affiliated with, endorsed by, or supported by Semgrep Inc.** For official Semgrep offerings see [semgrep.dev](https://semgrep.dev). Semgrep® is a trademark of Semgrep Inc.; this project makes nominative use only to indicate the software packaged.

Runs the official `semgrep mcp` server (built into Semgrep ≥ 1.146.0) wrapped with [supergateway](https://github.com/supercorp-ai/supergateway) for stdio→HTTP/SSE/WS bridging, fronted by HAProxy L7 with TLS, HTTP/2, HTTP/3 (QUIC), CORS, rate limiting, IP ACL, and Bearer-token API key authentication.

## Table of Contents

- [Overview](#overview)
- [Supported Architectures](#supported-architectures)
- [Available Tags](#available-tags)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [MCP Client Configuration](#mcp-client-configuration)
- [Pro Engine Mode](#pro-engine-mode)
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

Semgrep MCP exposes Semgrep's security scanner as a set of Model Context Protocol tools AI coding assistants (Claude Code, Cursor, Windsurf, VS Code, Claude Desktop, ChatGPT) can call directly. This image packages the official upstream server in a production-ready container with no cloud dependencies required for OSS use.

### Key Features

- **Official Upstream** — uses `semgrep mcp` built into Semgrep CLI (≥ 1.146.0), not a third-party wrapper
- **9 MCP Tools + 2 Prompts + 2 Resources** (see [Tool Reference](#tool-reference))
- **Universal OSS + Pro Modes** — works out of the box without any token; auto-unlocks Pro features when `SEMGREP_APP_TOKEN` is set
- **Multi-Architecture** — native `linux/amd64` and `linux/arm64`
- **Multiple Transports** — SHTTP (streamable HTTP), SSE, WebSocket via supergateway
- **Secure by Default** — Alpine-based, minimal attack surface, HAProxy TLS with self-signed cert auto-gen, Bearer-token auth, CORS validation, rate limiting, IP ACL
- **HTTP/2 + HTTP/3 (QUIC)** — auto-negotiation or explicit version selection
- **PUID/PGID** — runs as non-root user with configurable UID/GID mapping
- **Health Checks** — supergateway `/healthz` endpoint passes through HAProxy
- **Persistent Cache** — semgrep rule registry cached across restarts

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

- Docker Engine ≥ 24.0
- Linux kernel ≥ 5.4 (for QUIC/HTTP3 UDP)
- ≥ 512 MB RAM (small codebases); ≥ 2 GB for large repos
- Outbound HTTPS access to `semgrep.dev` and `raw.githubusercontent.com` for rule registry

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
docker run -d \
  --name semgrep-mcp \
  -p 7055:7055/tcp -p 7055:7055/udp \
  -e PUID=1000 -e PGID=1000 -e TZ=UTC \
  -e PROTOCOL=SHTTP \
  -v "$PWD/code:/code:ro" \
  -v "$PWD/custom-rules:/opt/custom-rules:ro" \
  -v semgrep-cache:/home/semgrep/.semgrep \
  -v semgrep-registry:/home/semgrep/.cache/semgrep \
  --restart unless-stopped \
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
| `SEMGREP_RULES` | `p/default` | Default ruleset(s) — comma-separated |
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
- `HTTP_VERSION_MODE=auto` with TLS → negotiates HTTP/1.1 + HTTP/2 + HTTP/3 (if HAProxy QUIC build present)
- HTTP/3 requires UDP port mapping (`-p 7055:7055/udp`)

### API Key Authentication Notes

Clients must send `Authorization: Bearer <API_KEY>`. Health checks on `/healthz` always bypass auth. Token validation is constant-time at the HAProxy layer. Minimum length 5 chars; maximum 256. Whitespace/control chars are rejected.

### User & Group IDs

Find yours:
```bash
id $USER
```

### Timezone Examples

`UTC`, `America/New_York`, `Europe/Berlin`, `Asia/Dhaka`, `Asia/Tokyo`, `Australia/Sydney`

## MCP Client Configuration

### Transport Support

| Transport | URL Format |
|:----------|:-----------|
| SHTTP | `http[s]://host:7055/mcp` |
| SSE | `http[s]://host:7055/sse` (events), `http[s]://host:7055/message` (POST) |
| WebSocket | `ws[s]://host:7055/message` |

### Claude Code

```bash
claude mcp add --transport http semgrep http://host-ip:7055/mcp
# With auth:
claude mcp add --transport http semgrep http://host-ip:7055/mcp \
  --header "Authorization: Bearer your-token"
```

### Claude Desktop App

Edit `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "semgrep": {
      "transport": { "type": "http", "url": "http://host-ip:7055/mcp" }
    }
  }
}
```

### Cursor

Edit `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "semgrep": {
      "url": "http://host-ip:7055/mcp"
    }
  }
}
```

### VS Code (Cline / Roo-Cline)

Settings → MCP Servers → Add:
- Name: `semgrep`
- Transport: `http`
- URL: `http://host-ip:7055/mcp`

### Codex CLI

```bash
codex mcp add semgrep --url http://host-ip:7055/mcp --transport http
```

### Windsurf

```json
{
  "mcpServers": {
    "semgrep": {
      "serverUrl": "http://host-ip:7055/mcp"
    }
  }
}
```

### Testing Configuration

```bash
npx -y @modelcontextprotocol/inspector http://host-ip:7055/mcp
```

## Pro Engine Mode

Semgrep Pro (AppSec Platform) unlocks 3 additional tools. To enable:

1. Get a token from [semgrep.dev/orgs/-/settings/tokens](https://semgrep.dev/orgs/-/settings/tokens)
2. Set `SEMGREP_APP_TOKEN=<your-token>` in compose or via `-e`
3. Restart the container — the entrypoint auto-runs `semgrep login` and unlocks:
   - `semgrep_findings` (fetch findings from AppSec Platform)
   - `semgrep_scan_remote` (scan hosted repositories)
   - `semgrep_scan_supply_chain` (SCA scanning)

**Strict mode:** set `REQUIRE_PRO=true` alongside the token to fail-fast if the token is missing — useful for CI and production deployments.

**OSS mode** works without any setup. Default ruleset is `p/default` (curated by Semgrep); change via `SEMGREP_RULES` env.

## Code & Rules Directories

Both the scan target directory and the custom-rules directory are env-configurable via a `.env` file or shell env vars. Compose auto-loads `.env` next to `docker-compose.yml`.

### `.env` file

```bash
cp .env.example .env
# edit .env
```

| Variable | Default | Description |
|:---------|:-------:|:------------|
| `CODE_DIR` | `./code` | Host path to the code you want semgrep to scan (mounted read-only at `/code`) |
| `CUSTOM_RULES_DIR` | `./custom-rules` | Host path to your YAML rule files (mounted read-only at `/opt/custom-rules`) |

### Example

```bash
# ~/projects/myapp → scanned at /code inside container
CODE_DIR=/home/user/projects/myapp
CUSTOM_RULES_DIR=/home/user/semgrep-rules
```

Then:
```bash
docker compose up -d
# Client tool call: semgrep_scan(path="/code/src/main.py")
```

### Shell env override (no `.env`)

```bash
CODE_DIR=/path/to/code docker compose up -d
```

### Custom rules

Clients invoke `semgrep_scan_with_custom_rule` with the rule as an inline YAML string, OR reference file paths under `/opt/custom-rules/`. See [semgrep.dev/docs/writing-rules](https://semgrep.dev/docs/writing-rules/overview) for rule syntax.

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

1. Container healthy: `docker ps` shows `healthy`
2. Port open: `curl http://host-ip:7055/healthz`
3. Logs clean: `docker logs semgrep-mcp` — banner appears, no errors
4. Outbound network: container can reach `semgrep.dev` and `raw.githubusercontent.com`

### Common Issues

#### Container Won't Start

- Port conflict: check host port 7055 isn't already bound
- PUID/PGID invalid: must be positive integers
- Bad API_KEY: length 5–256 chars, no whitespace

#### Permission Errors

- Volume owned by wrong UID/GID: `chown -R 1000:1000 ./custom-rules`
- Or set `PUID=$(id -u)` / `PGID=$(id -g)` to match host user

#### Client Cannot Connect

- Firewall blocking 7055/tcp or 7055/udp
- TLS enabled but client using `http://` — switch to `https://`
- API_KEY set but client not sending `Authorization: Bearer ...`
- Wrong endpoint path: SHTTP → `/mcp`, SSE → `/sse` + `/message`, WS → `/message`

#### Slow First Scan

- Semgrep is downloading + caching the rule registry on first scan. Subsequent scans reuse `~/.cache/semgrep`. Mount a persistent volume (see compose example).

#### Pro Tools Disabled

- `SEMGREP_APP_TOKEN` unset → `semgrep_findings`, `semgrep_scan_remote`, `semgrep_scan_supply_chain` auto-disabled
- Token invalid → check logs for `semgrep login failed`; regenerate at [semgrep.dev/orgs/-/settings/tokens](https://semgrep.dev/orgs/-/settings/tokens)
- Set `REQUIRE_PRO=true` to fail-fast instead of silent OSS fallback

### Debug Information

```bash
docker exec semgrep-mcp semgrep --version
docker exec semgrep-mcp semgrep mcp --help
docker logs --tail 200 semgrep-mcp
```

## Additional Resources

### Documentation

- [Semgrep Docs](https://semgrep.dev/docs/)
- [Semgrep MCP Upstream](https://github.com/semgrep/semgrep/tree/develop/cli/src/semgrep/mcp)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Supergateway](https://github.com/supercorp-ai/supergateway)

### Docker Resources

- [Dockerfile Modifier](./DockerfileModifier.sh)
- [Compose Example](./docker-compose.yml)
- [GitHub Repository](https://github.com/mekayelanik/semgrep-mcp-docker)

### Monitoring

Health endpoint returns HTTP 200 with supergateway status. Wire into your monitoring (Prometheus blackbox, Uptime Kuma, etc.) at `http[s]://host:7055/healthz`.

## 😎 Buy Me a Coffee ☕︎

If this image saved you time, [buy me a coffee](https://buymeacoffee.com/mekayelanik).

## Support & License

### Getting Help

- Issues: [github.com/mekayelanik/semgrep-mcp-docker/issues](https://github.com/mekayelanik/semgrep-mcp-docker/issues)
- Discussions: [github.com/mekayelanik/semgrep-mcp-docker/discussions](https://github.com/mekayelanik/semgrep-mcp-docker/discussions)

### Contributing

PRs welcome. Keep changes minimal, match existing code style, preserve universal (non-opinionated) defaults.

### License & Attribution

This Docker packaging is licensed **MIT** — see [LICENSE](./LICENSE).

The software packaged inside the image retains its original licensing:
- **Semgrep CLI** — LGPL-2.1 (see [github.com/semgrep/semgrep/blob/develop/LICENSE](https://github.com/semgrep/semgrep/blob/develop/LICENSE))
- **Semgrep Registry rules** (fetched at runtime, not bundled) — governed by Semgrep's Terms of Service, see [semgrep.dev/legal](https://semgrep.dev/legal/)
- **Semgrep Pro Engine** (requires your own `SEMGREP_APP_TOKEN`, not bundled) — proprietary, see [semgrep.dev/legal](https://semgrep.dev/legal/)
- **supergateway** — MIT (see [github.com/supercorp-ai/supergateway](https://github.com/supercorp-ai/supergateway))
- **HAProxy** — GPL-2.0-or-later (see [haproxy.org](https://www.haproxy.org/))

### Trademark Notice

**Semgrep®** is a registered trademark of Semgrep Inc. This project is an **unofficial community packaging** and is not affiliated with, sponsored by, or endorsed by Semgrep Inc. The Semgrep name and logo are used only nominatively to identify the software packaged inside this image.

For official Semgrep products and support, visit [semgrep.dev](https://semgrep.dev).
