# QA 허브 (docs/qa)

> 본 디렉토리는 `qa-lead` 에이전트의 단일 진실 공급원. iOS 개발자는 자기 모듈 작업 *전*에 해당 시나리오 `.md`를 읽는다.

## 시나리오 인덱스

| 모듈 | 파일 | 담당 iOS 에이전트 |
|---|---|---|
| 온보딩 | [scenarios/onboarding.md](scenarios/onboarding.md) | `ios-auth-monetize` |
| 지도 | [scenarios/map.md](scenarios/map.md) | `ios-map` |
| 매장 상세 / 검색 / 리뷰 | [scenarios/store.md](scenarios/store.md) | `ios-store` |
| 도감 / 위시리스트 / 피드 / 랭킹 | [scenarios/social-collection.md](scenarios/social-collection.md) | `ios-social-collection` |
| 광고 / 구독 | [scenarios/monetize.md](scenarios/monetize.md) | `ios-auth-monetize` |
| 다국어 | [scenarios/localization.md](scenarios/localization.md) | `qa-localization` |

## 회귀 시트

- [regression/v1.0.0.md](regression/v1.0.0.md) — v1.0.0 출시 회귀 매트릭스 (시뮬레이터 × OS × 언어)

## 자동화

- [appium/](appium/) — Appium Python 스크립트
- [scripts/verify-localizations.py](scripts/verify-localizations.py) — String Catalog 누락 키 검출

## App Store Review 체크리스트

- [checklists/app-store-review.md](checklists/app-store-review.md)

## 게이트 정책

- 시나리오 없는 기능 = 머지 차단.
- FAIL 케이스 = 머지 차단 (BLOCKER 라벨 시).
- 다국어/접근성 회귀 = 출시 차단.
