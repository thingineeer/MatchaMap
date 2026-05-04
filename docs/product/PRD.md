# PRD — 말차맵 (MatchaMap) v1.0.0

> 살아있는 문서. 변경 시 changelog 섹션에 일자/요약/사인오프 기록.

## 1. 비전 한 줄

전세계 말차 덕후를 위한 발견 · 기록 · 도감 앱.

## 2. 목표 사용자 (ICP)

세부는 [icp.md](icp.md). MVP 핵심 페르소나:
- **여행자 매니아**: 출장/여행지에서 말차 카페 검색. JTBD = "낯선 도시에서 진짜 매장을 찾는다".
- **로컬 도감러**: 자기 도시에서 시음한 말차를 카드로 모으고 싶다. JTBD = "수집욕".
- **공유러**: 친구와 매장/리뷰 공유. JTBD = "내 발견을 자랑하고 싶다".

## 3. MVP 기능 (v1.0.0 범위)

| # | 모듈 | 기능 | 담당 |
|---|---|---|---|
| 1 | Onboarding | Splash, 가치제안, Apple/Passkey 로그인, 위치 권한 | `ios-auth-monetize` |
| 2 | Map | 전세계 지도, 도시 줌, 매장 핀, 미리보기 | `ios-map` |
| 3 | Store | 매장 상세(소개/메뉴/리뷰), 검색, 필터 | `ios-store` |
| 4 | Review | 평점, 사진, 글, 태그 | `ios-store` |
| 5 | Collection | 도감 그리드, 메모리 페이지(등급/원산지/색감) | `ios-social-collection` |
| 6 | Social | 친구 피드, 좋아요/댓글 | `ios-social-collection` |
| 7 | Wishlist | 국가별 그룹, 미니 세계지도 | `ios-social-collection` |
| 8 | Profile | 내 정보, 통계, 설정 | `ios-social-collection` |
| 9 | Monetize | AdMob 배너/인터/보상, ATT | `ios-auth-monetize` |

## 4. 측정 지표 (출시 후 30일)

| 지표 | 목표 |
|---|---|
| D1 retention | 35% |
| D7 retention | 18% |
| 도감 등록률 (방문→등록) | 30% |
| 친구 1+ 사용자 비율 | 25% |
| AdMob ARPU (글로벌) | $0.05/MAU |
| 평균 평점 (App Store) | ≥ 4.3 |

## 5. 가설 → 검증

자세한 표는 [decisions/](decisions/). 핵심:
1. **여행 + 도감 = 강한 수집욕** → 여행 모드(해외 위치) 사용자의 도감 등록률 ≥ 50%.
2. **친구 피드 = 리텐션** → 친구 ≥ 1명 D7 retention ≥ 비친구의 2배.
3. **AdMob ARPU ≥ $0.05** → 미달 시 v1.1.0에서 구독 우선화.

## 6. 비기능 요구

- **성능**: 도시 줌 P95 ≤ 600ms. 도감 그리드 250+ 항목까지 60fps.
- **다국어**: ko / en-US / en-GB / de-DE / ja / fr-FR. 빈 키 0.
- **접근성**: VoiceOver 모든 컨트롤 라벨, Dynamic Type 호환, WCAG AA 컨트라스트.
- **개인정보**: ATT 프롬프트는 첫 사용 60초 후. 위치는 WhenInUse만.
- **오프라인**: 마지막 캐시 표시 + 읽기 모드.

## 7. 출시 우선순위 (시장)

KR → JP → US → UK → DE → FR. 자세한 [launch-plan.md](launch-plan.md).

## 8. 수익화

상세 [monetization.md](monetization.md). MVP = AdMob 3슬롯. 첫 60초 광고 차단(리텐션 보호).

## 9. 비범위 (v1.0.0에 포함하지 않음)

- 매장 등록(사용자가 새 매장을 추가) — Google Place ID 의존, v1.1.0 검토.
- 다크 모드 — v1.1.0.
- iPad 전용 레이아웃 — 적응형으로 처리, 전용은 v1.2.0.
- 안드로이드 — 별도 트리거 후 시작.
- watchOS / macOS — 별도 트리거.

## 10. Changelog

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-04 | 초안 작성 (16명 팀 셋업과 함께) | po-lead |
