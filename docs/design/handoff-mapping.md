# Handoff Mapping (v2.html → SwiftUI)

> 정전(canon) 13개 화면을 SwiftUI View와 1:1 매핑한 표.
> 정전 파일: `_handoff/matchamap/project/MatchaMap v2.html` / `mm-shared-v2.jsx` / `mm-screens-v2.jsx`.
> SwiftUI 컴포넌트 정의는 `docs/design/components.md` 참조. 토큰은 `docs/design/design-system.md` 참조.

소유: `designer-lead` · 구현: `ios-{map,auth-monetize,store,social-collection}` · 검수: `qa-functional`.

---

## 0. Feature 모듈 분담 (요약)

| Feature | 담당 iOS | 화면 ID |
|---|---|---|
| FeatureBoot | `ios-lead` | 01 |
| FeatureAuth | `ios-auth-monetize` | 02 |
| FeatureMap | `ios-map` | 03, 04, 05, 06 |
| FeatureStore | `ios-store` | 07, 08, 09, 10 |
| FeatureSocial | `ios-social-collection` | 11 |
| FeatureCollection | `ios-social-collection` | 12 |
| FeatureProfile | `ios-social-collection` | 13 |

> 모듈 경계 충돌 방지: 한 화면은 한 worktree 안에서만 작업. `ios-lead`가 통합 검증.

---

## 1. 매핑표 (13 screens)

### 01 · Splash
- **v2 컴포넌트**: `Screen2Splash` (`mm-screens-v2.jsx` line 7–27)
- **SwiftUI View**: `SplashView` in `FeatureBoot`
- **사용 토큰**: bg `Color.MM.cream` / 로고 `Color.MM.deep` + `Color.MM.matchaSoft` / 헤드라인 `MMTypography.display` / mono "MATCHAMAP" + "EST. 2025 · KYOTO" `MMTypography.monoLabel` color `Color.MM.muted` / 부제 `MMTypography.body` color `Color.MM.text`
- **레이아웃**: 중앙 정렬 column, 로고 84×100 → 26pt gap → 헤드라인 → 8pt → mono → 26pt → 부제(maxWidth 280). 하단 50pt absolute mono.
- **주의**:
  - "말차맵" 로고는 SVG 1개 자산 (`designer-icon` 책임). PDF/SVG vector로 `Symbols/logo-mark.svg` 납품.
  - Splash 시간 = 앱 부팅 + Firebase 초기화. 최소 1.2s, 최대 2.5s. `ios-lead` ADR 결정.
  - 다국어: "세상의 말차를 한 잔씩 모아두는 곳" → en "A cup of matcha from every corner of the world" 등. 강제 줄바꿈은 String Catalog의 `\n`로.

### 02 · Login (Apple / Passkey)
- **v2 컴포넌트**: `Screen2Login` (line 32–96)
- **SwiftUI View**: `LoginView` in `FeatureAuth`
- **하위 컴포넌트**: `PrimaryButton(.fullWidth, leadingIcon:"apple")` × Apple 검정 / `SecondaryButton(.fullWidth)` × Passkey / `GhostButton` × 이메일 가입 / Passkey 안내 카드(custom)
- **사용 토큰**: bg `Color.MM.bg` / 헤드라인 `MMTypography.title1` `Color.MM.deep` / 부제 `MMTypography.body` `Color.MM.muted` / Apple 버튼 bg `Color.MM.appleBlack` / Passkey 버튼 border 1.5pt `Color.MM.deep` / 안내 카드 bg `Color.MM.matchaPale`, 아이콘 fill `Color.MM.matcha`, paper check / divider `Color.MM.line` + mono "OR" `Color.MM.muted`
- **주의**:
  - Apple Sign In 버튼 텍스트는 Apple HIG 준수: "Apple로 계속하기" / "Continue with Apple". 색·라운드 변경 금지(Apple 정책).
  - Passkey: iOS 16+ ASAuthorizationPlatformPublicKeyCredentialProvider 사용 (`ios-auth-monetize`).
  - 약관 / 개인정보 링크: 텍스트 일부 underlined deep — `AttributedString` SwiftUI 사용.
  - 다국어 길이: "Apple로 계속하기" → de "Mit Apple fortfahren" 약 18글자 OK. "패스키로 계속하기" → fr "Continuer avec une clé d'accès" 약 30글자 — height 56 단일행에 fit하는지 회귀.

### 03 · Location 권한 (Lottie)
- **v2 컴포넌트**: `Screen2Location` (line 101–126)
- **SwiftUI View**: `LocationPermissionView` in `FeatureMap`
- **하위 컴포넌트**: `IconButton(.glass)` back / `LottieView(name:"matcha-leaf-rotate")` (`designer-icon` 자산) / `PrimaryButton(.fullWidth)` 위치 허용 / `GhostButton` 나중에
- **사용 토큰**: bg `Color.MM.bg` / 진행 표시 "2 / 2" `MMTypography.monoLabel` `Color.MM.muted` / 헤드라인 `MMTypography.title2` `Color.MM.deep` / 부제 `MMTypography.body` `Color.MM.muted` (maxWidth 280)
- **주의**:
  - Lottie 자산 미준비 시 `LottiePlaceholder` (점선 회전 링) 임시 사용.
  - 권한 요청 다이얼로그는 `CLLocationManager.requestWhenInUseAuthorization` — 시스템 다이얼로그가 위에 떠야 함. 기본 시스템 다이얼로그 한국어/영어/독어/불어/일본어 OS 설정 따라감.
  - 거부 시 fallback: 수동 도시 선택 화면(추가 ADR 필요).

### 04 · 전세계 지도
- **v2 컴포넌트**: `Screen2MapWorld` (line 131–175)
- **SwiftUI View**: `MapWorldView` in `FeatureMap`
- **하위 컴포넌트**: `WorldMap2` (placeholder → GMSMapView world camera) / `SearchField(.floating)` / `Chip` row (전체/일본/한국/미국/유럽) / `MatchaPin` 8개 + cluster 1개 / `StatHero` (지금 이 순간 banner) / `TabBar2(.map)`
- **사용 토큰**: bg `Color.MM.bg` (실 지도는 GMS) / cluster bg `Color.MM.matcha` paper border / banner bg `Color.MM.paper` shadow `MMShadow.large` / mono "지금 이 순간" `Color.MM.rose` / 통계 숫자 `MMTypography.statNumber` `Color.MM.deep` / 통계 라벨 `MMTypography.caption` `Color.MM.muted`
- **주의**:
  - 실제 GMSMapView styling JSON은 `ios-map`이 본 매핑의 `CityMap2` 색을 참고하여 작성.
  - "지금 이 순간" 텍스트의 1,847개 등 숫자는 Cloud Functions endpoint에서 로드 (5분 캐시) — `server-functions` API 계약 필요.
  - 클러스터 임계값(247): 줌 레벨별 클러스터 룰은 `ios-map` ADR.
  - 마커는 PNG raster (등급×사이즈 12개) — `designer-icon` 책임.

### 05 · 도시 줌
- **v2 컴포넌트**: `Screen2MapCity` (line 180–240)
- **SwiftUI View**: `MapCityView` in `FeatureMap`
- **하위 컴포넌트**: `CityMap2` (GMS 실맵) / 헤더 mini search bar (`back + 도시명 + 매장수`) / `Chip` 4개(정렬/등급/영업중/우스차) / `IconButton(.surface)` zoom-in / world-pin / compass 3개 / `StoreCard(.horizontal)` carousel
- **사용 토큰**: 헤더 `Color.MM.paper` shadow `MMShadow.medium` / 도시명 `MMTypography.subhead` weight 500 `Color.MM.deep` / 매장수 mono `Color.MM.muted` / 컨트롤 버튼 40×40 `Color.MM.paper` shadow / carousel 카드 width 280 shadow `MMShadow.medium`
- **주의**:
  - GMS 카메라 줌레벨 14~16에서 도시 줌. 도시 라벨(YOYOGI PARK 등)은 GMS 자체 라벨 사용 (커스텀 styling JSON에서 표시).
  - carousel은 `ScrollView(.horizontal)` + `.scrollTargetBehavior(.viewAligned)` (iOS 17+, 본 프로젝트 26.2 OK).
  - 도시 검색: 처음 매핑 시 OpenStreetMap reverse-geocode → 향후 Google Places. `server-functions` 결정.

### 06 · 매장 미리보기 (지도 위 카드)
- **v2 컴포넌트**: `Screen2MapPreview` (line 245–292)
- **SwiftUI View**: `MapStorePreviewSheet` in `FeatureMap`
- **하위 컴포넌트**: `Sheet(detent:.medium)` 또는 floating `StoreCard(.floating)` / 매장 이름 헤더 / `PrimaryButton(leadingIcon:"compass")` 길찾기 / `IconButton(.surface)` phone
- **사용 토큰**: 카드 `Color.MM.paper` radius `MMRadius.xxxl` shadow `MMShadow.float` / 매장명 `MMTypography.headline` `Color.MM.deep` / 가격대 mono `MMTypography.monoLabel` `Color.MM.muted` / 영업 `Color.MM.matcha` weight 600 / 길찾기 시간 표기 ("14분") `MMTypography.subhead`
- **주의**:
  - 핀 탭 → preview 등장: `MMMotion.spring`.
  - 길찾기 버튼: Apple Maps deeplink (`maps://?daddr=...`) 또는 Google Maps app fallback. `ios-map` ADR.
  - hero photo 150pt — Google Places photo URL 또는 사용자 업로드. `Data` 모듈 책임.

### 07 · 매장 상세
- **v2 컴포넌트**: `Screen2StoreDetail` (line 297–385)
- **SwiftUI View**: `StoreDetailView` in `FeatureStore`
- **하위 컴포넌트**: hero photo 240pt + gradient overlay / `IconButton(.glass)` back+share+bookmark / 매장명 + 평점 / quick action grid 4×1 (길찾기/전화/웹사이트/공유) / 탭(소개/메뉴/리뷰) / 매장 소개 본문 / mini-map 카드 / 영업시간 카드 / attributes grid 2×3
- **사용 토큰**: hero gradient `Color.black @ 30% → transparent → Color.MM.bg @ 100%` / quick action grid bg `Color.MM.paper` border `Color.MM.line` / 강조 grid 1번째: bg `Color.MM.deep` paper / 탭 active: weight 700 `Color.MM.deep` underline 2pt / mini-map: photo 60×60 + `MatchaPin(20, .S)` / attribute pill: bg `Color.MM.paper` border `Color.MM.lineSoft`
- **주의**:
  - hero photo는 47장 캐러셀 placeholder. 실제는 Google Places photos 첫 1장 + 사용자 업로드.
  - 영업시간 expand: chevron-down → 7일치 표시. `DisclosureGroup` 스타일링 커스텀.
  - 탭 전환은 `ScrollViewReader` + horizontal swipe 가능. 깊은 페이지 스크롤은 lazy.
  - 6개 언어: 매장명은 다국어 표기(JP 한자 + 한글/영문 transliteration). `qa-localization` 회귀.
  - mini-map 안의 `CityMap2`는 60×60 thumb로 GMS 캡처 또는 정적 PNG.

### 08 · 리뷰 탭
- **v2 컴포넌트**: `Screen2Reviews` (line 390–461)
- **SwiftUI View**: `StoreReviewsView` in `FeatureStore`
- **하위 컴포넌트**: 헤더(back + 매장명 + edit) / rating summary (4.8 + 분포 막대) / Chip 4개(전체/사진/5점/친구) / `ReviewCard` 리스트 / FAB 리뷰 작성 (edit icon)
- **사용 토큰**: rating 큰 숫자 `Noto Serif KR 44pt` `Color.MM.deep` / 분포 막대 bg `Color.MM.lineSoft` fill `Color.MM.matcha` / 분포 % mono / Chip count 라벨 mono opacity 0.6
- **주의**:
  - 분포 데이터: Firestore aggregation 필드. `server-data` 스키마 ADR.
  - 사용자별 친구 리뷰 필터: 본인 follow 그래프 조인 — `server-functions` callable 필요.
  - 무한 스크롤: 20개 paging.

### 09 · 검색 결과
- **v2 컴포넌트**: `Screen2Search` (line 466–516)
- **SwiftUI View**: `SearchResultsView` in `FeatureStore`
- **하위 컴포넌트**: 헤더(back + `SearchField(.inline)` + filter) / Chip 4개(전체/매장/메뉴/리뷰) / mono header "매장 24곳 · 거리순" / `StoreCard(.listRow)` 리스트 + bookmark IconButton / `TabBar2(.map)`
- **사용 토큰**: 거리 mono `Color.MM.rose` weight 600 / 평점 `Color.MM.deep` / count `Color.MM.muted`
- **주의**:
  - 매장 검색 backend: Algolia or Firestore + Cloud Functions. MVP는 Firestore where + array-contains. `server-functions` ADR.
  - 정렬 기준 단일 (거리순) 시작, 추후 점수/리뷰수.
  - 빈 상태 화면 별도 디자인 필요(`designer-lead` 팔로업 v1.1).

### 10 · 리뷰 작성
- **v2 컴포넌트**: `Screen2ReviewWrite` (line 521–584)
- **SwiftUI View**: `ReviewWriteView` in `FeatureStore`
- **하위 컴포넌트**: 헤더(close + 제목 + `PrimaryButton(.compact)` 등록) / 매장 row mini-card / 별점 입력 (5 large stars + 텍스트 "완벽해요!") / 사진 업로드 grid (3 + add) / `TagSelector` (선택 가능 태그) / `ReviewTextEditor`
- **사용 토큰**: 매장 row bg `Color.MM.paper` border `Color.MM.lineSoft` / 별점 36pt `Color.MM.gold` / 텍스트 입력 bg paper border lineSoft / 태그 selected matchaPale border matchaSoft `Color.MM.deep`
- **주의**:
  - 별점 0.5 단위 입력 가능 여부: MVP는 정수만(시안 일치). 추후 0.5.
  - 사진 max 9. 첫 9장은 in-memory, 등록 시 Firebase Storage 업로드. `server-auth` Storage rules + `ios-store` 업로드 로직.
  - "완벽해요!" 등의 별점 → 카피 매핑 5단계 사전: `qa-localization` 6개 언어 매핑.
  - 등록 disabled 상태: 별점 0 + 본문 0자. validation은 client + Cloud Function.

### 11 · 친구 피드
- **v2 컴포넌트**: `Screen2Feed` (line 589–663)
- **SwiftUI View**: `FeedView` in `FeatureSocial`
- **하위 컴포넌트**: 헤더("피드" `MMTypography.headline` + search/bell IconButton) / Stories row (6 avatars, gradient ring) / `FeedPostCard` 리스트 / `TabBar2(.feed)`
- **사용 토큰**: stories ring `LinearGradient(matcha → rose)` / "내" plus avatar `Color.MM.deep` paper border / heart fill `Color.MM.rose` 활성 / post body `MMTypography.callout`
- **주의**:
  - Stories: 24h 만료 메타데이터(`server-data` 스키마). MVP에서 우선순위 낮으면 v1.1로 이동 — `po-lead` 결정 필요.
  - 무한 스크롤 + pull-to-refresh.
  - 사진 photo height 300 — full bleed (수평 padding 무시): `.padding(.horizontal, -16)` 패턴.
  - 광고 슬롯: 매 5번째 post 사이 native ad. `po-growth` 합의 후 추가.

### 12 · 위시리스트 (국가별 그룹)
- **v2 컴포넌트**: `Screen2Wishlist` (line 668–769)
- **SwiftUI View**: `WishlistView` in `FeatureCollection`
- **하위 컴포넌트**: 헤더("위시리스트" + grid/map view toggle IconButton) / mini world map (`WorldMap2` height 160 + small `MatchaPin`s) / Country `Chip` row / `ContentSection` 지역별 그룹 (TOKYO / KYOTO / OSAKA …) / 각 row: photo 56 + grade + 이름 + 메모(rose italic) + bookmark-fill / `TabBar2(.wish)`
- **사용 토큰**: mini map "28 PINS" badge bg `Color.MM.paper @ 95%` mono `Color.MM.deep` / region label mono `Color.MM.muted` letterSpacing 0.2em / 메모 `MMTypography.caption` italic `Color.MM.rose` / region count `MMTypography.footnote` weight 600 `Color.MM.deep`
- **주의**:
  - 국가 → 지역 grouping은 client 사이드 (`country.region` 메타). Firestore에 `country` (ISO) + `region` (text) 필드 필수 — `server-data`.
  - view toggle: list/grid/map 3가지. MVP는 list+map만, grid는 v1.1.
  - "다음 도쿄 갈때" 같은 메모는 `Color.MM.rose` italic — `qa-localization`이 italic 사용 가능 폰트인지 검증.
  - 빈 상태 + 친구 추천 위시 가져오기 화면: 별도 디자인 필요(팔로업).

### 13 · 프로필 (My matcha journey)
- **v2 컴포넌트**: `Screen2Profile` (line 774–end)
- **SwiftUI View**: `ProfileView` in `FeatureCollection`
- **하위 컴포넌트**: 헤더("내 정보" + settings IconButton) / Avatar(64, .gradient ring) + 이름/핸들/팔로우 / `SecondaryButton(.compact)` 편집 / `StatHero` 4 stats (마신 잔/방문 매장/국가/리뷰) / "최근 마신 말차" 섹션 + horizontal carousel 130×130 photos / 메뉴 리스트 (위시리스트/내 리뷰/친구/알림 설정 …) / `TabBar2(.me)`
- **사용 토큰**: stat 라벨 mono `Color.MM.rose` / stat 숫자 `MMTypography.statNumber` `Color.MM.deep` / "전체 →" `MMTypography.footnote` `Color.MM.rose` / 메뉴 리스트 bg `Color.MM.paper` border `Color.MM.lineSoft`
- **주의**:
  - "교토 출신" 등 사용자 prop은 옵션. 빈 값일 때 노출 정책 → `po-lead` 결정.
  - 도감(잠금 해제) 영역은 시안 미포함. v1.0에서는 메뉴 링크로만 접근 (보상형 광고 unlock).
  - 편집 화면, 설정 화면, 친구 화면, 알림 설정 화면은 시안 미준비 — Phase 2 디자인 팔로업.

---

## 2. 화면별 광고 슬롯 매핑 (`po-growth` 합의 후 확정)

| 화면 ID | 슬롯 | 타입 | 노출 룰 |
|---|---|---|---|
| 04 (지도) | TabBar 위 320×50 | 배너 | 첫 60s 차단, 매장 핀 6개 이상 표시 시만 |
| 07 (매장 상세) | 진입 인터셉트 | 인터스티셜 | 5번째 진입마다 + 60s gap |
| 12 (위시리스트) | 도감 잠금 해제 시 | 보상형 | 사용자 자발 |
| 11 (피드) | 매 5 post 사이 native | 네이티브 | (옵션) v1.1 |

→ `designer-lead` 가 `po-growth` 에 위 표 검토 요청 (별도 `SendMessage`).

---

## 3. 픽셀-퍼펙트 검수 체크리스트 (`qa-functional`용)

각 화면 빌드 후 검수 시 확인:

1. **Color**: 화면에서 사용된 모든 색이 `Color.MM.*` 토큰? (정전 hex 값과 ±0 일치)
2. **Spacing**: padding / gap이 `MMSpacing.*` (4/8/12/16/20/24/32/48) 8-grid 일치?
3. **Radius**: corner radius가 `MMRadius.*` 토큰?
4. **Typography**: font / size / weight / letterSpacing이 `MMTypography.*`?
5. **Shadow**: 그림자가 `MMShadow.*`?
6. **Icons**: SF Symbols 사용 0건? `Symbols/*.svg` 자산만?
7. **다국어**: ko/en/de/ja/fr 5개 가장 긴 카피 적용 시 줄넘침 / 잘림 없음?
8. **Dynamic Type**: Largest Accessibility 5단계에서 레이아웃 크래시 없음?
9. **WCAG AA**: 텍스트 색대비 통과? (design-system § 1.8 제약 준수?)
10. **광고 슬롯**: 첫 60s 차단 작동? 인터스티셜 빈도 정책 준수?

→ 검수 실패 시 `designer-lead`에 `SendMessage`로 보고. PR 차단.

---

## 4. 변경 이력

| 일자 | 변경 | 사유 |
|---|---|---|
| 2026-05-04 | 최초 작성 (13 screens 1차 매핑) | Phase 1 핸드오프 매핑 |

---

References:
- 정전: `_handoff/matchamap/project/MatchaMap v2.html` + `mm-shared-v2.jsx` + `mm-screens-v2.jsx` (line 번호는 본 문서 작성 시점 기준)
- 사이드: `docs/design/design-system.md` / `docs/design/components.md`
- 분담 ADR: `docs/architecture/` (작성 예정 by `ios-lead`)
