# PRD — 말차맵 (MatchaMap) v1.0.0

> 살아있는 문서. 변경 시 §11 changelog에 일자/요약/사인오프 기록.
> 본 PRD의 모든 정량 정의는 [decisions/ADR-PROD-001-hypothesis-framework.md](decisions/ADR-PROD-001-hypothesis-framework.md)의 공식 수식을 단일 진실 원천(SSOT)으로 인용한다.

## 1. 비전 한 줄

전세계 말차 덕후를 위한 발견 · 기록 · 도감 앱.

## 2. 목표 사용자 (ICP)

세부는 [icp.md](icp.md). MVP 핵심 페르소나(우선순위 순):

1. **여행자 매니아** — 출장/여행지에서 말차 카페 검색. JTBD = "낯선 도시에서 진짜 매장을 찾는다".
2. **로컬 도감러** — 자기 도시에서 시음한 말차를 카드로 모으고 싶다. JTBD = "수집욕".
3. **공유러** — 친구와 매장/리뷰 공유. JTBD = "내 발견을 자랑하고 싶다".

상세 인구통계·행동·지불의지·획득 채널은 `po-growth`가 [icp.md](icp.md)에 정의.

## 3. MVP 기능 (v1.0.0 범위)

| # | 모듈 | 기능 | 담당 |
|---|---|---|---|
| 1 | Onboarding | Splash, 가치제안, Apple/Passkey 로그인, 위치 권한 | `ios-auth-monetize` |
| 2 | Map | 전세계 지도, 도시 줌, 매장 핀, 미리보기, 클러스터링 | `ios-map` |
| 3 | Store | 매장 상세(소개/메뉴/리뷰), 검색, 필터 | `ios-store` |
| 4 | Review | 평점, 사진, 글, 태그 | `ios-store` |
| 5 | Collection | 도감 그리드, 메모리 페이지(등급/원산지/색감) | `ios-social-collection` |
| 6 | Social | 친구 피드, 좋아요/댓글 | `ios-social-collection` |
| 7 | Wishlist | 국가별 그룹, 미니 세계지도 | `ios-social-collection` |
| 8 | Profile | 내 정보, 통계, 설정 | `ios-social-collection` |
| 9 | Monetize | AdMob 배너/인터/보상, ATT | `ios-auth-monetize` |

## 4. 측정 지표 (출시 후 30일 목표)

> **공식 수식**은 [ADR-PROD-001 § 지표 정의](decisions/ADR-PROD-001-hypothesis-framework.md#지표-정의-prd-§4와-일치-조작-가능-정의) 참조. 본 표는 목표값만 요약한다.

| 지표 | 목표 | 단일 진실 원천 |
|---|---|---|
| D1 retention (시장 × locale × travel_mode 세그먼트별) | ≥ 35% (글로벌) | Firebase Analytics `session_start` |
| D7 retention | ≥ 18% (글로벌) | 동상 |
| 도감 등록률 (매장×사용자 쌍 단위, 7일 윈도우) | ≥ 30% 전체 / ≥ 50% travel_mode | `store_view` → `store_collection_added` |
| 친구 ≥ 1 사용자 비율 | ≥ 25% 월간 MAU | `friend_count` 첫 세션 스냅샷 |
| AdMob ARPU (글로벌) | ≥ $0.05 / MAU | AdMob 콘솔 결산 (월) |
| 평균 평점 (App Store) | ≥ 4.3 | App Store Connect (가중평균) |

가드레일(악화 시 ABORT):
- 크래시-프리 세션 ≥ 99.5%
- ATT 동의율 ≥ 35% (글로벌)
- ad_impression P95 인터스티셜 노출 빈도 ≤ 사용자당 1회/세션

## 5. 가설 (검증 대상)

가설 운영 규칙은 [ADR-PROD-001](decisions/ADR-PROD-001-hypothesis-framework.md)의 Hypothesis Card 형식 강제.

| ID | 가설 | 임계 | 기간 | 결정 |
|---|---|---|---|---|
| H1 | 여행 + 도감 = 강한 수집욕 | travel_mode=true 사용자의 도감 등록률 ≥ 50% | D+30 | SHIP/STOP/EXTEND |
| H2 | 친구 피드 = 리텐션 드라이버 | friend_count≥1 D7 ≥ friend_count=0 D7 × 2 | D+30 | 동상 |
| H3 | AdMob ARPU 글로벌 | ≥ $0.05/MAU (po-growth 추정 $0.10–$0.14, 보수적) | 1개월 | 미달 시 v1.1.0 구독 가속 |
| H4 | KR vs JP D7/ARPU | KR D7 ≥ JP D7 + 5pp & KR ARPU ≥ JP ARPU × 0.7 | D+30 | 미달 시 v1.1.0 JP 우선 강화 |
| H4' | APAC 비치헤드 → US 시차 출시 효과 | US D0(D+30) D7 ≥ 17% & ARPU ≥ $0.18/MAU | D+60 | ADR-PROD-003 옵션 C 검증 |
| H5 | 도감 공유 → 친구 가입 루프 | 카드 공유율 ≥ 25% & 외부 클릭→가입 ≥ 8% & 신규 중 공유 비중 ≥ 30% | D+30 | growth-loops 루프 1 검증 |
| H6 | KR/JP ASO → US ASA CAC 절감 | US ASA CAC ≤ 업계 벤치 × 0.8 | D+60 | ADR-PROD-003 옵션 C 사이드 효과 |

> H4는 PO 본인이 즉시 추가. CLAUDE.md에 "KR 우선" 명시되어 있으나 정량 근거가 약하다. po-growth가 `pm-go-to-market:beachhead-segment` 스킬로 4축 평가 후 확정 또는 반증 권장.

## 6. 비기능 요구

- **성능**: 도시 줌 P95 ≤ 600ms (시뮬레이터 + iPhone 17 실측 둘 다). 도감 그리드 250+ 항목 60fps 유지.
- **다국어**: ko / en-US / en-GB / de-DE / ja / fr-FR. String Catalog 빈 키 0(qa-localization 회귀).
- **접근성**: VoiceOver 모든 컨트롤 라벨, Dynamic Type 호환(XS~AX5), WCAG AA 컨트라스트.
- **개인정보**:
  - ATT 프롬프트는 첫 사용 60초 후(AdMob 슬롯 노출 직전이 아니라 충분한 가치 노출 이후 트리거).
  - 위치는 WhenInUse만. Always 요청 없음.
- **오프라인**: 마지막 캐시 표시 + 읽기 모드. 쓰기(리뷰/도감 추가)는 온라인 강제 + 큐잉 1단계는 v1.1.0.
- **신뢰성**: 크래시-프리 세션 ≥ 99.5%. Firebase Crashlytics + dSYM 자동 업로드(fastlane refresh_dsyms).

## 7. 출시 우선순위 (시장)

KR → JP → US → UK → DE → FR. (잠정 — `po-growth` 비치헤드 점수 기반)

| 순위 | 시장 | 비치헤드 점수 | 핵심 사유 (market-research-{시장}.md 참조) |
|---|---|---|---|
| 1 | KR | 8.0 | 모국어 운영 가능, 말차 카테고리 YoY 100%+, 인플루언서 글로벌 영향력 |
| 2 | JP | 7.2 | "본토 인증" 글로벌 신뢰도, KR과 묶어 동시 출시 권장 |
| 3 | US | 8.0 | iOS eCPM 최상($14.32 인터/$19.63 보상), 글로벌 매출 견인 |
| 4 | UK | 7.6 | iOS eCPM 2위, 영어 ASO + 유럽 게이트웨이 |
| 5 | DE | 6.4 | 비건/플랜트베이스 트렌드, 독일어 카피 길이 검증장 |
| 6 | FR | 6.4 | 일본 빠띠스리 결합, 파리 르마레 밀집 |

**해소(2026-05-04)**: KR(8.0)과 US(8.0) 동률은 [decisions/ADR-PROD-003-beachhead-decision.md](decisions/ADR-PROD-003-beachhead-decision.md)에서 **옵션 C(KR+JP 동시 → US+UK D+30 → DE+FR D+60) 채택**으로 해소. 가설 H4/H4'/H5는 §5 표에 등록.

상세 일정은 [launch-plan.md](launch-plan.md).

## 8. 수익화

상세 [monetization.md](monetization.md). MVP = AdMob 3슬롯(배너/인터/보상). 첫 60초 광고 차단(리텐션 보호). 유료 전환 트리거: H3 임계 미달 OR 광고 ARPU < $0.03 × 2개월 연속.

## 9. 비범위 (v1.0.0에 포함하지 않음)

- 매장 등록(사용자가 새 매장을 추가) — Google Place ID 의존, v1.1.0 검토.
- 다크 모드 — v1.1.0.
- iPad 전용 레이아웃 — 적응형으로 처리, 전용은 v1.2.0.
- 안드로이드 — 별도 트리거 후 시작.
- watchOS / macOS — 별도 트리거.
- RTL(아랍어/히브리어 등) — v1.0.0 6개 언어에 RTL 없음. v1.x 언어 확장 시 재논의.
- 오프라인 쓰기 큐 — v1.1.0.
- **친구 피드 Stories(24h 임시 콘텐츠) — v1.1.0**. 사유: 모더레이션 부담 + growth-loops 핵심 5루프에 비의존. designer-lead 보고(2026-05-04)에서 명시 결정.
- 보조 화면(설정 / 편집 / 친구 관리 / 알림 설정) — Phase 2-3 시안 검수 시점에 보강. v1.0.0 미니멈 출시 범위에서 핵심 흐름(Splash/Login/위치/Map/Store/Review/Collection/Feed/Wishlist/Profile) 13 화면 우선.

## 10. 의존성 (Open Items)

| ID | 항목 | 책임 | 마감 |
|---|---|---|---|
| D1 | Firestore 스키마 ADR-302 | server-data | Phase 2 (재할당) |
| D2 | App Check + 보안 규칙 ADR-303 | server-auth | Phase 2-3 (재할당) |
| D3 | Analytics 이벤트 스키마 (PRD §4 정의 충족) | server-lead | ✅ Phase 1 완료 (observability.md) |
| D4 | 디자인 시스템 + 9 모듈 시안 | designer-lead | ✅ Phase 1 완료 (design-system + components + handoff-mapping) |
| D5 | App Icon + Liquid Glass 변형 | designer-icon | ✅ Phase 1 완료 (B 채택, store-screenshots-spec 포함) |
| D6 | ICP/시장조사/수익화 상세 | po-growth | ✅ Phase 1 완료 (11 산출물) |
| D7 | iOS 모듈 경계 ADR-001/002 | ios-lead | Phase 2 (진행 중) |

## 11. Changelog

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-04 | 초안 작성 (16명 팀 셋업과 함께) | po-lead |
| 2026-05-04 | §4 지표를 ADR-PROD-001 공식 수식으로 강화. 가드레일 추가. H4(KR 비치헤드) 추가. §10 Open Items 추가. §6 비기능 가드 구체화. | po-lead |
| 2026-05-04 | §7 시퀀스를 ADR-PROD-003 옵션 C(3그룹 시차)로 확정. §5 가설 H4'/H5/H6 추가. §9 비범위에 Stories 24h + 보조 화면 명시. | po-lead |
| 2026-05-04 | §10 Open Items D3~D6 Phase 1 완료 표시. D1/D2 Phase 2 재할당. | po-lead |
