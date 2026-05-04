# ADR-PROD-003 — 비치헤드 결정 (KR vs US 동률 해소)

- **일자**: 2026-05-04 · **보강(po-growth cross-check)**: 2026-05-04
- **상태**: Accepted
- **결정자**: `po-lead`, `po-growth` 공동
- **사인오프**: `po-lead`
- **연관**:
  - PRD §7 출시 우선순위, [launch-plan.md](../launch-plan.md)
  - [market-research-kr.md](../market-research-kr.md) §8, [market-research-us.md](../market-research-us.md) §8, [market-research-jp.md](../market-research-jp.md) §8
  - [ADR-PROD-001](ADR-PROD-001-hypothesis-framework.md) — Hypothesis Card 양식 (본 ADR §측정 단락이 그 양식 준수)
  - [ADR-PROD-201](ADR-PROD-201-beachhead-kr-vs-jp.md) — KR vs JP 4축 정량 비교 (본 ADR과 짝)
  - [backlog.md](backlog.md) — H4·H4'·H5·H6 카드 본문

## 컨텍스트

`po-growth`의 비치헤드 5축 평가(잠재 사용자 규모 / 결제 의지 / 도달 용이성 / 경쟁 부재 / 레퍼런스 가능성)에서 **KR(8.0)과 US(8.0)가 종합 동률**. 종합 점수만 보면 사전 가설(KR 1순위, PRD §7·CLAUDE.md 명시)을 정량 데이터가 강하게 지지하지 않는 신호였다. PRD H4 가설은 "KR D7 ≥ JP D7 + 5pp & KR ARPU ≥ JP ARPU × 0.7"로 *KR이 JP를 넘는*만 검증할 뿐, KR vs US를 직접 비교하지 않는다.

본 ADR은 이 동률을 어떻게 해소하고, 출시 시퀀스를 어떻게 결정했는지를 명시한다.

## 정량 근거 — KR vs US 5축 분해 (po-growth cross-check, 2026-05-04 보강)

종합 동률 8.0/8.0이지만 **축별 분포가 정반대**. 이 비대칭이 결정의 핵심 근거.

| 평가 축 | KR | US | Δ (KR-US) | 메모 |
|---|---|---|---|---|
| 잠재 사용자 규모 | 8 | 9 | -1 | US가 글로벌 최대 잠재. KR은 Z세대·30대 여성 폭넓음. |
| 결제 의지(광고/구독) | 6 | **10** | **-4** | iOS eCPM US $14.32 인터/$19.63 보상이 압도(Playwire 2025). |
| 도달 용이성 | **9** | 6 | **+3** | KR 모국어 운영·인스타/X 직접 컨택 vs US ASO 경쟁 치열. |
| 경쟁 부재 | **9** | 6 | **+3** | KR 전용 앱 사실상 0 vs US Cha Cha Matcha + Matcha Spot 등. |
| 레퍼런스 가능성 | 8 | 9 | -1 | US 글로벌 트렌드 셋팅 vs KR K-pop·Jennie 견인. |
| **종합 합계** | **40** | **40** | 0 | — |
| **표준편차** | 1.10 | 1.79 | — | KR이 *전 축 균등 강세*, US가 *결제 의지에 편중*. |

> 근거 출처: [`market-research-kr.md`](../market-research-kr.md) §8, [`market-research-us.md`](../market-research-us.md) §8, [Playwire AdMob eCPM 2025](https://www.playwire.com/blog/admob-ecpm-benchmarks-what-publishers-should-expect).

**해석 — 비대칭 3가지가 결정의 가중치**:

1. **US +4(결제 의지)**는 *출시 후 30일이라도 늦게 따라가도 회수 가능*한 축. 30일 지연 매출 손실 추정: monetization.md §3 추정 $0.18-0.25/MAU × 30일 × 예상 12K US MAU(launch-plan §9 90일 다운로드 12K 기준) ≈ **$650-900 단발성**. 단발성 손실 < 운영 안정성 가치(아래 #2/#3).
2. **KR +3 두 축(도달 용이성·경쟁 부재)**은 *비치헤드 단계에서 결정적*. 비치헤드의 정의는 "작지만 명확한 시장 점유율을 빠르게 확보 가능한 시장" — 도달 용이성·경쟁 부재가 직접 점유율 속도에 기여. 두 축 합산 +6pt가 결제 의지 -4pt를 상쇄하고도 +2pt.
3. **레퍼런스 -1**은 사실상 동률. K-pop의 글로벌 영향력(ADR-PROD-201 §2.4)이 *문화적 트렌드 셋팅*에서 US를 일부 상쇄.

→ **결론**: 종합 동률(8.0=8.0)은 *서로 다른 차원의 강점이 평균화된 결과*이지 *동등한 비치헤드 후보*가 아니다. 비치헤드 단계에서 가장 중요한 *점유율 확보 속도* 축에서 KR이 +6pt 절대 우위(도달 용이성 + 경쟁 부재 합산). KR 1순위 채택은 정량적으로 정당.

## 옵션

### 옵션 A — KR 1순위 유지 (단독 출시 후 US 후속)
- KR D0 → US D+30
- 장점: 모국어 운영 가능, 사용자 피드백 사이클 빠름, 인플루언서 직접 컨택 용이.
- 단점: 글로벌 매출 견인이 30일 지연, 초기 ARPU 데이터(US iOS eCPM $14.32 인터/$19.63 보상)가 늦게 검증됨.

### 옵션 B — US 1순위 변경 (단독 출시 후 KR 후속)
- US D0 → KR D+30
- 장점: iOS eCPM 압도적 우위로 광고 ARPU 데이터 빠르게 확보, 글로벌 매출 즉시 검증.
- 단점: 모국어 운영 불가, 한국팀의 빠른 피드백·인플루언서 직접 협업 손실, 매장 데이터셋 신뢰도가 KR 대비 낮음(NY/LA 50+/40+ 추정 vs KR 200~400 추정).

### 옵션 C — KR + JP 동시 출시 (APAC 비치헤드), US/UK는 D+30
- D0 = KR + JP 동시 출시 → D+30 = US + UK → D+60 = DE + FR
- 장점:
  - **모국어 운영 + 본토 인증 동시 확보**: KR의 빠른 피드백 사이클 + JP의 "본토 인증" 글로벌 신뢰도(JP market-research §1 "글로벌 신뢰도 측면에서 가장 중요") 두 가지를 한 번에.
  - **30일 데이터로 ASO 키워드/카피/슬롯 빈도 보강** 후 US/UK에 적용.
  - **운영 부담 분산**: 6개 시장 동시 출시는 1인 PO + 1인 PO Growth 운영 한계 초과. 30일 간격 그룹핑은 모니터링·인플루언서 컨택·핫픽스 사이클을 한 그룹씩 처리 가능.
  - **AdMob ARPU 데이터 단계적 검증**: KR/JP(추정 $0.09–0.14/MAU) → US/UK($0.13–0.25) → DE/FR($0.06–0.10) 순으로 시장별 ARPU 곡선 형성, 가설 H3 임계 조정 가능.
- 단점:
  - US 매출 견인이 30일 지연.
  - 그룹별로 카피/메타데이터 작업이 두 번 → 작업량 +25%.

## 결정

**옵션 C 채택.** launch-plan.md §1.2 그룹핑 전략으로 이미 운영 합의 완료. 본 ADR은 그 결정의 근거를 명시한다.

## 근거

1. **모국어 + 본토 인증의 결합 가치 > 30일 매출 지연**: KR의 운영 우위와 JP의 글로벌 인증 효과를 동시에 얻는 것이 *어느 한쪽을 단독 1순위로 둘 때*보다 PRD §1 비전("전세계 말차 덕후") 달성에 직접 기여.

2. **매출 지연의 보상**: US 출시를 30일 늦추되 KR/JP 30일 데이터로 ASO 키워드·메시징·인터스티셜 빈도를 *조정 후* 진입 → US 출시 효율 향상으로 매출 지연 손실을 부분적으로 회수.

3. **운영 부담의 현실**: 16명 팀 중 사용자 응대·인플루언서 컨택은 사실상 po-lead + po-growth + qa-localization 3명. 6시장 동시는 D+7 시점에 응답 큐 폭주 위험. 그룹핑이 운영 안정성에 결정적.

4. **반증 메커니즘 보존**: 30일 후 US/UK에서 KR/JP 대비 *현저히 우수한* D7 retention이 관찰되면 PRD §7 시퀀스를 v1.1.0에서 재검토. 본 결정은 v1.0.0 한정.

## 측정 (가설 H4 보강 + 신규 H4'·H5)

본 결정의 검증 가설은 ADR-PROD-001 §Hypothesis Card 7필드 양식을 준수해 [`backlog.md`](backlog.md)에 *완전한 카드*로 등록된다. 본 ADR 본문은 그 카드의 *결정 근거 인용*만 보유.

| 가설 | 카드 위치 | 단계 | 한 줄 요약 |
|---|---|---|---|
| **H4** | [backlog.md §H4](backlog.md) | DESIGN | KR D7 ≥ JP D7 + 5pp & KR ARPU ≥ JP ARPU × 0.7 |
| **H4'** | [backlog.md 백로그](backlog.md) | PROPOSE | US D0(D+30) D7 ≥ 17% & ARPU ≥ $0.18/MAU |
| **H5** | [backlog.md 백로그](backlog.md) | PROPOSE | 카드 공유율 25% / 클릭→가입 8% / 신규 중 공유 30% (그로스 루프 1 검증) |
| **H6** | [backlog.md 백로그](backlog.md) | PROPOSE | APAC 학습 ASO로 US ASA CAC ≥ 20% 절감 |

### H4 — KR vs JP D7/ARPU (PRD §5 그대로)

- 임계: KR D7 ≥ JP D7 + 5pp **AND** KR ARPU/MAU ≥ JP ARPU/MAU × 0.7.
- 임계 미달 시: KR 비치헤드 가정 약화 → v1.1.0 기획 시 JP 우선 강화 검토 (ADR-PROD-201 §3.3 REVERSED 분기 발동).
- 결과 기록: `learnings/HC-202605-004.md`.

### H4' — APAC 비치헤드 vs 글로벌 매출 시차 검증 (신규)

- US D0~D+30 미가용 상태에서 *APAC 30일 데이터*로 보정한 US 출시가, "단독 KR 출시 후 US가 D+60" 가상 시나리오 대비 더 좋은 D7/ARPU를 만드는가.
- 측정 임계: D+30 US 출시 직후 D7 retention ≥ 17% **AND** ARPU/MAU ≥ $0.18 → 옵션 C 유효.

### H5 (= backlog H6) — APAC 데이터 → US ASA 키워드 효율 (신규)

- KR/JP 30일에서 학습된 ASO 키워드 매핑이 US Apple Search Ads CAC를 *학습 없이* 진입 시 대비 ≥ 20% 절감하는가.
- 측정: D+30 ~ D+60 US ASA CAC vs 업계 벤치($1.80–$3.00 라이프스타일).

> backlog.md에서 H5 ID는 *카드 공유율 가설*에 부여됨. 본 ADR이 신규로 제안한 *ASO 효율 가설*은 backlog.md의 **H6**와 동일한 가설. 향후 ID는 H6로 통일.

## 영향

- PRD §7 시퀀스(KR→JP→US→UK→DE→FR)는 launch-plan §1.2 그룹핑(KR+JP / US+UK / DE+FR)으로 *그룹 단위 해석* 유지.
- po-growth가 인플루언서 컨택을 그룹별로 분할해서 진행(§launch-plan §6 풀에서).
- server-lead의 cost-projection 시나리오 B(MAU 25K)는 KR+JP+US+UK D+60 합산 가정으로 재검증 필요(별도 보강 또는 시나리오 추가).
- qa-localization은 KR/JP 카탈로그 첫 회귀 → US/UK 두 번째 → DE/FR 세 번째로 일정 분배.

## Learnings (사후 D+90 회고에서 채움)

- (예정) HC-202608-001: 옵션 C 옵션 회고 — 매출 지연 30일이 정성적/정량적으로 유효했는가.

## Changelog

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-04 | Accepted (옵션 C — APAC 비치헤드 그룹) | po-lead, po-growth |
| 2026-05-04 | po-growth cross-check 보강 — KR vs US 5축 정량 분해 표(§정량 근거) 추가, 가설 카드 양식을 ADR-PROD-001과 정합 (§측정), H4/H4'/H5/H6 ID와 backlog.md 정합화 | po-growth (사인오프 대기) |
