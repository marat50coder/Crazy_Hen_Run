#!/usr/bin/env python3
"""Rewrite Dart import paths that reference the renamed top-level folders.

We just moved ``lib/core → lib/foundation``, ``lib/data → lib/persistence`` and
``lib/state → lib/domain``. This walks every Dart source and rewrites the
segment inside any ``import`` / ``export`` / ``part`` string that still points
at the old names. Relative depth (`../../..`) is untouched — only the segment
name changes.
"""
from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent

FOLDER_MAP: dict[str, str] = {
    "core": "foundation",
    "data": "persistence",
    "state": "domain",
}

# We rewrite occurrences of `/<old>/` and `<old>/...'` at the *start* of a
# quoted path (e.g. `'core/utils/day_key.dart'`) within import/export/part
# directives. Matching on quotes keeps us clear of unrelated substrings.
_IMPORT_RE = re.compile(
    r"""(?P<kw>\b(?:import|export|part)\s+)(?P<q>['"])(?P<path>[^'"]+)(?P=q)"""
)


def rewrite_path(path: str) -> str:
    parts = path.split("/")
    changed = False
    for i, seg in enumerate(parts):
        if seg in FOLDER_MAP:
            parts[i] = FOLDER_MAP[seg]
            changed = True
    return "/".join(parts) if changed else path


def transform(text: str) -> str:
    def _sub(match: re.Match[str]) -> str:
        original = match.group("path")
        rewritten = rewrite_path(original)
        if rewritten == original:
            return match.group(0)
        return f"{match.group('kw')}{match.group('q')}{rewritten}{match.group('q')}"

    return _IMPORT_RE.sub(_sub, text)


def main() -> None:
    targets: list[pathlib.Path] = []
    for folder in ("lib", "test"):
        targets.extend((ROOT / folder).rglob("*.dart"))

    changed: list[pathlib.Path] = []
    for path in targets:
        original = path.read_text(encoding="utf-8")
        updated = transform(original)
        if updated != original:
            path.write_text(updated, encoding="utf-8")
            changed.append(path)

    for p in changed:
        print(f"rewrote {p.relative_to(ROOT)}")
    print(f"\nTotal files rewritten: {len(changed)}")


if __name__ == "__main__":
    main()
