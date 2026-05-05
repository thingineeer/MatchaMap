# QA 허브 (docs/qa)

> 본 디렉토리는 `qa-lead` 에이전트의 단일 진실 공급원. iOS 개발자는 자기 모듈 작업 *전*에 해당 시나리오 `.md`를 읽는다.

## 시나리오 인덱스

### Phase 4 신규 (사용자 플로우 단위)

| 시나리오 | 파일 | 담당 iOS | 위험도 |
|---|---|---|---|
| 온보딩 | [scenarios/onboarding.md](scenarios/onboarding.md) | `ios-auth-monetize` | P0 |
| 지도 탐색 | [scenarios/map-discovery.md](scenarios/map-discovery.md) | `ios-map` | P0 |
| 매장 상세 + 리뷰 | [scenarios/store-detail-review.md](scenarios/store-detail-review.md) | `ios-store` | P0 |
| 검색 + 필터 | [scenarios/search-filter.md](scenarios/search-filter.md) | `ios-store` | P1 |
| 위시리스트 + 미니 세계지도 | [scenarios/wishlist-mini-world.md](scenarios/wishlist-mini-world.md) | `ios-social-collection` | P1 |
| 도감 + 메모리 | [scenarios/collection-grid-memory.md](scenarios/collection-grid-memory.md) | `ios-social-collection` + `ios-auth-monetize` | P0 (광고) / P1 (도감) |
| 피드 + 친구 | [scenarios/feed-friend.md](scenarios/feed-friend.md) | `ios-social-collection` | P1 |

## 회귀 시트

- [regression/v1.0.0.md](regression/v1.0.0.md) — v1.0.0 회귀 매트릭스 (시나리오 7 × 디바이스 3 × OS 1 × 언어 6 × 모드 2 = 252 셀)

## 자동화

- [appium/](appium/) — Appium Python 스크립트
  - [appium/golden-onboarding.py](appium/golden-onboarding.py) — 골든패스 (Splash → Login → MainTab)
  - [appium/README.md](appium/README.md) — 환경 셋업 + 시나리오 매핑

## App Store Review 체크리스트

- [checklists/app-store-review.md](checklists/app-store-review.md) — Privacy Manifest, ATT 6언어, 1.1.6 매장 정확성, Apple ID 비식별화

## Phase 보고서

- [phase4-status-v1.0.0.md](phase4-status-v1.0.0.md) — Phase 4 사인오프 (Phase 5 진입 게이트)

## 게이트 정책

- 시나리오 없는 기능 = 머지 차단.
- FAIL 케이스 = 머지 차단 (BLOCKER 라벨 시).
- 다국어/접근성 회귀 = 출시 차단.
- Phase 3 PASS는 mock 데이터 기준 — 실 백엔드 연동 후 Phase 5에서 재실행 강제.
