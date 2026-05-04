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

**유료 전환(미정·임계 도달 시 재검토)**:
- 월간 활성 1만 + 광고 ARPU < $0.05/MAU → 구독(연 4.99 USD, 광고 제거 + 도감 무제한).
- 결제 SDK: StoreKit 2.

**How to apply:**
- `ios-monetize` 에이전트(역할 통합: `ios-auth-monetize`)가 슬롯 설정 + ATT 프롬프트 + 정책 가드를 책임.
- ATT 다국어 카피는 `qa-localization`이 검수.
