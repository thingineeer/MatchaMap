# ADR-PROD-001 — 가설 검증 프레임워크 (Hypothesis Framework)

- **일자**: 2026-05-04
- **상태**: Accepted
- **결정자**: `po-lead` · 사인오프: `po-lead`
- **영향**: 전 에이전트 (제품/디자인/iOS/QA/서버 모두 가설 등록·검증 시 본 ADR 준수)

## 컨텍스트

말차맵은 6주 MVP 일정 + 6개 시장이라는 좁은 시간/넓은 변수 조합을 다룬다. 의사결정이 의견·인상·관성으로 흐르지 않으려면 **가설 → 측정 → 학습** 사이클을 표준화하고 모든 결정의 근거를 추적 가능한 형태로 남겨야 한다. 본 ADR은 그 운영 규칙을 정의한다.

## 결정

말차맵의 모든 제품 가설은 다음 7개 필드를 가진 **Hypothesis Card** 단위로 등록·검증한다.

```
ID:               H-YYYYMM-NNN (예: H-202605-001)
한 줄 가설:        "[조건]이면 [결과]가 [임계]를 만족한다"
근거:             왜 이 가설이 그럴듯한가? 선행 사례/유저 인터뷰/유사앱 데이터
측정 지표:        primary_metric (수식까지) + guardrails(악화시 abort)
실험 방법:        관찰형 / A·B / 단일군 전후비교 / 코호트 비교
실험 기간:        T-시작 ~ T-종료, 최소 노출/샘플 N
결정 임계값:      p-value, MDE, 또는 도메인 경험적 임계
결과 기록 위치:   docs/product/decisions/learnings/HC-YYYYMM-NNN.md
```

**가설 카드는 GitHub Markdown으로 PR을 통해 등록한다.** 이력 보존(no-squash) + CodeRabbit 리뷰 대상.

## 사이클 (5단계)

1. **PROPOSE (가설 제안)**
   - 누구든 제안 가능. po-lead/po-growth가 우선순위 큐를 관리(`docs/product/decisions/backlog.md`).
   - 제안 시 위 7필드를 채워 PR 생성. 미완 필드는 "TBD-{책임자}" 명시.

2. **DESIGN (실험 설계)**
   - 측정 가능한 정의로 수식화. 분자/분모, 시간 윈도우, 세그먼트(시장/언어/플랫폼)를 명시.
   - 가드레일 지표(예: 크래시율, ATT 동의율) 함께 정의. 가드레일이 X% 악화되면 즉시 중단.
   - server-lead가 이벤트 스키마를 검토(observability.md와 정합).

3. **RUN (실험 실행)**
   - 코드 변경이 필요하면 worktree feat 브랜치(§ CLAUDE.md 6.1)로 분리.
   - A/B는 Firebase Remote Config + Analytics 코호트. MVP 초기에는 단일군 전후 비교(pre/post launch)로 시작.
   - 실행 중 매주 화요일 10:00 KST에 결과 스냅샷 → po-lead가 dry-run으로 임계 대비 진척 점검.

4. **DECIDE (결정)**
   - 임계 도달 + 가드레일 정상 → **SHIP**: 영구 적용 + PRD 반영.
   - 임계 미도달 + 표본 부족 → **EXTEND**: 기간 연장(상한 있음, 사이클 1회 한정).
   - 임계 미도달 + 표본 충분 → **STOP**: 가설 기각 + ADR 보강 + 백로그 다음 가설로 이동.
   - 가드레일 위반 → **ABORT**: 즉시 중단 + 인시던트 회고.

5. **LEARN (학습 기록)**
   - `docs/product/decisions/learnings/HC-{ID}.md`에 결과·결정·후속 액션을 기록.
   - 기각된 가설도 반드시 기록. 다음 PRD 사이클에서 재제안 방지.

## 지표 정의 (PRD §4와 일치, 조작 가능 정의)

본 ADR이 다음 지표의 **공식 수식**을 정의한다. PRD/observability/QA가 모두 이 정의를 인용한다.

### D1 / D7 Retention
- **분모**: `users.created_at`이 코호트 일자 D0 KST 00:00–23:59 사이인 사용자.
  - 코호트는 가입 일자 기준 (사용자의 첫 `auth_session_started` 이벤트 발생일).
- **분자(D1)**: 위 코호트 중 `[D0+24h, D0+48h)` 윈도우에 `session_start` 이벤트가 1회 이상 있는 사용자.
- **분자(D7)**: 위 코호트 중 `[D0+7d, D0+8d)` 윈도우에 `session_start` 이벤트가 1회 이상 있는 사용자.
- **목표**: D1 ≥ 35%, D7 ≥ 18%.
- **세그먼트**: 시장(country) × locale × travel_mode 별로 별도 산출.
- **윈도우 선택 근거**: 24h/48h 슬라이딩이 아닌 고정 윈도우. AdMob 일별 정산과 정합.

### 도감 등록률 (Collection-Add Rate)
- **분모**: `store_view` 이벤트 1회 이상 발생한 고유 (user_id, store_id) 쌍 — 매장 상세를 본 케이스.
- **분자**: 같은 (user_id, store_id) 쌍에 대해 `store_view` 이후 7일 이내 `store_collection_added` 이벤트가 1회 이상 발생한 케이스.
- **목표**: 30% (전체) / 50% (travel_mode=true 세그먼트 — 가설 H1).
- **분리 산출 이유**: 분모를 "사용자"로 잡으면 한 사용자의 여러 매장 행동이 평균에 묻힌다. 매장×사용자 쌍 단위가 도감 본질("이 매장을 모았다") 측정에 부합.

### AdMob ARPU (글로벌)
- **분모**: 해당 월 MAU = 그 달 1회 이상 `session_start` 이벤트가 있던 고유 user_id.
- **분자**: 같은 달 AdMob 콘솔 보고된 광고 수익(USD, 환율은 AdMob 결산 기준).
  - 클라이언트 `ad_impression` × eCPM 추정치는 **검증용 보조**일 뿐, 공식 ARPU는 AdMob 콘솔의 실 결산 금액이 단일 진실 원천(SSOT).
- **목표**: 글로벌 평균 ≥ $0.05 / MAU.
- **시장별 가드레일**: KR/JP/US 셋 중 두 시장 이상이 $0.03 미만이면 구독 전환 가속(monetization.md 트리거 발동).

### 친구 1+ 사용자 비율
- **분모**: 월간 MAU.
- **분자**: 그 달의 첫 `session_start` 시점 기준 `friend_count ≥ 1` 인 사용자.
- **목표**: 25%.

### 평균 평점 (App Store)
- App Store Connect API 또는 Connect 콘솔 수기 확인. 6개 스토어 가중평균(installs 가중).
- **목표**: ≥ 4.3.

## 실험 기간 가이드

| 가설 유형 | 최소 기간 | 권장 기간 | 최소 표본 |
|---|---|---|---|
| Onboarding 변형(권한 카피/순서) | 7일 | 14일 | 시장당 N=500 |
| Map UX(클러스터링/카메라) | 14일 | 28일 | N=1000 |
| 광고 슬롯/빈도 | 14일 | 28일 | 슬롯당 impression ≥ 10k |
| Collection/Social 루프 | 28일 | 60일 | N=2000 |

기간이 짧을수록 노이즈 ↑. 위 가이드보다 짧게 결정하려면 ADR-PROD-001 보강 필요.

## 임계값 정책

- **양적 가설(retention/ARPU 등)**: 단측 검정 p < 0.05 + practical significance(절대 차이 ≥ 정의된 MDE).
- **경험적 임계**: 표본 < 가이드 표본 절반 → SHIP 결정 금지(대신 EXTEND).
- **반증 환영**: 임계 미달이라도 가드레일이 우수하면 백로그에 "재실험 후보"로 보관.

## 결과 기록 (Learning Log)

`docs/product/decisions/learnings/HC-{ID}.md` 템플릿:

```markdown
# HC-{ID} — 한 줄 가설 (결과: SHIP / STOP / ABORT)

- 기간: YYYY-MM-DD ~ YYYY-MM-DD
- 표본: N=...
- 결과 표 (primary metric, 가드레일)
- 결정: SHIP / STOP / ABORT
- 후속 액션:
  - PRD §X 변경
  - 관련 ADR 변경
  - 다음 가설 후보
- Changelog
```

## 운영 룰

- **모든 PR이 가설을 인용**: 사용자 가시 변경(UI/카피/광고)을 도입하는 PR은 description에 `Hypothesis: H-...` 라인 또는 `No hypothesis (rationale: ...)` 명시.
- **가설 ID는 결정 ADR 본문에 인용**: ADR-PROD-NNN 또는 ADR-NNN의 "근거" 섹션에 가설 카드 링크.
- **월 1회 리트로**: po-lead 주관, 활성 가설 전수 점검 + 결정/연장.

## 영향

- po-growth: 시장 진입 가설(KR vs JP, GTM 채널)을 본 카드 형식으로 등록.
- designer-lead: UI 변경 시 영향 가설(예: 빈 상태 메시지가 도감 등록률에 미치는 영향)을 옵션으로 제안 가능.
- ios-lead/server-lead: 측정에 필요한 이벤트 스키마 보장. 누락 시 가설은 PROPOSE 단계에서 설계 검토 통과 불가.
- qa-lead: 가설 검증 종료 시점에 측정 신뢰성을 회귀.

## 거부된 대안

- **OKR을 가설 대신 사용**: OKR은 KR이 산출 결과(achievement)에 가깝고, 인과 관계 검증을 강제하지 않아 기각.
- **가설 없이 직관 기반 결정**: 6개 시장의 변수가 많아 직관 한계 명확. 기각.

## Changelog

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-04 | Accepted | po-lead |
