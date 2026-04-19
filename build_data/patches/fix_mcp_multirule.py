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
Patch `semgrep/mcp/semgrep.py::get_semgrep_scan_args(temp_dir, config)` so that
when no explicit `config` is passed by the MCP tool, it reads SEMGREP_RULES
from env, splits on whitespace, and appends N repeated `--config X` flags (one
per value). Explicit arg-config path is unchanged.

Anchor-checked
--------------
The patch asserts that the current get_semgrep_scan_args implementation is
byte-identical to the version this patch was written against. If the anchor
fails, the Dockerfile build aborts — forcing a re-verification on every
semgrep version bump.

Retire when upstream fixes the osemgrep envvar split.
"""
import os
import sys
import textwrap


def locate_target() -> str:
    """Find the semgrep/mcp/server.py file inside site-packages."""
    import semgrep
    base = os.path.dirname(semgrep.__file__)
    path = os.path.join(base, "mcp", "server.py")
    if not os.path.isfile(path):
        sys.exit(f"[patch] target file not found: {path}")
    return path


ANCHOR = textwrap.dedent('''\
    def get_semgrep_scan_args(temp_dir: str, config: str | None = None) -> list[str]:
        """
        Builds command arguments for semgrep scan

        Args:
            temp_dir: Path to temporary directory containing the files
            config: Optional Semgrep configuration (e.g. "auto" or absolute path to rule file)

        Returns:
            List of command arguments
        """

        # Build command arguments and just run semgrep scan
        # if no config is provided to allow for either the default "auto"
        # or whatever the logged in config is
        args = ["scan", "--json", "--experimental"]  # avoid the extra exec
        args.extend(["--x-mcp"])
        if config:
            args.extend(["--config", config])
        args.append(temp_dir)
        return args
''')

REPLACEMENT = textwrap.dedent('''\
    def get_semgrep_scan_args(temp_dir: str, config: str | None = None) -> list[str]:
        """
        Builds command arguments for semgrep scan.

        Patched by mekayelanik/semgrep-mcp-docker to work around osemgrep's
        SEMGREP_RULES envvar not splitting whitespace-separated values.
        See build_data/patches/fix_mcp_multirule.py for details.

        Args:
            temp_dir: Path to temporary directory containing the files
            config: Optional Semgrep configuration (e.g. "auto" or absolute path to rule file)

        Returns:
            List of command arguments
        """
        import os as _os

        args = ["scan", "--json", "--experimental"]  # avoid the extra exec
        args.extend(["--x-mcp"])
        if config:
            args.extend(["--config", config])
        else:
            _rules_env = (_os.environ.get("SEMGREP_RULES") or "").strip()
            if _rules_env:
                # Split on whitespace to compensate for osemgrep not respecting
                # Cmdliner multi-value envvar semantics. Single-value stays as-is.
                _parts = _rules_env.split()
                for _c in _parts:
                    args.extend(["--config", _c])
        args.append(temp_dir)
        return args
''')


def main() -> int:
    target = locate_target()
    with open(target, "r", encoding="utf-8") as fh:
        source = fh.read()

    if REPLACEMENT.strip() in source:
        print(f"[patch] already applied in {target}, skipping")
        return 0

    if ANCHOR.strip() not in source:
        sys.exit(
            f"[patch] ANCHOR NOT FOUND in {target} — semgrep internal API moved.\n"
            f"        This patch must be re-validated before the image build can proceed.\n"
            f"        Fix: update build_data/patches/fix_mcp_multirule.py ANCHOR/REPLACEMENT\n"
            f"        to match the new upstream definition of get_semgrep_scan_args,\n"
            f"        or remove the patch entirely if upstream now splits SEMGREP_RULES\n"
            f"        correctly on the osemgrep path."
        )

    patched = source.replace(ANCHOR.strip(), REPLACEMENT.strip(), 1)
    if patched == source:
        sys.exit("[patch] replace was a no-op — aborting")

    with open(target, "w", encoding="utf-8") as fh:
        fh.write(patched)
    print(f"[patch] multi-rule SEMGREP_RULES envvar split applied to {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
