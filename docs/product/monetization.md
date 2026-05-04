# Monetization Strategy

> Owner: `po-growth` · Last updated: 2026-05-04 · Reviewer (예정): `po-lead`, `ios-auth-monetize`

## 1. 한 줄

**MVP는 AdMob 3슬롯 광고**. 광고 ARPU < $0.05/MAU 임계 도달 시 **유료 구독(연 $4.99: 광고 제거 + 도감 무제한)**을 v1.1.0에서 도입.

이 결정은 `.claude/memory/decisions-monetization.md`에 이미 확정되어 있으며, 본 문서는 **운영 정책 + ARPU 추정 근거**를 추가한다.

---

## 2. AdMob 3슬롯 정책

| 슬롯 | 위치 | 빈도 | UX 가드 |
|---|---|---|---|
| **배너** | 지도 화면 하단 (홈 인디케이터 위) | 상시 | 첫 사용 60초 차단, 인터랙션 중 hide |
| **인터스티셜** | 매장 상세 진입 시 | N=5회마다 | 쿨다운 90초, 첫 화면/첫 60초 차단 |
| **보상형** | 도감(컬렉션) 잠금 해제 | 사용자 자발 시청 | 광고 ID 별도, 쿨다운 없음 |

자세한 매핑은 [admob-slots.md](admob-slots.md).

### 2.1 절대 규칙 (양보 금지)

- **첫 화면 = 광고 없음**. 사용자가 앱을 열자마자 광고가 보이면 D1 retention -10pp.
- **첫 60초 = 광고 없음**. 신규 활성 사용자에게 단 한 번도 광고 노출 X.
- **로그인 직후 = 광고 없음**. 인증 직후 *환영 화면*에서 즉시 광고는 강한 이탈 유발.
- **음성/접근성 모드에서 광고 폼 변경 금지** — Apple 심사 가이드 5.1.1 회피.

### 2.2 ATT (App Tracking Transparency)

- 프롬프트 타이밍: **첫 사용 60초 후**, *지도 첫 진입 직후*가 아닌 *도감 잠금해제 보상형 광고 클릭 직전*에 표시 (가장 자연스러운 컨텍스트).
- 카피는 6개 언어로 작성, `qa-localization` 검수.

---

## 3. ARPU 추정

### 3.1 시장별 iOS eCPM 벤치마크 (2025 Q3-Q4 → 2026 적용)

| 국가 | 배너 (USD) | 인터스티셜 (USD) | 보상형 (USD) | 출처 |
|---|---|---|---|---|
| US | $0.45 | $14.32 | $19.63 | Playwire 2025 |
| UK | $0.44 | $10.38 | ~$15 | Playwire 2025 |
| KR | ~$0.30 | $10.04 | ~$13 | Playwire 2025 |
| JP | ~$0.35 | $8-10 | ~$13 | Tier 1 평균 |
| DE | ~$0.30 | $7-9 | ~$11 | Tier 1 평균 |
| FR | ~$0.28 | $6-8 | ~$10 | Tier 1 평균 |
| Global avg | $0.20-$0.50 | $2.50-$5.00 | $8.00-$18.00 | Tenjin/Appodeal |

> 출처: [AdMob eCPM Benchmarks (Playwire)](https://www.playwire.com/blog/admob-ecpm-benchmarks-what-publishers-should-expect), [Mobile Ads eCPM (Maf.ad)](https://maf.ad/en/blog/mobile-ads-ecpm/), [Tenjin Benchmark 2025](https://tenjin.com/blog/ad-mon-gaming-2025/)

### 3.2 사용자 1인당 일일 노출 가정 (말차맵)

| 슬롯 | 일일 노출 (DAU 기준) | 비고 |
|---|---|---|
| 배너 | 8-15회 | 지도 화면 평균 체류 + 60초 차단 후 |
| 인터스티셜 | 0.4-1.0회 | 매장 상세 평균 2-3회 진입 / 5회마다 |
| 보상형 | 0.1-0.3회 | 도감 잠금 해제 자발 시청 |

### 3.3 ARPU 모델 (US 사용자, 활성 30일)

```
배너:    10회/일 × 30일 × $0.45/1000 = $0.135
인터:    0.7회/일 × 30일 × $14.32/1000 = $0.300
보상:    0.2회/일 × 30일 × $19.63/1000 = $0.118
─────────────────────────────────────
ARPU(US, 30일) ≈ $0.55
ARPU(US, 월 평균 MAU 환산) ≈ $0.18-$0.25
```

### 3.4 글로벌 ARPU 가설

| 시장 | ARPU/MAU 추정 | PRD 목표 ($0.05) 대비 |
|---|---|---|
| US | $0.18-$0.25 | 4-5x 초과 (강) |
| UK | $0.13-$0.18 | 2.5-3.5x 초과 |
| KR | $0.10-$0.14 | 2-2.8x 초과 |
| JP | $0.09-$0.12 | 1.8-2.4x 초과 |
| DE | $0.07-$0.10 | 1.4-2x 초과 |
| FR | $0.06-$0.09 | 1.2-1.8x 초과 |
| **글로벌 가중평균** | **$0.10-$0.14** | **2-2.8x 초과** |

**해석**: PRD §4 목표 *글로벌 ARPU $0.05/MAU*는 **상당히 보수적**. 단, 신뢰도는 *중*으로 둔다 — 사용자 노출 횟수 가정이 미검증.

### 3.5 반증 시나리오

| 시나리오 | 트리거 | 대응 |
|---|---|---|
| 노출당 가정 과대 | 일일 배너 노출 < 5회 | 배너 노출 영역 확대, 단 UX 가드는 유지 |
| eCPM 급락 | iOS ATT 거부율 > 80% | ATT 카피/타이밍 재설계 |
| 광고 거부감 강 | D7 retention -10pp 이상 | 인터스티셜 빈도 N=5 → N=8로 완화 |

---

## 4. 유료 구독 (v1.1.0 후보)

### 4.1 트리거 조건

- 광고 ARPU 측정값 < $0.05/MAU **OR**
- D7 retention < 12% (도감 무제한 카드를 retention 도구로 활용)

### 4.2 가격대 후보 (A/B 예정)

| 옵션 | 가격 | 혜택 |
|---|---|---|
| A (보수) | **연 $4.99** / 월 $0.99 | 광고 제거 + 도감 무제한 |
| B (공격) | **연 $9.99** / 월 $1.49 | A + 친구 그룹 도감 + 시즌 컬렉션 뱃지 |

### 4.3 결제 SDK

- **StoreKit 2** (iOS 15+). FearIndex에서 검증된 패턴 재사용.
- 가족 공유 / 환불 처리 / 구독 일시정지 지원.

### 4.4 전환 임계 (PMF 신호)

- **무료 → 유료 전환**: 1주차 ≥ 1.5%, 1개월 누적 ≥ 3%.
- **연 갱신율**: ≥ 50% (FearIndex 벤치 기준).

---

## 5. 비범위 (v1.0.0)

- 광고 매개체 분리(Inmobi/AppLovin/Unity Ads): AdMob mediation은 v1.1.x.
- 인앱 결제(개별 카드 구매): UX 복잡성, v1.2.0 검토.
- 매장 광고 (sponsored placement): 윤리/공정성 이슈. v1.2.0 검토.
- 친구 추천 보상 (referral cash): App Store 정책 정밀 검토 필요.

---

## 6. KPI 트래킹

| KPI | 목표 (30일) | 미달 시 액션 |
|---|---|---|
| ATT 옵트인율 | ≥ 35% | 카피 A/B |
| 광고 ARPU (글로벌) | ≥ $0.05 | 슬롯 영역 조정 |
| 인터스티셜 거부율 (광고 닫기 < 1초) | ≤ 30% | 빈도 완화 |
| D7 retention (광고 후) | ≥ 18% | 광고 차단 시간 확대 |

## 7. 가설 매핑

본 monetization.md는 다음 [backlog.md](decisions/backlog.md) 가설 카드의 직접 근거가 된다:

| Hypothesis ID | 매핑 섹션 | 어떻게 검증되는가 |
|---|---|---|
| **H3** | §3 ARPU 추정·§3.4 글로벌 가중평균 | 출시 후 30/60/90일 AdMob 콘솔 결산값을 ADR-PROD-001 §지표정의 "AdMob ARPU" 수식으로 측정. 임계 $0.05/MAU. |
| **H4** | §3.1 시장별 eCPM 표 | KR ARPU vs JP ARPU의 비율(≥ 0.7)을 4축 비교 ADR-PROD-201과 함께 검증. |
| **H7** (백로그) | §2.1 인터스티셜 빈도 N=5 | 빈도 변경(N=5 vs N=3)이 ARPU에 미치는 영향 — Phase 2 이후 A/B. |
| **H10** (백로그) | §2.1 보상형 슬롯 | 보상형 광고 시청자의 D7 retention이 +5pp 우수한가. |

가드레일(공통): D7 retention ≥ 18%, 인터 거부율 ≤ 30%, ATT 옵트인 ≥ 35%.

## 8. 출처

- [AdMob eCPM Benchmarks | Playwire](https://www.playwire.com/blog/admob-ecpm-benchmarks-what-publishers-should-expect)
- [Mobile Ads eCPM | Maf.ad](https://maf.ad/en/blog/mobile-ads-ecpm/)
- [Tenjin Ad Monetization Benchmark 2025](https://tenjin.com/blog/ad-mon-gaming-2025/)
- [Mobile Advertising Rates 2025 | Business of Apps](https://www.businessofapps.com/ads/research/mobile-app-advertising-cpm-rates/)
- [`decisions/ADR-PROD-001-hypothesis-framework.md`](decisions/ADR-PROD-001-hypothesis-framework.md) §지표정의 (ARPU 공식)
