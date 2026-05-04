# Launch Plan — Sequence & GTM

> Owner: `po-growth` · Last updated: 2026-05-04 · 참조: `pm-go-to-market:gtm-strategy`, `pm-go-to-market:beachhead-segment`
>
> 6개국 출시 시퀀스 + 채널 + 메시징. 전체 일정은 v1.0.0 App Store 첫 출시 기준 ±90일. 정확한 날짜는 `po-lead`와 출시 게이트에서 확정.

## 1. 시퀀스 결정 (KR → JP → US → UK → DE → FR)

> **결정 ADR**: [ADR-PROD-003](decisions/ADR-PROD-003-beachhead-decision.md) (KR vs US 동률 해소 + 옵션 C APAC 듀얼) + [ADR-PROD-201](decisions/ADR-PROD-201-beachhead-kr-vs-jp.md) (KR vs JP 4축 정량 비교).
>
> 검증 가설: **H4** (KR D7 ≥ JP D7 + 5pp & KR ARPU ≥ JP ARPU × 0.7) — [backlog.md](decisions/backlog.md) 카드 본문 참조.

### 1.1 비치헤드 점수 정리

시장조사 §8 종합 점수 (5축 평균, `market-research-{cc}.md`):

| 순서 | 시장 | 비치헤드 점수 | 단계 |
|---|---|---|---|
| 1 | KR | 8.0 | Soft → Hard launch |
| 2 | JP | 7.2 | KR과 동시(soft), Hard 1주 지연 |
| 3 | US | 8.0 (수익) | KR/JP 안정 후 D+30 |
| 4 | UK | 7.6 | US와 동시 |
| 5 | DE | 6.4 | EU phase, D+60 |
| 6 | FR | 6.4 | DE와 동시 |

ADR-PROD-201은 KR vs JP를 *4축*(burning pain / WTP / winnable share / referral)으로 별도 정량 비교 → KR 8.50 vs JP 6.75 (KR 23pt% 우위). 두 점수 체계는 축 구성이 다르므로 *동일 시장 절대값 비교*는 의미가 없고, 각각 *시장 내 상대 우위* 신호로 사용.

### 1.2 그룹핑 전략

| 그룹 | 시장 | 일정 (D=v1.0.0 첫 release 빌드) |
|---|---|---|
| **APAC 비치헤드** | KR + JP | D-7 베타 → D0 출시 |
| **글로벌 매출** | US + UK | D+30 출시 |
| **EU 확장** | DE + FR | D+60 출시 |

같은 그룹은 *같은 빌드*로 공개. 그룹 간 간격(30일)은 데이터 수집과 카피/메타데이터 보강을 위함.

---

## 2. 단계별 게이트

### Phase 0: 출시 전 (D-30 ~ D-1)

- TestFlight 베타 (KR/JP 사용자 200명 + EN 사용자 50명).
- 메트릭 게이트: D7 retention ≥ 15%, 크래시율 ≤ 0.5%, ATT 옵트인 ≥ 30%.
- 출시 차단 트리거: 도감 등록률 < 15%, 평균 평점 < 4.0.

### Phase 1: APAC 비치헤드 (D0 ~ D+30)

- KR/JP App Store 출시.
- 광고 캠페인 *없음* (오가닉 검증).
- 인플루언서 시드 (KR 5명, JP 3명) — 마이크로 인플루언서 (5K-50K 팔로워).
- 데일리 모니터링: D1 retention, 도감 등록률, 광고 ARPU.

### Phase 2: 글로벌 매출 (D+30 ~ D+60)

- US + UK 출시.
- AdMob 슬롯 라이브 검증.
- Apple Search Ads 시작 (KR/JP 첫 30일 데이터 기반 키워드 매핑).
- 인플루언서 — US 마이크로 5명 (`@matcha.club`, `@nyc.matcha` 류).

### Phase 3: EU 확장 (D+60 ~ D+90)

- DE + FR 출시.
- 독일어/프랑스어 메타데이터 + ASO 키워드 보강.
- 베를린 비건 커뮤니티 + 파리 일본 빠띠스리 커뮤니티 시드.

### Phase 4: 데이터 검토 (D+90)

- KPI 검토 → 가설 검증 (PRD §4).
- v1.0.x 핫픽스 vs v1.1.0 (구독) 결정.

---

## 3. 채널별 GTM (시장 × 채널 매트릭스)

| 시장 | Inbound (콘텐츠/SEO) | Community (커뮤니티) | Paid (유료) | Influencer | PR |
|---|---|---|---|---|---|
| KR | Naver 블로그, 인스타 릴 | 다음카페 *말차이야기*, 트위터 매차러 | Apple Search Ads | 마이크로 인플루언서 5 | The Korea Herald 후속 보도 시도 |
| JP | はてなブログ, X/Twitter | TeaBu 커뮤니티, /r/matcha JP | Apple Search Ads (소액) | Tea Master 인플루언서 3 | matcha-jp.com 협업 |
| US | Reddit /r/matcha, TikTok | r/matcha, Discord 커뮤니티 | TikTok Ads + Search Ads | Cha Cha 단골/마이크로 5 | The Cut, Bon Appétit pitch |
| UK | TimeOut London 협업 | r/matcha UK, 차 인스타 그룹 | Search Ads | Tombo 단골/마이크로 3 | TimeOut, Vogue UK pitch |
| DE | HappyCow 노출, 비건 미디어 | r/Berlin, 비건 페북 그룹 | Search Ads (저액) | 비건 인플루언서 3 | Vegan.de 미디어 |
| FR | Sortiraparis 노출 | r/Paris, 일본 카페 페북 그룹 | Search Ads (저액) | parisselectbook 협업 | Le Figaro Madame pitch |

## 4. 메시징 (시장별 hero)

| 시장 | Hero 카피 | Sub | 핵심 가치 |
|---|---|---|---|
| KR | "전세계 말차, 한 번에 도감으로." | "여행 가서 발견한 말차 한 잔도 도감에 모아요." | 도감 + 여행 |
| JP | "本場の抹茶、世界中で。" | "宇治から東京、海外まで—一冊の抹茶図鑑。" | 본토 + 글로벌 |
| US | "Find. Sip. Collect." | "Every matcha you taste, saved as a card." | 도감 + 발견 |
| UK | "Your matcha journal, from Soho to Shibuya." | "Discover, sip, and collect every matcha." | 여행 + 일기 |
| DE | "Dein Matcha-Tagebuch — von Berlin bis Kyoto." | "Entdecke, genieße und sammle jeden Matcha." | 일기 + 다이어리 |
| FR | "Ton journal de matcha, de Paris à Kyoto." | "Découvre, savoure et collectionne chaque matcha." | 저널 + 여행 |

> 카피 톤은 `qa-localization`이 informal/formal 결정 후 String Catalog에 동기화 (Phase 4).

---

## 5. ASO 키워드 (시작 우선순위)

| 시장 | Top 5 키워드 |
|---|---|
| KR | 말차, 말차맵, 말차카페, 말차도감, 우지말차 |
| JP | 抹茶, 抹茶カフェ, 宇治抹茶, 抹茶マップ, 抹茶ラテ |
| US | matcha, matcha cafe, matcha map, matcha bar, ceremonial matcha |
| UK | matcha London, matcha cafe, japanese cafe, matcha bar, iced matcha |
| DE | Matcha, Matcha Café, Matcha Berlin, Matcha Latte, veganer Matcha |
| FR | matcha, café matcha, matcha Paris, pâtisserie japonaise, thé matcha |

## 6. 인플루언서 시드 풀 (예시·검증 필요)

| 시장 | 인플루언서 후보 | 팔로워 | 비고 |
|---|---|---|---|
| KR | `@maru_matcha`, `@cafe.matcha.kr` | 10K-80K | 마이크로 |
| JP | `@japanesematcha`, `@uji_matcha_lover` | 30K-100K | 노포 우호 |
| US | `@thematchaclub`, `@matcha.lover.nyc` | 20K-200K | 마이크로 |
| UK | `@londonmatcha`, `@matcha.in.london` | 15K-50K | 마이크로 |
| DE | `@vegan.berlin`, `@matchasome` | 30K+ | Matchasome 직접 협업 후보 |
| FR | `@parisselectbook`, `@umamiparis_official` | 20K+ | 매장 + 미디어 결합 |

> 위 핸들은 *후보 풀*로, 실제 컨택은 Phase 2-3에서 확정. 협업 비용은 무상/제품 협찬/유료 3단으로 분리.

## 7. 출시 캠페인 (글로벌 공통)

### 캠페인 1 — "100매 챌린지"

- 출시 후 30일간 도감 100매 달성 사용자에게 *한정 골드 뱃지* 부여.
- 인스타 #말차맵100 #MatchaMap100 해시태그 챌린지.
- 1등 한 명 우지 노포 디저트 세트 증정 (CAC < $50/획득 효과 기대).

### 캠페인 2 — "친구 도감 같이"

- 친구 1명 초대 → 양쪽 모두 *얼리 액세스 카드* 잠금 해제.
- 그룹 도감 메커닉 (그로스 루프 §2)과 동조.

### 캠페인 3 — "내 도시 베스트 5"

- 출시 후 14일간 매 도시별 베스트 5 매장을 자동 큐레이션 → 인스타 카드.
- 큐레이션 카드 자체가 SEO/오가닉 콘텐츠.

---

## 8. 리스크 / 대응

| 리스크 | 영향 | 대응 |
|---|---|---|
| Apple 심사 지연 | 일정 +14d | Phase 0에서 사전 심사 가이드 통과 검증 |
| 매장 데이터 부족 (특히 DE/FR) | UX 공백 | Google Places fallback + 사용자 등록 v1.1 |
| 광고 ARPU 미달 | 수익 모델 흔들림 | 구독 v1.1.0 가속 |
| 일본어 ASO 저효율 | JP 도달 부족 | 노포 협업 강화, JP 미디어 PR |
| GDPR/DSGVO 컴플라이언스 미흡 | EU 출시 차단 | UMP SDK 통합 (DE 출시 전 필수) |

## 9. 성공 지표 (출시 후 90일)

| 지표 | 목표 |
|---|---|
| 누적 다운로드 | 50K+ (KR 20K, JP 8K, US 12K, UK 5K, DE 3K, FR 2K) |
| MAU | 12K+ |
| D7 retention (글로벌) | ≥ 18% (PRD §4) |
| 평균 평점 | ≥ 4.3 |
| 광고 ARPU (글로벌) | ≥ $0.05/MAU |

## 10. 가설 매핑

본 launch-plan은 다음 [backlog.md](decisions/backlog.md) 가설 카드의 운영 근거가 된다:

| Hypothesis ID | 어떤 결정에 매핑되는가 |
|---|---|
| **H4** | §1.2 그룹핑 — KR/JP 동시 출시. 90일 후 H4 결과로 KR 비치헤드 가정 검증/재배분. |
| **H4'** | §3 Phase 2 (US D+30) — APAC 30일 데이터 보정 후 US 진입의 효과. |
| **H3** | §6 Phase 4 KPI ARPU 검증. 시장별 ARPU 표(monetization.md §3.4) → 글로벌 가중평균. |
| **H1** | §3 Phase 1·2 데일리 모니터링 — *travel_mode* 도감 등록률은 APAC + US 데이터로 1차 검증. |
| **H2** | §3 Phase 1 데일리 모니터링 — 친구 1+ retention. KR 인플루언서 시드가 친구 그래프 첫 시드. |
| **H5** | §7 캠페인 1·2 — 100매 챌린지 + "친구 도감 같이"가 H5(공유 루프)를 검증. |
| **H6** | §3 Phase 2 — Apple Search Ads CAC가 KR/JP 학습 키워드 적용으로 ≥ 20% 절감되는가. |

가설 결과 기록은 [`decisions/learnings/HC-202605-XXX.md`](decisions/learnings/) (D+30/60/90 시점 기록).

## 11. 출처 / 참조

- 6개 시장조사 문서 (`market-research-{kr,jp,us,uk,de,fr}.md`)
- [`icp.md`](icp.md), [`growth-loops.md`](growth-loops.md), [`monetization.md`](monetization.md)
- [`PRD.md`](PRD.md) §4, §7, §8
- [`decisions/ADR-PROD-001-hypothesis-framework.md`](decisions/ADR-PROD-001-hypothesis-framework.md), [`ADR-PROD-003`](decisions/ADR-PROD-003-beachhead-decision.md), [`ADR-PROD-201`](decisions/ADR-PROD-201-beachhead-kr-vs-jp.md)
