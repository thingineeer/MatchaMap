# Localization Audit — v1.0.0 (Phase 4)

> Owner: `qa-localization`
> Date: 2026-05-05
> Branch: `qa/localization-v1.0.0`

## TL;DR

- **90 keys** extracted across **8 module catalogs**.
- **540 / 540** locale slots filled (100%, 0 missing).
- `verify-localizations.py` exits 0 — merge gate clean.
- **Catalogs ship as source-of-truth only in this PR.** SPM `Package.swift` activation (`resources: [.process("Resources")]` + `defaultLocalization: "ko"`) and view-code migration to `Text("...", bundle: .module)` are deliberately deferred to a follow-up so this PR does not collide with the parallel `qa/scenarios-v1.0.0` and feature worktrees that share the same Package manifests.

## Coverage by module

| Module | Keys | KO | EN | EN-GB | DE | JA | FR |
|---|---:|:-:|:-:|:-:|:-:|:-:|:-:|
| MatchaMap (shell) | 16 | 16 | 16 | 16 | 16 | 16 | 16 |
| DesignSystem | 14 | 14 | 14 | 14 | 14 | 14 | 14 |
| FeatureAuth | 4 | 4 | 4 | 4 | 4 | 4 | 4 |
| FeatureMap | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| FeatureStore | 33 | 33 | 33 | 33 | 33 | 33 | 33 |
| FeatureSocial | 6 | 6 | 6 | 6 | 6 | 6 | 6 |
| FeatureCollection | 13 | 13 | 13 | 13 | 13 | 13 | 13 |
| FeatureMonetize | 3 | 3 | 3 | 3 | 3 | 3 | 3 |
| **TOTAL** | **90** | **90** | **90** | **90** | **90** | **90** | **90** |

## Overflow risk register (DE / EN-GB worst case)

DE has the longest renderings; EN-GB ties on a couple of tokens (e.g. `Opening hours`).

| Screen | Key | DE rendering | Approx chars | Risk | Action |
|---|---|---|---:|---|---|
| Splash | tagline | "Die Matcha-Welt,\nTasse für Tasse gesammelt" | 22 + 24 | Low — fits 2 lines at 18pt body | Verify on iPhone SE 4 (375 pt). |
| Login | welcome headline | "Willkommen\nbei MatchaMap" | 10 + 14 | Low | OK at 28 pt serif. |
| Login | sync explainer | "Melde dich an, um Matcha-Log und\nMerkliste auf allen Geräten zu synchronisieren." | 33 + 49 | Medium — second line 49 chars | If wrapping to 3 lines, force `Text(...).fixedSize(horizontal: false, vertical: true)`. |
| Tab bar | "Wishlist" | DE: "Merkliste" / EN-GB: "Wish list" | 9 | Medium | Tab bar font already supports 9-char labels; revisit if iconLabel font shrinks. |
| Tab bar | "Profile" | DE: "Profil" | 6 | Low | OK. |
| Filter sheet | reset/apply buttons | DE: "Zurücksetzen" / "Anwenden" | 12 / 8 | Medium — 12 char button | Inline button width must flex; current `Button("초기화") {}` will autosize, but row must allow line wrap. |
| Search empty | hint | DE: "z. B. Matcha House, Kyoto, Uji" | 32 | Low | Center text, single line OK. |
| Search empty | placeholder | DE: "Suche nach Café-Name oder Stadt" | 32 | Low | OK. |
| Review write | submit button | DE: "Wird gesendet…" | 14 | Medium | Toolbar label width must accommodate 14 char + spinner. |
| Review error | alert title | DE: "Rezension nicht veröffentlicht" | 31 | Medium | iOS alert title can wrap; verify on iPhone SE width. |
| Auth CTA | Apple button | DE: "Mit Apple fortfahren" | 19 | Low | Apple HIG button supports ≥ 25 char. |
| Collection lock | UNLOCK CTA | DE: "FREISCHALTEN" | 12 | High — uppercase 12-char fixed label on grid card | Card overlay must be ≥ 110 pt wide at 16 pt bold. Designer to confirm. |
| Wishlist counter | "PINS" unit | FR: "ÉPINGLES" | 8 | Medium | Counter "12 ÉPINGLES" = 11 chars — banner header must flex. |
| Splash | EST line | "EST. 2025 · KYOTO" | 17 | Low (locked across all locales). | OK. |

### High-risk items (designer-lead handoff)

1. **Collection grid `UNLOCK` overlay** — `FREISCHALTEN` (DE, 12 chars) is 71% wider than English `UNLOCK` (6). Verify card aspect ratio holds at iPhone SE 4.
2. **Wishlist `PINS` count chip** — French `ÉPINGLES` doubles English label width. Consider switching to icon-only chip or numeric-only above ≥ 10 cm width.

## Open follow-ups (next sprint)

1. **SPM resource activation** — each module's `Package.swift` still has `defaultLocalization: "en"` and no `resources: [.process("Resources")]`. Once the parallel feature worktrees stabilise, a single follow-up commit should:
   - flip every Feature `defaultLocalization` to `"ko"`,
   - add `resources: [.process("Resources")]` to each target,
   - and verify SPM picks up the catalogs via `swift build` per package.
2. **View-code migration** — feature modules currently use bare `Text("...")`. SwiftUI inside an SPM target needs `Text("...", bundle: .module)` to look up the module's String Catalog. App-shell strings (in `MatchaMap/`) already work via the main bundle. Catalogs are pre-staged so this migration is mechanical.
3. **ATT prompt verification** — `att.prompt.title` / `att.prompt.body` keys exist in `FeatureMonetize`; they must also be wired into `Info.plist`'s `NSUserTrackingUsageDescription` per locale (handled by App Shell during `bump_build` lane).
4. **App Store metadata** — `fastlane/metadata/{ko,en-US,en-GB,de-DE,ja,fr-FR}/` is owned by another QA worktree. This audit does not touch it.
5. **Length screenshots** — once activation + migration lands, run `xcrun simctl spawn booted defaults write -g AppleLanguages '("de-DE")'` and capture each screen for `docs/qa/localization-overflow.md`.

## Verification

```bash
python3 docs/qa/scripts/verify-localizations.py
# expected: "OK — all locales translated for every key."  exit 0
```

Output captured 2026-05-05:

```
Scanning 8 catalog(s)…
  • LocalPackages/DesignSystem/Sources/DesignSystem/Resources/Localizable.xcstrings  keys=14  errors=0
  • LocalPackages/Feature/FeatureAuth/Sources/FeatureAuth/Resources/Localizable.xcstrings  keys=4  errors=0
  • LocalPackages/Feature/FeatureCollection/Sources/FeatureCollection/Resources/Localizable.xcstrings  keys=13  errors=0
  • LocalPackages/Feature/FeatureMap/Sources/FeatureMap/Resources/Localizable.xcstrings  keys=1  errors=0
  • LocalPackages/Feature/FeatureMonetize/Sources/FeatureMonetize/Resources/Localizable.xcstrings  keys=3  errors=0
  • LocalPackages/Feature/FeatureSocial/Sources/FeatureSocial/Resources/Localizable.xcstrings  keys=6  errors=0
  • LocalPackages/Feature/FeatureStore/Sources/FeatureStore/Resources/Localizable.xcstrings  keys=33  errors=0
  • MatchaMap/Resources/Localizable.xcstrings  keys=16  errors=0
Total keys across all catalogs: 90
Total errors: 0
OK — all locales translated for every key.
```
