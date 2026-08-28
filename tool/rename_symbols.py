#!/usr/bin/env python3
"""One-shot rename pass across Dart sources.

Rewrites class-level identifiers everywhere in `lib/` and `test/`. Each key is
matched only when surrounded by non-identifier characters so we never touch a
substring inside another symbol (e.g. `BrandingWidget` is left alone even
though `Brand` maps to `Meadow`).
"""
from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent

MAPPING: dict[str, str] = {
    # Top-level application shell.
    "CrazyHenRunApp": "HenyardApp",
    # Foundation.
    "AppConfig": "AppMeta",
    "AppAssets": "Artwork",
    "AppTheme": "HenyardTheme",
    "AppSpacing": "Insets",
    "AppRadii": "Corners",
    "AppColors": "Palette",
    "AppColorsX": "PaletteX",
    "HabitPalette": "HabitSwatches",
    "Brand": "Meadow",
    # Persistence.
    "LocalStore": "SnapshotStore",
    "OfflinePages": "EmbeddedDocs",
    # Services.
    "PedometerService": "StepFeed",
    # State containers.
    "AppState": "HenState",
    "RunState": "RunTracker",
    # Screens.
    "WebPageScreen": "WebDocScreen",
    "LoadingScreen": "BootScreen",
    "RootShell": "AppShell",
    "OnboardingScreen": "WelcomeScreen",
}

# Build a single regex OR'd together, ordered so longer keys win first
# (important: `AppColorsX` before `AppColors`).
KEYS = sorted(MAPPING.keys(), key=len, reverse=True)
PATTERN = re.compile(r"(?<![A-Za-z0-9_])(" + "|".join(re.escape(k) for k in KEYS) + r")(?![A-Za-z0-9_])")


def transform(text: str) -> str:
    return PATTERN.sub(lambda m: MAPPING[m.group(0)], text)


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
