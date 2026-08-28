#!/usr/bin/env python3
"""Update import strings after individual Dart file renames.

Only rewrites the *filename* segment inside quoted import/export/part paths,
so it never touches identifiers or unrelated string literals.
"""
from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent

FILE_MAP: dict[str, str] = {
    "app_config.dart": "app_meta.dart",
    "app_assets.dart": "artwork.dart",
    "offline_pages.dart": "embedded_docs.dart",
    "app_theme.dart": "henyard_theme.dart",
    "app_palette.dart": "palette.dart",
    "pedometer_service.dart": "step_feed.dart",
    "app_state.dart": "hen_state.dart",
    "run_state.dart": "run_tracker.dart",
    "local_store.dart": "snapshot_store.dart",
    "avatar_store.dart": "avatar_cache.dart",
    "coach.dart": "coach_lines.dart",
}

_IMPORT_RE = re.compile(
    r"""(?P<kw>\b(?:import|export|part)\s+)(?P<q>['"])(?P<path>[^'"]+)(?P=q)"""
)


def rewrite_path(path: str) -> str:
    tail = path.rsplit("/", 1)
    filename = tail[-1]
    if filename in FILE_MAP:
        tail[-1] = FILE_MAP[filename]
        return "/".join(tail)
    return path


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
