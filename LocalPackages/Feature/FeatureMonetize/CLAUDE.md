# LocalPackages/Feature/FeatureMonetize

> AdMob 슬롯(배너/인터스티셜/보상형) + ATT + 첫 60초 차단 가드.
> **소유: `ios-auth-monetize`**.

## 책임

- 배너 광고 (지도 화면 하단).
- 인터스티셜 (매장 상세 진입 시 N=5회마다, 쿨다운 90초).
- 보상형 (도감 잠금 해제).
- ATT(App Tracking Transparency) 프롬프트 흐름.
- **첫 60초 차단 가드** (UX 보호 — `decisions-monetization.md`).

## 의존

- 내부: `Domain`, `DesignSystem`.
- 외부 (Phase 3): `GoogleMobileAds`, `StoreKit`(v1.1.0 구독 대비).

## 금지

- `import Data`. 다른 `Feature/*` 모듈 import.
- 첫 화면(스플래시/로그인) 광고 노출. 첫 사용 60초 동안 광고 노출.

## 정책 SSOT

- `docs/product/admob-slots.md` — 슬롯 배치/빈도/쿨다운.
- `decisions-monetization.md` — UX 보호 정책.
