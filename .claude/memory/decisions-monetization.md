---
name: decisions-monetization
description: 수익화 결정 — MVP는 AdMob 3슬롯(배너/인터/보상). UX 보호 정책은 첫 60초 광고 금지
type: project
---

**MVP 광고 슬롯**: AdMob 3종.

| 슬롯 | 위치 | 빈도 |
|---|---|---|
| 배너 | 지도 화면 하단 (홈인디케이터 위) | 상시 노출, 단 첫 사용 60초 차단 |
| 인터스티셜 | 매장 상세 진입 시 | N=5회마다(쿨다운 90초) |
| 보상형 | 도감(컬렉션) 잠금 해제 | 사용자 자발 시청 |

**Why:**
- AdMob은 Apple 심사 친화적이고 FearIndex에서 검증.
- 첫 60초/첫 화면 차단은 리텐션 보호 목적(사용자 신규 접속 즉시 광고는 강한 이탈 신호).

**ARPU 추정 (po-growth Phase 1, 2026-05-04)**:
- 시장별: US $0.18–0.25 / UK $0.13–0.18 / KR $0.10–0.14 / JP $0.09–0.12 / DE $0.07–0.10 / FR $0.06–0.09 (USD/MAU).
- 글로벌 가중평균 추정 **$0.10–$0.14/MAU** = PRD §4 목표 $0.05의 **2–2.8x 초과** (보수적 임계). 출처: Playwire 2025 iOS eCPM × 일일 노출 가정(배너 10/인터 0.7/보상 0.2).

**유료 전환(임계 도달 시 재검토)**:
- 광고 ARPU < $0.05/MAU OR D7 retention < 12% → 구독 v1.1.0 가속.
- 가격대 후보: A 연 $4.99(보수, 광고 제거+도감 무제한) / B 연 $9.99(공격, A + 친구 그룹 도감).
- 전환 임계 PMF 신호: 1주 ≥ 1.5%, 1개월 ≥ 3%. 연 갱신율 ≥ 50%.
- 결제 SDK: StoreKit 2.

**AdMob 슬롯 ID 발급 완료 (2026-05-04, vault `~/.env-vault/projects/matchamap-ios/admob.json`)**:
- App ID: `ca-app-pub-5283496525222246~9629032489`
- Banner-Map: `ca-app-pub-5283496525222246/6560016017`
- Interstitial-Store: `ca-app-pub-5283496525222246/8764567012`
- Rewarded-Collection: `ca-app-pub-5283496525222246/2979863655` (CollectionSlot ×1)
- 게재 시작까지 최대 1시간 지연 가능. 개발 중에는 Google Test Ad Unit ID 사용 권장.

**How to apply:**
- `ios-auth-monetize`가 슬롯 ID를 vault에서 빌드 타임 주입 (Configs/AdMob.xcconfig 또는 Info.plist build setting).
- `Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier")`로 App ID 로드.
- ATT 다국어 카피는 `qa-localization`이 Phase 4에 검수.
- 광고 정책 가드(첫 60초 차단/인터스티셜 5회 쿨다운/보상형 자발 시청)는 ADR-202 `MonetizeRules` 강제.
