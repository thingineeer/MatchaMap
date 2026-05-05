# Phase 4 QA 사인오프 보고서 — v1.0.0

> 작성: 2026-05-05 · qa-lead · 브랜치 `qa/scenarios-v1.0.0`

## 요약

Phase 3 통합 빌드(MainTabView 4탭 + Splash + Login 라우팅 + Feature* mock 구현 완료) 기준으로
QA 시나리오 6개 신규 작성, 회귀 시트 v1.0.0 보강, Appium 골든패스 1개 작성 완료.

## 산출물

### 시나리오 (총 7 — 기존 1 + 신규 6)

| # | 파일 | 위험도 | Phase 3 결과 |
|---|---|---|---|
| 1 | scenarios/onboarding.md (기존) | P0 | PASS (mock) |
| 2 | scenarios/map-discovery.md | P0 | PASS (mock) |
| 3 | scenarios/store-detail-review.md | P0 | PASS (mock) |
| 4 | scenarios/search-filter.md | P1 | PASS (mock) |
| 5 | scenarios/wishlist-mini-world.md | P1 | PASS (mock) |
| 6 | scenarios/collection-grid-memory.md | P0/P1 | PASS (mock) |
| 7 | scenarios/feed-friend.md | P1 | PASS (mock) |

### 회귀 매트릭스

| 차원 | 값 |
|---|---|
| 시나리오 | 7 |
| 디바이스 | 3 (iPhone 17 Pro / iPhone SE3 / iPad Pro 13") |
| OS | 1 (iOS 26.2) |
| 언어 | 6 (ko, en-US, en-GB, de-DE, ja, fr-FR) |
| 모드 | 2 (Light / Dark) |
| **총 셀** | **252** |

> Phase 3은 핵심 셀(iPhone 17 Pro × ko/en-US × Light/Dark = 28셀) 우선 검증 → 모두 PASS (mock 기준).
> 풀매트릭스 252셀은 Phase 5 실 백엔드 연동 후 자동화 ≥ 30% 비율로 실행.

### 자동화

| 항목 | 상태 |
|---|---|
| Appium 골든패스 (`golden-onboarding.py`) | 작성 완료 (실 실행은 Phase 5) |
| Appium 환경 셋업 README | 작성 완료 |
| Accessibility ID 규약 | 명문화 (12 ID) |

### App Store Review 체크리스트

- ATT 6언어 카피 명문화
- 광고 정책 (첫 화면 / 60초 / 자발적 보상) 항목화
- Apple Sign In 비식별화 정책 추가
- Privacy Manifest 키 목록 작성 (Phase 5에서 실파일 생성)
- 1.1.6 매장 데이터 정확성 게이트 추가 (신고 CTA + 48h SLA)

## 발견 결함

| ID | 시나리오 | 심각도 | 상태 | 비고 |
|---|---|---|---|---|
| — | — | — | — | **결함 0** (Phase 3 mock 데이터 기준) |

> Phase 5에서 실 Firebase/AdMob/GMaps 연동 후 결함 발견 가능성 있음. 발견 시 본 시트에 추가.

## Phase 5 진입 게이트

| 게이트 | 결과 |
|---|---|
| 시나리오 7개 작성 | **PASS** |
| 회귀 시트 매트릭스 정의 | **PASS** |
| 자동화 골든패스 1개 작성 | **PASS** |
| 핵심 셀(28) Phase 3 mock 검증 | **PASS** |
| App Store Review 체크리스트 갱신 | **PASS** |
| **종합 판정** | **PASS — Phase 5 진입 승인** |

## Phase 5 작업 목록 (qa-lead)

1. 실 백엔드 연동 후 풀매트릭스 252셀 회귀 (자동화 비율 ≥ 30%).
2. Appium 시나리오 6개 추가 작성 (map / review / search / wishlist / collection / feed).
3. Privacy Manifest 실파일 (`PrivacyInfo.xcprivacy`) 작성 — server-auth 협업.
4. TestFlight 외부 베타 1주 운영.
5. 광고 정책 실측 검증 (AdMob test ID로 첫 60초 차단 확인).

## 협업 통신 로그

| 대상 | 내용 |
|---|---|
| `po-lead` | Phase 4 사인오프 PASS — Phase 5 진입 승인 요청 |
| `ios-lead` | Accessibility ID 규약 (12개) 신규 — 새 화면 추가 시 등록 강제 |
| `qa-functional` | 시나리오 7개 분배 — 핵심 셀 28 검증 완료 |
| `qa-localization` | 6개 언어 String Catalog 키 누락 검증 위임 |
| `designer-lead` | 컬러 대비 WCAG AA 토큰 검증 위임 (다크 모드 핀 vs 배경) |
