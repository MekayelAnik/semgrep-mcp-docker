#!/usr/bin/env python3
"""
Build-time patch: fix multi-rule SEMGREP_RULES support in the `semgrep_scan`
MCP tool.

Problem
-------
`semgrep_scan` invokes `semgrep scan --experimental ...` which routes through
osemgrep (OCaml). osemgrep's Cmdliner `-f/--config` envvar handling does NOT
split SEMGREP_RULES on whitespace (or any separator) — it treats the whole env
value as a single opaque config identifier. A multi-rule env like
`SEMGREP_RULES="p/default p/python"` gets URL-encoded whole and hits the
registry as a nonexistent config ID → HTTP 404 → exit 2.

pysemgrep's Click splits correctly, so the plain `semgrep scan` path (no
`--experimental`) works fine — only the MCP-tool subprocess is affected.

Fix
---
Patch `semgrep/mcp/server.py::get_semgrep_scan_args(temp_dir, config)` so that
when no explicit `config` is passed by the MCP tool, it reads SEMGREP_RULES
from env, splits on whitespace, and appends N repeated `--config X` flags (one
per value). Explicit arg-config path is unchanged. After injecting from env,
`config` is rebound to a non-None sentinel so semgrep 1.162+'s
"auto + metrics off" check downstream does not fire.

Soft-failure semantics
----------------------
This patch never aborts the Docker build. It exits 0 in every situation
except a true I/O error. The taxonomy:

  * Already patched          → no-op exit 0 (idempotent across rebuilds).
  * Upstream module missing  → no-op exit 0 with notice (MCP path removed).
  * Upstream auto-retired    → no-op exit 0 with notice (function now reads
                               SEMGREP_RULES itself; patch is obsolete).
  * Anchor drifted, bug live → exit 0 with LOUD WARNING to stderr (build
                               proceeds UNPATCHED; multi-rule will be broken
                               until a human re-validates the anchor).
  * Anchor matches once      → apply patch and exit 0.
  * Anchor matches >1 times  → exit 0 with LOUD WARNING (ambiguous, skipped).

The intent: a future semgrep release that fixes the underlying osemgrep
envvar issue, or restructures the MCP module, MUST NOT break this image's CI
matrix. The retirement probe in `.github/workflows/check-patch-retirement.yml`
is the canonical signal that the patch can be deleted from this repo.
"""
import os
import re
import sys


def locate_target() -> str | None:
    """Find the semgrep/mcp/server.py file inside site-packages, or None."""
    try:
        import semgrep
    except ImportError:
        return None
    base = os.path.dirname(semgrep.__file__)
    path = os.path.join(base, "mcp", "server.py")
    return path if os.path.isfile(path) else None


# Small, stable anchor inside get_semgrep_scan_args. Indented 4 spaces because
# it lives inside a top-level function body. Matched verbatim — tolerant of
# unrelated lines added before/after this block in the same function.
ANCHOR = (
    '    args.extend(["--x-mcp"])\n'
    '    if config:\n'
    '        args.extend(["--config", config])\n'
)

REPLACEMENT = (
    '    args.extend(["--x-mcp"])\n'
    '    if config:\n'
    '        args.extend(["--config", config])\n'
    '    else:\n'
    '        # Patched by mekayelanik/semgrep-mcp-docker:\n'
    '        # osemgrep does not split SEMGREP_RULES on whitespace, so emit\n'
    '        # one --config flag per whitespace-separated value. After\n'
    '        # injecting we rebind `config` to a non-None sentinel so the\n'
    '        # 1.162+ "auto + metrics off" check downstream does not fire\n'
    '        # (we have provided explicit --config flags, not auto).\n'
    '        import os as _os\n'
    '        _rules_env = (_os.environ.get("SEMGREP_RULES") or "").strip()\n'
    '        if _rules_env:\n'
    '            for _c in _rules_env.split():\n'
    '                args.extend(["--config", _c])\n'
    '            config = "<patched-from-env>"\n'
)

# Unique substring of REPLACEMENT — used to detect already-patched files so
# the patch is idempotent across rebuilds and layer caches.
PATCHED_MARKER = "mekayelanik/semgrep-mcp-docker"

# Regex carving out the body of get_semgrep_scan_args from a Python source
# file. Used to detect upstream auto-retirement (function now reads
# SEMGREP_RULES itself).
_FUNC_RE = re.compile(
    r"^def\s+get_semgrep_scan_args\s*\([^)]*\)[^:]*:\s*$.*?(?=^def\s|^class\s|\Z)",
    re.MULTILINE | re.DOTALL,
)


def upstream_auto_retired(source: str) -> bool:
    """Heuristic: returns True if the upstream get_semgrep_scan_args body
    references the SEMGREP_RULES env var directly. If so, upstream has
    presumably implemented option 1 from issue #11649 and this patch is
    obsolete — no-op cleanly.
    """
    m = _FUNC_RE.search(source)
    if not m:
        return False
    return "SEMGREP_RULES" in m.group(0)


def warn(msg: str) -> None:
    print(f"[patch] {msg}", file=sys.stderr)


def info(msg: str) -> None:
    print(f"[patch] {msg}")


def main() -> int:
    target = locate_target()
    if target is None:
        info("semgrep.mcp.server not present — upstream may have removed or "
             "restructured the MCP module. Patch is a no-op.")
        return 0

    try:
        with open(target, "r", encoding="utf-8") as fh:
            source = fh.read()
    except OSError as e:
        # Genuine I/O failure — fail hard so build doesn't ship a corrupt image.
        sys.exit(f"[patch] could not read {target}: {e}")

    if PATCHED_MARKER in source:
        info(f"already applied in {target}, skipping")
        return 0

    if upstream_auto_retired(source):
        info(f"upstream get_semgrep_scan_args in {target} now references "
             "SEMGREP_RULES directly. Patch is OBSOLETE — no-op. "
             "Delete build_data/patches/fix_mcp_multirule.py and the patch "
             "step in DockerfileModifier.sh.")
        return 0

    occurrences = source.count(ANCHOR)
    if occurrences == 0:
        warn("=" * 72)
        warn(f"WARNING: ANCHOR NOT FOUND in {target}")
        warn("Upstream MCP scan source drifted, but the SEMGREP_RULES env-split")
        warn("issue does not yet appear to be fixed (no SEMGREP_RULES reference")
        warn("in get_semgrep_scan_args).")
        warn("")
        warn("Build proceeds UNPATCHED. Multi-rule SEMGREP_RULES will fail at")
        warn("runtime until a human re-validates ANCHOR/REPLACEMENT against the")
        warn("new upstream definition of get_semgrep_scan_args, or removes this")
        warn("patch entirely if upstream now splits SEMGREP_RULES correctly.")
        warn("=" * 72)
        return 0

    if occurrences > 1:
        warn(f"WARNING: ANCHOR matched {occurrences} times in {target} — "
             "ambiguous. Skipping patch. Tighten ANCHOR with more surrounding "
             "context if this is a real upstream change.")
        return 0

    patched = source.replace(ANCHOR, REPLACEMENT, 1)
    if patched == source:
        warn(f"WARNING: replace was a no-op in {target} — skipping.")
        return 0

    try:
        with open(target, "w", encoding="utf-8") as fh:
            fh.write(patched)
    except OSError as e:
        sys.exit(f"[patch] could not write {target}: {e}")
    info(f"multi-rule SEMGREP_RULES envvar split applied to {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
