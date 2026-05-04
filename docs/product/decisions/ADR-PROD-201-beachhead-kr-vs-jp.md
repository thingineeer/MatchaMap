# ADR-PROD-201 — 비치헤드 시장 결정 (KR vs JP 4축 정량 비교)

- **일자**: 2026-05-04
- **상태**: Accepted (단, 검증 가설 H4로 출시 후 90일 재평가)
- **결정자**: `po-growth` 제안 · `po-lead` 사인오프 대기
- **연관 가설**: H4 (KR D7 ≥ JP D7 + 5pp & KR ARPU ≥ JP ARPU × 0.7)
- **연관 ADR**:
  - [ADR-PROD-001 가설 프레임워크](ADR-PROD-001-hypothesis-framework.md) — 본 ADR의 측정 정의 인용
  - [ADR-PROD-003 KR vs US 동률 해소(옵션 C)](ADR-PROD-003-beachhead-decision.md) — *KR/JP 동시 출시 결정*은 003에서 확정. 본 ADR은 003이 결정한 *듀얼 비치헤드*의 **KR vs JP 내부 4축 정량 비교**를 추가 (003에는 4축 분해가 없었음).
- **영향**: GTM/광고/인플루언서 예산, 그룹 내 우선순위(KR 1차 모니터링), 다국어 카피 우선순위.

## 1. 컨텍스트

CLAUDE.md §1과 PRD §7은 출시 시퀀스를 **KR → JP → US → UK → DE → FR**로 명시하지만, 그 근거는 (a) 사용자 모국어, (b) FearIndex 운영 경험, (c) "한국 트렌드의 글로벌 영향력" 인상이다. 이 결정이 **정량 근거**로도 성립하는지 4축(Christensen-Christophersen 비치헤드 프레임)으로 검증한다.

> 4축: **Burning Pain · Willingness to Pay · Winnable Share · Referral Potential**

본 ADR은 KR을 1순위로 유지하되, JP를 *동시 그룹(D-7 베타 → D0 출시)*에 포함시켜 **APAC 비치헤드 그룹**으로 확장한다. 단일 시장 베팅이 아닌 *듀얼 비치헤드*가 제품 검증에 더 강하기 때문.

## 2. 4축 정량 비교

각 축은 0–10 점수 + 정량 근거를 동반. 동점일 경우 *제품-시장 핏 신호 강도*로 우선순위 결정.

### 2.1 Burning Pain (불편의 강도) — KR 우세

| 신호 | KR | JP | 출처 |
|---|---|---|---|
| 카테고리 검색 부재 | 카카오맵·네이버지도에 *말차 전용 카테고리 없음* | Tabelog에 차/카페 카테고리 있으나 "말차 전문" 필터 없음 | 각 플랫폼 카테고리 트리 직접 확인 |
| 매장 발견 1차 채널 만족도 | Naver 블로그/인스타 검색 → *재가공 콘텐츠 만족 낮음* | Tabelog → *카페 카테고리 신뢰 중상*, 노포는 자체 명성으로 발견 | KFriday/KoreaTravelPost 정성 평가 |
| 원료 가격 부담으로 *인증 욕구* 발생 | Uji 원료 +42% (1년) → 사용자도 *"진짜 우지인가?"* 의심 | 본토라 인증 욕구 약 | KoreaTravelPost 2025 |
| 도감/메모 자작 행동 | Notion/Apple Notes에 매차 메모 빈도 높음 (인스타 #말차도감 활성) | 일부 다도/와가시 매니아만 자작 | 인스타 해시태그 표본 |
| **점수** | **8.5** | **5.5** | — |

**해석**: KR은 "기존 도구로는 큐레이션이 안 된다"는 불편이 *명시적*. JP는 본토 + Tabelog로 *허용 가능한 차선책*이 존재 → 진입의 burning pain은 KR이 더 크다.

### 2.2 Willingness to Pay (지불 의지) — JP 우세

| 신호 | KR | JP | 출처 |
|---|---|---|---|
| iOS 인터스티셜 eCPM | $10.04 | $8–10 | Playwire 2025 |
| 평균 매장 객단가 | 8,500 KRW (~$6.30) | 1,200 JPY (~$8.10) | 시장조사 §6 |
| 연간 모바일 게임 ARPU | ~$110 | $118 | SQ Magazine 2025 / Sensor Tower |
| 연간 앱당 결제 ARPU | 약 $90-100 | $118 | 동일 |
| iOS 인앱 결제 보급 | 높음 | 매우 높음 (코쿠야쿠 보급률 + 결제 신뢰) | 산업 보고 |
| **점수** | **7.5** | **8.5** | — |

**해석**: JP가 절대 ARPU와 결제 신뢰도에서 미세 우위. 단 KR도 Tier 1 상위로 *PRD §4 ARPU 목표 $0.05/MAU*는 두 시장 모두 단독으로도 달성 가능 (시장조사 monetization §3.3 추정).

### 2.3 Winnable Share (승자독식 가능성) — KR 우세

| 신호 | KR | JP | 출처 |
|---|---|---|---|
| 말차 전용 모바일 앱 | **부재** (체인 자체앱만 존재) | **부재** (단, Tabelog가 카테고리 일부 충족) | 앱스토어 카테고리 직접 확인 |
| 큐레이션 매체 강도 | KFriday/KoreaTravelPost (블로그) | matcha-jp.com / Fun-Japan (관광 가이드) | 시장조사 §3 |
| 모국어 ASO 경쟁 | 낮음 (`말차`+`도감`+`지도` 결합 키워드 경쟁자 0) | 중상 (`抹茶 マップ` 일부 가이드 앱 존재) | 앱스토어 검색 |
| 진입 후 6개월 내 30% 점유 가능성 | 가능 | 어려움 (Tabelog/노포 자체앱 견제) | 정성 추정 |
| **점수** | **9.0** | **6.0** | — |

**해석**: 동일 카테고리에서 *작지만 명확한 시장 점유율*을 빠르게 확보 가능한 정도는 KR이 압도. JP는 *일본인 사용자*보다 *여행자 모드 일본 검색* 시나리오가 더 winnable.

### 2.4 Referral Potential (외부 시장 견인) — KR 우세

| 신호 | KR | JP | 출처 |
|---|---|---|---|
| K-pop/K-콘텐츠 글로벌 영향력 | 매우 높음 (Blackpink Jennie 매차 루틴 → US/EU 트렌드 견인) | 본토 인증 효과는 강하나 *콘텐츠 자체*는 정적 | Korea Herald 2025 |
| 인스타/TikTok 한국어 콘텐츠 글로벌 도달 | 자동 번역/리포스트 강함 | 일본어 콘텐츠는 일본 내 머무는 비중 큼 | iCrossBorder Japan 2025 |
| 한국→일본 여행자 비중 | KR 사용자가 JP 출장/여행 잦음 → JP 매장 데이터 시드를 KR이 만들 수 있음 | 역방향 비중은 작음 | 관광 통계 |
| **점수** | **9.0** | **7.0** | — |

**해석**: KR은 *글로벌 트렌드 진앙*으로서 referral 잠재력이 매우 큼. JP는 *진정성 보증*으로서 referral. 둘 다 가치 있지만 KR이 시간가속에서 우세.

### 2.5 종합

| 축 | KR | JP |
|---|---|---|
| Burning Pain | 8.5 | 5.5 |
| Willingness to Pay | 7.5 | 8.5 |
| Winnable Share | 9.0 | 6.0 |
| Referral Potential | 9.0 | 7.0 |
| **합계** | **34.0** | **27.0** |
| **평균** | **8.50** | **6.75** |

**KR 우세 (1.75pt 차이, 23pt% 우위)**.

## 3. 결정

### 3.1 1순위: KR (확정 유지)

CLAUDE.md/PRD에 명시된 KR 1순위는 **정량적으로 정당**. Burning Pain + Winnable Share + Referral의 3축에서 명백 우위.

### 3.2 2순위: JP — *KR과 동시 그룹*으로 격상 (변경)

기존 PRD §7의 *순차 출시* (KR → JP)에서 **APAC 비치헤드 그룹 동시 출시**로 변경:

- **D-7 ~ D-1**: KR + JP 베타 동시 (KR 200명, JP 100명)
- **D0**: KR + JP App Store 동시 출시 (Hard launch)
- 그룹 간 간격은 D0 → D+30 (US/UK) → D+60 (DE/FR) 유지

**Why**:
- WTP 축에서 JP가 약간 우세 → ARPU 가설(H3) 검증의 *상한값*을 빨리 확보.
- JP 본토 인증이 KR/US 시장 referral에 즉시 작동 (H4 referral 측면).
- 일정 +1주만으로 검증력 ×2.

### 3.3 결정의 가설 종속성

본 결정은 **출시 후 90일 H4(가설카드 H-202605-004)의 결과로 재평가**한다.

- **H4 SHIP**: KR 비치헤드 우세 확정 → US 진입 시에도 KR 인플루언서·콘텐츠를 견인 차로 활용.
- **H4 STOP/REVERSED** (KR D7 < JP D7 - 5pp 또는 KR ARPU < JP ARPU × 0.5): JP가 실제 비치헤드. v1.1 GTM 예산을 JP로 재배분.

## 4. 측정 (Phase 4 출시 후 90일)

| 지표 | KR 목표 | JP 목표 | 비교 임계 (H4) |
|---|---|---|---|
| D7 retention | ≥ 18% | ≥ 13% | KR ≥ JP + 5pp |
| 도감 등록률 (전체) | ≥ 30% | ≥ 25% | KR ≥ JP - 0pp |
| ARPU/MAU (USD) | ≥ $0.10 | ≥ $0.12 | KR ≥ JP × 0.7 |
| 평균 평점 | ≥ 4.3 | ≥ 4.3 | 동일 |
| 인플루언서 자연 노출 | KR 1,000+/주 | JP 500+/주 | — |

가드레일(즉시 대응): KR 또는 JP 어느 쪽이든 D1 < 25% 또는 크래시율 > 1%.

## 5. 거부된 대안

### 대안 A — 단일 KR 베타 후 JP 순차 출시

- 장점: 운영 단순.
- 단점: WTP 검증 지연. JP referral 효과 1개월 손실.
- **기각 이유**: 일정 1주 추가만으로 Dual-beachhead 운영 가능.

### 대안 B — JP를 1순위로 변경

- 장점: WTP 절대 우위.
- 단점: Burning Pain/Winnable Share 명백 열세. 한국어 → 일본어 카피 우선 전환 비용.
- **기각 이유**: 4축 합계 7pt 차이. 정량적으로 정당화 안 됨.

### 대안 C — KR + US를 듀얼 비치헤드

- 장점: 매출 견인 시장 동시 진입.
- 단점: ASO 경쟁(US) + 인플루언서 비용 ×3 + 영어 카피 검증 미완.
- **기각 이유**: Phase 1에서 검증 + Phase 2 진입 분리 모델이 더 안전.

## 6. 영향

- **PRD §7**: "KR → JP → US..."는 유지하되 *"KR + JP 동시 출시 후 그룹별 진입"*으로 표현 정밀화 (po-lead가 §7 갱신).
- **launch-plan.md**: 이미 "APAC 비치헤드(KR + JP, D0)" 그룹으로 작성됨 — 본 ADR과 정합 OK.
- **monetization.md**: ARPU 가설(H3) 시장별 분리 표 유지. JP를 KR과 함께 *Phase 1 정산 대상*으로.
- **icp.md**: 페르소나 1(여행자 매니아)의 KR↔JP 트래픽이 즉시 가설 H4의 *교차 데이터* 시드.

## 7. 출처

- [South Korea Mobile App Market Statistics | 42matters](https://42matters.com/south-korea-app-market-statistics)
- [Mobile Game ARPU by Country | GAMES.GG](https://games.gg/news/mobile-game-arpu-by-country-insights-for-ua-strategy-and-growth/)
- [2025 State of Mobile | Sensor Tower](https://sensortower.com/blog/2025-state-of-mobile-consumers-usd150-billion-spent-on-mobile-highlights)
- [App Revenue Data 2026 | Business of Apps](https://www.businessofapps.com/data/app-revenues/)
- [Korean Social Media in 2025 | iCrossBorder Japan](https://www.icrossborderjapan.com/en/blog/social-media/korean-social-media-2025-trends-strategies/)
- [Matcha goes mainstream with Gen Z | Korea Herald](https://www.koreaherald.com/article/10524615)
- [Matcha is Back and Trending in Korea | KoreaTravelPost](https://koreatravelpost.com/matcha-is-back-and-trending-in-south-korea/)
- [AdMob eCPM Benchmarks | Playwire](https://www.playwire.com/blog/admob-ecpm-benchmarks-what-publishers-should-expect)
- 시장조사 [`market-research-kr.md`](../market-research-kr.md), [`market-research-jp.md`](../market-research-jp.md)

## 8. Changelog

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-04 | Accepted (KR 1순위 유지 + JP D0 동시 출시) | po-growth (제안), po-lead (사인오프 대기) |
