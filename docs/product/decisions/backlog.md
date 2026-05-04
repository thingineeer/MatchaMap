# Hypothesis Backlog

> [ADR-PROD-001](ADR-PROD-001-hypothesis-framework.md)의 Hypothesis Card 큐. 우선순위 순.
>
> 본 파일은 **인덱스 + 카드 본문**. 활성 가설은 7필드(ID/한줄/근거/측정/실험/기간/임계/결과위치)를 카드 본문에 채워 등록한다.

## 활성 (Active)

| 우선순위 | ID | 한 줄 가설 | 단계 | 책임 |
|---|---|---|---|---|
| 1 | H1 | travel_mode=true 사용자의 도감 등록률 ≥ 50% | DESIGN | po-lead + server-lead |
| 2 | H2 | friend_count≥1 D7 ≥ friend_count=0 D7 × 2 | DESIGN | po-lead + ios-social-collection |
| 3 | H3 | AdMob ARPU 글로벌 ≥ $0.05/MAU (po-growth 추정 보수적) | DESIGN | po-growth |
| 4 | H4 | KR D7 ≥ JP D7 + 5pp & KR ARPU ≥ JP ARPU × 0.7 | DESIGN | po-growth |
| 5 | H4' | US D0(D+30) D7 ≥ 17% & ARPU ≥ $0.18/MAU (옵션 C 검증) | PROPOSE | po-growth |
| 6 | H5 | 카드 공유율 25% & 클릭→가입 8% & 신규 중 공유 30% | PROPOSE | po-growth + ios-social-collection |
| 7 | H6 | US ASA CAC ≤ 업계 벤치 × 0.8 (APAC ASO 학습 효과) | PROPOSE | po-growth |

> **단계 격상 (2026-05-04)**: H4를 PROPOSE → DESIGN으로 격상. ADR-PROD-201 §2 4축 정량 비교가 근거 섹션을 채움.

---

## H1 — 여행 + 도감 = 강한 수집욕

```
ID:               H-202605-001
한 줄 가설:        travel_mode=true 세그먼트의 도감 등록률 ≥ 50%
근거:
  - icp.md 페르소나 1(여행자 매니아) JTBD = "낯선 도시에서 진짜 매장을 찾는다" + 시음 결과를 *평생 기록*하고 싶음.
  - market-research-jp.md §7 — 외국인 관광객 모드가 우지/교토 클러스터 검색 빈도 높음.
  - market-research-us.md §7 — NY/LA 출장자 *city hop* 페르소나 강함.
  - PRD §5 핵심 가설 #1.
측정 지표:
  primary  = 도감 등록률(travel_mode=true). ADR-PROD-001 §지표정의 "Collection-Add Rate" 수식.
  guardrail-1 = travel_mode=false 도감 등록률이 < 20%로 하락하지 않을 것 (정상 모드 카니발리제이션 방지).
  guardrail-2 = 크래시율 ≤ 0.5%, ATT 옵트인 ≥ 30%.
실험 방법:        단일군 전후 비교 (travel_mode 분류 = 위치권한 + 거주지로부터 거리 ≥ 200km로 자동 판정).
실험 기간:        D0 ~ D+90.
결정 임계값:      ≥ 50% (PASS) / 35-49% (EXTEND) / < 35% (STOP, PRD §5 H1 기각).
결과 기록 위치:   docs/product/decisions/learnings/HC-202605-001.md (D+90 작성)
```

**연관 산출물**: [`icp.md`](../icp.md), [`growth-loops.md`](../growth-loops.md) §5, [`market-research-jp.md`](../market-research-jp.md), [`market-research-us.md`](../market-research-us.md).

---

## H2 — 친구 피드 = 리텐션 드라이버

```
ID:               H-202605-002
한 줄 가설:        friend_count ≥ 1 사용자의 D7 retention이 friend_count = 0 사용자 D7 retention의 2배 이상
근거:
  - icp.md 페르소나 3(공유러) JTBD = "내 발견을 자랑하고 함께 가기".
  - growth-loops.md §1·§2 — Viral/Collaboration 루프가 retention 가속.
  - PRD §5 핵심 가설 #2.
측정 지표:
  primary  = D7(friend≥1) ÷ D7(friend=0). 분모/분자는 ADR-PROD-001 §지표정의 "D7 Retention" 수식.
  guardrail-1 = friend_count=0 D7 ≥ 12% (혼자 사용도 어느 정도 되는지).
  guardrail-2 = 친구 추가 거부율 ≤ 70%.
실험 방법:        관찰형 코호트 비교 (friend_count는 자연 발생).
실험 기간:        D0 ~ D+60.
결정 임계값:      ratio ≥ 2.0 (PASS) / 1.5-1.99 (EXTEND) / < 1.5 (STOP → v1.1.0 친구 기능 의무화 검토).
결과 기록 위치:   docs/product/decisions/learnings/HC-202605-002.md
```

**연관 산출물**: [`icp.md`](../icp.md) 페르소나 3, [`growth-loops.md`](../growth-loops.md) §1-2.

---

## H3 — AdMob ARPU 글로벌 ≥ $0.05/MAU

```
ID:               H-202605-003
한 줄 가설:        출시 후 30/60/90일 시점 글로벌 ARPU ≥ $0.05/MAU
근거:
  - monetization.md §3 시장별 eCPM × 노출 가정 시뮬레이션 결과 글로벌 가중평균 $0.10–$0.14/MAU.
  - 시장별 iOS eCPM (Playwire 2025): US $14.32 (인터), KR $10.04, UK $10.38, JP $8-10.
  - PRD §5 핵심 가설 #3.
  - po-growth 추정은 노출 횟수 가정 미검증으로 *신뢰도 중*.
측정 지표:
  primary  = 월간 ARPU(USD/MAU). ADR-PROD-001 §지표정의 "AdMob ARPU" 수식 — AdMob 콘솔이 SSOT.
  guardrail-1 = D7 retention 글로벌 ≥ 18% (광고 도입 후 retention 악화 방지).
  guardrail-2 = 인터스티셜 거부율(닫기 < 1초) ≤ 30%.
  guardrail-3 = ATT 옵트인 ≥ 35%.
실험 방법:        단일군 전후 비교 (출시 시점 = 광고 라이브 시점).
실험 기간:        D0 ~ D+90, 30/60/90일 스냅샷.
결정 임계값:
  - ARPU ≥ $0.05 + guardrail OK = SHIP
  - $0.03 ≤ ARPU < $0.05 = EXTEND + 슬롯 빈도 조정 후 30일 재측정
  - ARPU < $0.03 (시장 2개 이상 미달) = STOP → 구독 v1.1.0 가속(monetization.md §4 트리거)
결과 기록 위치:   docs/product/decisions/learnings/HC-202605-003.md
```

**연관 산출물**: [`monetization.md`](../monetization.md) §3·§6, [`admob-slots.md`](../admob-slots.md).

---

## H4 — KR vs JP 비치헤드 우위

```
ID:               H-202605-004
한 줄 가설:        KR D7 retention ≥ JP D7 retention + 5pp (절대) 이고, KR ARPU/MAU ≥ JP ARPU/MAU × 0.7
근거:
  - ADR-PROD-201 §2 4축 비교에서 KR 평균 8.50 vs JP 6.75 (KR 23pt% 우위, Burning Pain·Winnable Share·Referral 우세).
  - 단 WTP 축은 JP 약간 우세(절대 ARPU JP 큼) → KR이 70% 이상 따라잡는지가 별도 임계.
  - market-research-kr.md §8 (KR 비치헤드 점수 8.0) vs market-research-jp.md §8 (7.2).
  - ADR-PROD-003 §H4'와 함께 옵션 C(APAC 듀얼 비치헤드) 가정의 유효성을 함께 검증.
측정 지표:
  primary-1  = D7(KR) - D7(JP) ≥ 5pp. ADR-PROD-001 §지표정의 D7 Retention.
  primary-2  = ARPU(KR) ÷ ARPU(JP) ≥ 0.7. ADR-PROD-001 §지표정의 AdMob ARPU.
  guardrail-1 = 두 시장 D1 ≥ 25% (둘 다 살아있어야 비교 의미).
  guardrail-2 = 두 시장 평균 평점 ≥ 4.3.
실험 방법:        관찰형 시장간 비교. 동시 출시(D0 KR+JP)로 시간 변수 통제.
실험 기간:        D0 ~ D+90.
결정 임계값:
  - 두 primary 모두 PASS = SHIP (KR 비치헤드 우세 확정. v1.1 GTM 예산 KR-우선 유지)
  - 한 쪽만 PASS = EXTEND (D+180까지 관찰)
  - 둘 다 FAIL 또는 KR D7 < JP D7 - 5pp = STOP (JP가 실제 비치헤드 → v1.1 GTM JP 재배분, ADR-PROD-201 §3.3 REVERSED 분기 발동)
결과 기록 위치:   docs/product/decisions/learnings/HC-202605-004.md
```

**연관 산출물**: [`ADR-PROD-201`](ADR-PROD-201-beachhead-kr-vs-jp.md), [`ADR-PROD-003`](ADR-PROD-003-beachhead-decision.md), [`market-research-kr.md`](../market-research-kr.md), [`market-research-jp.md`](../market-research-jp.md), [`launch-plan.md`](../launch-plan.md).

---

## 백로그 (Backlog — Phase 2 이후, PROPOSE 단계 또는 미설계)

- **H4'** (ADR-PROD-003 §H4'): APAC 30일 데이터 보정 후 US 출시가 단독 KR 출시보다 우수한가 — `US D0(D+30) D7 ≥ 17% & ARPU ≥ $0.18/MAU`.
- **H5**: 카드 공유율 25% · 외부 클릭→가입 전환 8% · 신규 가입 중 공유 링크 비중 30% — growth-loops.md §1 검증.
- **H6**: APAC ASO 학습이 US Apple Search Ads CAC를 *학습 없이 진입* 대비 ≥ 20% 절감 — ADR-PROD-003 §H5와 동일.
- **H7**: 인터스티셜 N=5회 vs N=3회 — ARPU 차이 (가드레일: D7 retention 악화 ≤ 2pp).
- **H8**: 빈 도감 그리드의 CTA 카피 ko 변형 (수집욕 자극 vs 안내 톤).
- **H9**: 매장 미리보기 진입 시 위치 권한 재요청 vs 검색바 유도.
- **H10**: 보상형 광고 시청 후 D7 retention이 미시청자 대비 +5pp 개선되는가 (growth-loops.md §4 검증).

## 종료 (Resolved)

(아직 없음. D+30/D+60/D+90 시점에 H1/H2/H3/H4가 첫 입주 예정.)
