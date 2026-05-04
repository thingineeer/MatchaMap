# ADR-PROD-002 — Phase 1 게이트 사인오프

- **일자**: 2026-05-04
- **상태**: Accepted (Phase 1 통과)
- **결정자**: `po-lead`
- **사인오프**: `po-lead`
- **연관**: PRD, ADR-PROD-001, ADR-PROD-003, ADR-301, [docs/](../../../docs)

## 컨텍스트

말차맵 v1.0.0 Phase 1(제품 정의 + 디자인 + 백엔드 결정)의 5명(team-lead/po-lead/po-growth/designer-lead/designer-icon/server-lead) 산출물을 검토 후 Phase 2(iOS 구현 시작) 진행 가능 여부를 결정한다.

## 산출물 인벤토리 (PO 사인오프 상태)

| 영역 | 산출물 | 작성자 | 상태 |
|---|---|---|---|
| 제품 | [PRD.md](../PRD.md) | po-lead | ✅ |
| 제품 | [ADR-PROD-001-hypothesis-framework.md](ADR-PROD-001-hypothesis-framework.md) | po-lead | ✅ |
| 제품 | [ADR-PROD-003-beachhead-decision.md](ADR-PROD-003-beachhead-decision.md) (KR vs US 동률 해소) | po-lead | ✅ |
| 제품 | [ADR-PROD-201-beachhead-kr-vs-jp.md](ADR-PROD-201-beachhead-kr-vs-jp.md) (KR vs JP 4축 분석) | po-growth | ✅ |
| 제품 | [backlog.md](backlog.md) (가설 큐) | po-lead | ✅ |
| 시장 | market-research-{kr,jp,us,uk,de,fr}.md | po-growth | ✅ |
| 제품 | [icp.md](../icp.md) | po-growth | ✅ |
| 수익화 | [monetization.md](../monetization.md) + [admob-slots.md](../admob-slots.md) | po-growth | ✅ |
| GTM | [launch-plan.md](../launch-plan.md) + [growth-loops.md](../growth-loops.md) | po-growth | ✅ |
| 디자인 | [design-system.md](../../design/design-system.md) (17 토큰 + 의미 토큰) | designer-lead | ✅ |
| 디자인 | [components.md](../../design/components.md) (6분류 카탈로그) | designer-lead | ✅ |
| 디자인 | [handoff-mapping.md](../../design/handoff-mapping.md) (13 화면) | designer-lead | ✅ |
| 디자인 | [app-icon-decision.md](../../design/app-icon-decision.md) (B 채택) | designer-icon | ✅ |
| 디자인 | [icons.md](../../design/icons.md) (UI 16+탭바 4+핀 3) | designer-icon | ✅ |
| 인프라 | [ADR-301 v2 backend-choice.md](../../architecture/ADR-301-backend-choice.md) | server-lead | ✅ |
| 인프라 | [cost-projection.md](../../server/cost-projection.md) | server-lead | ✅ |
| 인프라 | [security-rules.md](../../server/security-rules.md) | server-lead | ✅ |
| 인프라 | [firebase-setup-checklist.md](../../server/firebase-setup-checklist.md) | server-lead | ✅ |
| 인프라 | [observability.md](../../server/observability.md) (이벤트 스키마 + travel_mode 정책) | server-lead | ✅ |

총 19 산출물. 전부 PO 검토 + 수용 사인오프.

## 미완 산출물 (Phase 2 이연)

다음 산출물은 Phase 1 게이트의 *블로커가 아닌 권장*으로 분류. Phase 2 이내 완료 조건으로 이연.

| 산출물 | 책임 | 상태 |
|---|---|---|
| `docs/design/screens.md` | designer-lead | ✅ Phase 1 후속에서 완료(30 화면 + 4 상태 + 광고 UX 가드) |
| `docs/design/localization-policy.md` | designer-lead | ✅ Phase 1 후속에서 완료(6언어 + de/fr 약어 사전 + ATT/UMP 다국어 매핑) |
| `docs/design/accessibility.md` | designer-lead | ✅ Phase 1 후속에서 완료(VoiceOver/Dynamic Type/WCAG AA + 결함 1건 Phase 2 폴리시 이연) |
| `docs/design/store-screenshots-spec.md` | designer-icon | ✅ Phase 1 후속에서 완료(컵+잎 슬롯 정책 + vein 시그니처 동결) |
| ADR-302 (Firestore 스키마) | server-data | Phase 2 task #12로 진행 중. |
| ADR-303 (App Check + 보안 규칙) | server-auth | Phase 2-3 task #14로 진행 중. Auth 비용 검증 4건 의무 포함. |

## 결정

**Phase 1 게이트 통과(PASS).** Phase 2(iOS 모듈 경계 + DI + Auth + Map MVP) 시작 가능.

## 통과 조건 검증

### 조건 1 — 제품 정의 명확
- PRD §1~§11 모두 채워져 있고, 측정 지표(§4)는 ADR-PROD-001 공식 수식 인용.
- 가설 H1~H6 임계값 + 결정 임계 명시. ✅

### 조건 2 — 시장 우선순위 결정
- ADR-PROD-003으로 KR vs US 동률 해소(옵션 C — APAC 비치헤드 그룹). ✅
- 6개 시장 D-30~D+90 일정 launch-plan.md에 명시. ✅

### 조건 3 — 디자인 토큰 + 컴포넌트 단일 진실 원천
- MM2 17 컬러 토큰 + 의미 토큰 레이어 + 9 타이포 + 8 스페이싱 + 9 라운드 + 5 섀도 + 7 모션. ✅
- v2.html 정전 인용 명시. 색상 리터럴 사용 금지 정책 합의. ✅

### 조건 4 — 백엔드 결정 정량 근거
- ADR-301 v2: 5축 가중 매트릭스(465 vs 335pt) + 정량 트리거 5개. ✅
- 비용 시나리오 3종(MAU 5K/25K/100K). 출시 전 Blaze 전환 권고. ✅
- 보안 규칙 6원칙 + Default Deny + App Check 강제. ✅

### 조건 5 — 수익화 모델
- AdMob 3슬롯 + 첫 60초 차단 UX 가드 + ATT 타이밍(보상형 광고 직전). ✅
- 시장별 ARPU 추정 $0.06–$0.25/MAU, 글로벌 추정 $0.10–$0.14. PRD 목표 $0.05의 2–2.8x. ✅
- 구독 트리거 명료(ARPU < $0.05 OR D7 < 12% → v1.1.0). ✅

### 조건 6 — 가설 검증 프레임워크
- ADR-PROD-001 7필드 카드 + 5단계 사이클(PROPOSE→DESIGN→RUN→DECIDE→LEARN). ✅
- 결과 기록 위치 표준화(`learnings/HC-{ID}.md` 템플릿). ✅
- 백로그 큐 운영(backlog.md). ✅

## Phase 2 진입 조건 (블로커 일정)

Phase 2 시작 시 다음 작업이 첫 1주 내 완료되어야 함:

1. **ADR-001 모듈 경계 + ADR-002 DI 전략** (ios-lead) — Phase 2 첫 두 태스크.
2. **iOS Unit Testing Bundle 추가 + TDD 골격** (ios-lead).
3. **ADR-302 Firestore 스키마** (server-data) — observability.md 이벤트 스키마와 stores/users/reviews 컬렉션 정합 검증.
4. **ADR-303 App Check + 보안 규칙 실 파일** (server-auth) — security-rules.md 가이드를 firestore.rules / storage.rules로 구현.
5. **Auth 비용 우려(시나리오 C $275) 대응** (server-auth, ADR-303 의존성).

## 영향

- Phase 2 팀 구성: ios-lead + ios-{map,auth-monetize,store,social-collection} 5명 + server-lead + qa-lead 합류.
- Phase 1 5명 중 po-lead/po-growth는 백그라운드로 가설 운영(ADR-PROD-001) 사이클 시작.
- designer-lead/designer-icon은 Phase 2 시안 검수 + 이연 산출물 보강.

## 거부 옵션 — Phase 1 보류 (택하지 않음)

- 보류 사유 후보: observability.md 미완 / DE/FR 시장조사 신뢰도 낮음 / handoff-mapping.md 13 화면 와이어프레임 별도 미작성.
- 거부 이유: 이연 처리해도 Phase 2 첫 1주의 iOS 모듈 작업(어차피 Domain 레이어 시작)을 막지 않음. 이연 항목은 Phase 2 게이트에서 강제 회수.

## Changelog

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-04 | Phase 1 통과(PASS) | po-lead |
