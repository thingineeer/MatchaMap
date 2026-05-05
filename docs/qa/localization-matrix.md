# Localization Matrix — v1.0.0

> Owner: `qa-localization`
> Generated: 2026-05-05
> Verifier: `docs/qa/scripts/verify-localizations.py`

## Target locales (6)

| Code | Locale | Notes |
|---|---|---|
| `ko` | Korean | Source language. App branded as "말차맵". |
| `en` | English (US) | App Store metadata in `fastlane/metadata/en-US/`. |
| `en-GB` | English (UK) | Region-specific spelling: `wishlist` → `wish list`, `personalized` → `personalised`. |
| `de` | German | Longest-copy benchmark. Layout regression baseline. |
| `ja` | Japanese | App branded as "抹茶マップ" (Matcha-map katakana). |
| `fr` | French | Apostrophes use straight quotes for now. |

> Apple `String Catalog` convention — language codes are stored without region unless region carries semantic difference. `en-US` collapses to `en`; `en-GB` is kept distinct because UK spellings diverge.

## Module catalogs

| Module | Path | Keys |
|---|---|---:|
| App shell | `MatchaMap/Resources/Localizable.xcstrings` | 16 |
| DesignSystem | `LocalPackages/DesignSystem/Sources/DesignSystem/Resources/Localizable.xcstrings` | 14 |
| FeatureAuth | `LocalPackages/Feature/FeatureAuth/Sources/FeatureAuth/Resources/Localizable.xcstrings` | 4 |
| FeatureMap | `LocalPackages/Feature/FeatureMap/Sources/FeatureMap/Resources/Localizable.xcstrings` | 1 |
| FeatureStore | `LocalPackages/Feature/FeatureStore/Sources/FeatureStore/Resources/Localizable.xcstrings` | 33 |
| FeatureSocial | `LocalPackages/Feature/FeatureSocial/Sources/FeatureSocial/Resources/Localizable.xcstrings` | 6 |
| FeatureCollection | `LocalPackages/Feature/FeatureCollection/Sources/FeatureCollection/Resources/Localizable.xcstrings` | 13 |
| FeatureMonetize | `LocalPackages/Feature/FeatureMonetize/Sources/FeatureMonetize/Resources/Localizable.xcstrings` | 3 |
| **Total** | | **90** |

Per-locale fill rate: **100% (90/90 × 6 = 540 / 540 strings translated)**.

## Branding tokens

| Token | KO | EN / EN-GB | DE | JA | FR |
|---|---|---|---|---|---|
| App name (ko/ja/zh markets) | 말차맵 | MatchaMap | MatchaMap | 抹茶マップ | MatchaMap |
| Splash mark | MATCHAMAP | MATCHAMAP | MATCHAMAP | MATCHAMAP | MATCHAMAP |
| Splash tagline | 세상의 말차를\n한 잔씩 모아두는 곳 | Collecting the world's matcha,\none cup at a time | Die Matcha-Welt,\nTasse für Tasse gesammelt | 世界の抹茶を\n一杯ずつ集める場所 | Le matcha du monde,\nune tasse à la fois |

## Tab bar labels (length comparison)

| Label | KO | EN | EN-GB | DE | JA | FR |
|---|---|---|---|---|---|---|
| Tab Map | 지도 (2 chars) | Map (3) | Map | Karte (5) | マップ (3) | Carte (5) |
| Tab Feed | 피드 (2) | Feed (4) | Feed | Feed | フィード (4) | Fil (3) |
| Tab Wishlist | 위시리스트 (5) | Wishlist (8) | Wish list (9) | Merkliste (9) | ウィッシュリスト (8) | Favoris (7) |
| Tab Profile | 내정보 (3) | Profile (7) | Profile | Profil (6) | マイページ (5) | Profil (6) |

`Wish list` (en-GB) and `Merkliste` (de) tie for the longest tab — 9 characters. Tab bar must accommodate ≥ 9-char Latin labels at body font.

## SDK locale code mapping for Apple ASA / App Store

| App Store metadata locale | xcstrings code |
|---|---|
| `ko` | `ko` |
| `en-US` | `en` |
| `en-GB` | `en-GB` |
| `de-DE` | `de` |
| `ja` | `ja` |
| `fr-FR` | `fr` |
