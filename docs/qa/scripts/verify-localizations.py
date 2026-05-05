#!/usr/bin/env python3
# verify-localizations.py
# 모든 *.xcstrings 파일을 스캔해 6개 타깃 언어가 모두 "translated" 상태인지 검사.
# 실패 시 exit 1 (CI/pre-commit 머지 게이트용).
#
# Owner: qa-localization · MatchaMap

import json
import os
import sys
from pathlib import Path

REQUIRED_LOCALES = {"ko", "en", "en-GB", "de", "ja", "fr"}
ROOT = Path(__file__).resolve().parents[3]


def find_catalogs(root: Path):
    # 빌드 산출물(.build/, DerivedData/) 제외 — 원본 source-of-truth만 검사.
    excluded_parts = {".build", "DerivedData", ".swiftpm", "build"}
    catalogs = []
    for p in root.rglob("Localizable.xcstrings"):
        if any(part in excluded_parts for part in p.parts):
            continue
        catalogs.append(p)
    return sorted(catalogs)


def check_catalog(path: Path) -> list[str]:
    errors: list[str] = []
    rel = path.relative_to(ROOT)
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return [f"{rel}: invalid JSON — {exc}"]

    strings = data.get("strings", {})
    if not strings:
        errors.append(f"{rel}: empty catalog")
        return errors

    for key, entry in strings.items():
        loc = entry.get("localizations") or {}
        present = set(loc.keys())
        missing = REQUIRED_LOCALES - present
        if missing:
            errors.append(f"{rel} :: '{key}' — missing locales: {sorted(missing)}")
            continue
        for code in REQUIRED_LOCALES:
            unit = loc[code].get("stringUnit") or {}
            state = unit.get("state")
            value = unit.get("value")
            if state != "translated":
                errors.append(f"{rel} :: '{key}' [{code}] state={state!r} (expected 'translated')")
            if not value:
                errors.append(f"{rel} :: '{key}' [{code}] empty value")
    return errors


def main() -> int:
    catalogs = find_catalogs(ROOT)
    if not catalogs:
        print("ERROR: no Localizable.xcstrings found")
        return 1

    print(f"Scanning {len(catalogs)} catalog(s)…")
    all_errors: list[str] = []
    summary: list[tuple[str, int]] = []

    for cat in catalogs:
        errs = check_catalog(cat)
        try:
            data = json.loads(cat.read_text(encoding="utf-8"))
            n_keys = len(data.get("strings") or {})
        except Exception:
            n_keys = 0
        rel = cat.relative_to(ROOT)
        summary.append((str(rel), n_keys))
        print(f"  • {rel}  keys={n_keys}  errors={len(errs)}")
        all_errors.extend(errs)

    print()
    print(f"Total keys across all catalogs: {sum(n for _, n in summary)}")
    print(f"Total errors: {len(all_errors)}")

    if all_errors:
        print("\nFIRST 30 ERRORS:")
        for e in all_errors[:30]:
            print(f"  - {e}")
        return 1

    print("OK — all locales translated for every key.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
