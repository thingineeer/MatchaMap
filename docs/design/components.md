# MatchaMap Component Catalog (MM2)

> 정전(canon): `_handoff/matchamap/project/mm-shared-v2.jsx` + `mm-screens-v2.jsx`. 본 카탈로그는 SwiftUI 구현 시 1:1 참조 가이드.
> 모든 색상은 `Color.MM.*` 토큰. 색상 리터럴 절대 금지.

소유: `designer-lead` · 아이콘 자산: `designer-icon` · 구현: `ios-lead` 위임.

---

## 0. SwiftUI 모듈 위치 (제안)

```
LocalPackages/DesignSystem/Sources/Components/
├── Frame/
│   ├── Phone2.swift              (디자인 카탈로그 전용 — 앱에서는 제거)
│   ├── StatusBar2.swift          (디자인 검수용 placeholder, 실제는 시스템 status bar 사용)
│   ├── HomeIndicator2.swift      (디자인 검수용 placeholder)
│   └── TabBar2.swift             (실제 사용됨)
├── Map/
│   ├── CityMap2.swift            (실제 Google Maps SDK 위 placeholder, ios-map 책임)
│   ├── WorldMap2.swift           (위시리스트 헤더 미니 월드맵)
│   └── MatchaPin.swift           (실제 GMS marker로 변환 — ios-map 책임)
├── Card/
│   ├── StoreCard.swift           (검색 결과, 매장 미리보기)
│   ├── ReviewCard.swift          (리뷰 탭)
│   └── FeedPostCard.swift        (피드)
├── Atom/
│   ├── GradeChip.swift
│   ├── Stars.swift
│   ├── Photo.swift               (placeholder, 실 이미지 로딩은 Data 모듈)
│   ├── CountryFlag.swift
│   ├── Chip.swift                (filter / sort / category)
│   └── Avatar.swift
├── Input/
│   ├── SearchField.swift
│   ├── ReviewTextEditor.swift
│   └── TagSelector.swift
└── Button/
    ├── PrimaryButton.swift
    ├── SecondaryButton.swift
    ├── GhostButton.swift
    ├── IconButton.swift          (라운드 버튼, 36×36)
    └── FloatingActionButton.swift
```

---

## 1. Frame Components

### 1.1 `Phone2`

**정전 위치**: `mm-shared-v2.jsx` line 50–54.

| Prop | 타입 | 기본값 | 비고 |
|---|---|---|---|
| `width` | CGFloat | 390 | 디자인 카탈로그 전용. 앱에서는 `.infinity` |
| `height` | CGFloat | 844 | 디자인 카탈로그 전용 |
| `bg` | Color | `.MM.bg` | 화면 배경 |
| `content` | () -> View | — | 본문 |

**용도**: 디자인 검수(Storybook 격) 전용 외곽 프레임. **앱 빌드에 포함하지 않음** — `#if DEBUG` 또는 별도 PreviewModule.

### 1.2 `StatusBar2`

**정전 위치**: `mm-shared-v2.jsx` line 31–42.

| Prop | 타입 | 기본값 |
|---|---|---|
| `dark` | Bool | false |
| `time` | String | "9:41" |

**구현 메모**: 실제 앱에서는 시스템 상태바 사용. 본 컴포넌트는 카탈로그 placeholder로만 유지 (높이 54, padding 18/28/6/28).

### 1.3 `HomeIndicator2`

**정전 위치**: `mm-shared-v2.jsx` line 44–48.

| Prop | 타입 | 기본값 |
|---|---|---|
| `dark` | Bool | false |

**구현 메모**: 시스템 home indicator 사용. 카탈로그 전용.

### 1.4 `TabBar2`

**정전 위치**: `mm-shared-v2.jsx` line 57–77.

| Prop | 타입 | 기본값 | 비고 |
|---|---|---|---|
| `active` | enum {map, feed, wish, me} | `.map` | 활성 탭 |
| `onSelect` | (Tab) -> Void | — | 탭 변경 핸들러 |

**스펙**:
- 위치: 화면 하단 absolute. `Color.MM.paper` opacity 96% + `.ultraThinMaterial`.
- top border: 0.5px `Color.MM.lineSoft`.
- padding: 8 / 12 / 28 / 12 (top/right/bottom/left).
- 4탭 균등 분포 (`flex: 1`).
- 아이콘 22pt + 라벨 10pt, 간격 3pt.
- 활성: 색 `Color.MM.deep`, 두께 stroke 2.0, 라벨 weight 600.
- 비활성: 색 `Color.MM.muted`, 두께 stroke 1.5, 라벨 weight 500.
- bookmark 아이콘은 활성 시 `bookmark-fill`.

**탭 정의**: 지도(map) · 피드(users) · 위시리스트(bookmark) · 내정보(user). 라벨/탭 다국어는 design-system § 7.2 참조.

---

## 2. Map Components

### 2.1 `CityMap2`

**정전 위치**: `mm-shared-v2.jsx` line 80–99.

도시 줌 단계의 화이트톤 placeholder. 실제 앱에서는 Google Maps SDK 카메라 위에 오버레이로만 사용. `ios-map` 책임으로 GMSMapView styling JSON으로 분리 변환.

| Prop | 비고 |
|---|---|
| `children` | 위에 얹을 핀 / 마커 / 레이블 |

**색 매핑** (Google Map style JSON으로):
- `geometry.fill` 도로: `#FBF9F3` (paper 약간 어둡게)
- `landscape.natural`: `#F6F3EB`
- `poi.park`: `#DDE6CF` (matchaPale 더 푸른)
- `water`: `#E3EAE5`
- `landscape.man_made`: `#EDE8D9`

### 2.2 `WorldMap2`

**정전 위치**: `mm-shared-v2.jsx` line 102–120.

전세계 지도 SVG placeholder + 위시리스트 헤더 미니맵. **두 위치에서 재사용**(map world / wishlist mini). MVP에서는 SVG를 그대로 SwiftUI Path로 옮기고, 추후 GMSMap world view로 대체.

### 2.3 `MatchaPin`

**정전 위치**: `mm-shared-v2.jsx` line 123–140 (v2 = `MatchaPin2`).

| Prop | 타입 | 기본값 |
|---|---|---|
| `size` | CGFloat | 36 |
| `grade` | enum {S, A, B, C} | .S |
| `glow` | Bool | false |

**스펙**:
- 비율: width=size, height=size×1.2.
- drop shadow: `MMShadow.pin` (deep @ 18%, radius 6, y 3).
- 등급별 색: design-system § 1.7 참조.
- glow=true: 1.4× pulse — **지도 진입 후 15초만 무한 → 이후 정지** (po-lead 결정 2026-05-04). 사유: 상시 무한 glow는 (a) 전력 소비 (b) 시각 피로 (c) 인터스티셜 광고와 충돌. 15초는 "신규 사용자 시선 유도" 목적 충족 + 그 이후 정적 표시. 구현: 지도 화면 onAppear 시 15초 타이머 start, expire 시 `MMMotion.pulse` 정지. Phase 2 ios-map ADR로 최종 결정.
- Reduce Motion 활성 시: 무조건 정지 (15초 카운트도 무시).

**variants**: 지도 마커는 사이즈 14~48 동적. 가까울수록 큼.

**구현 메모**: 실제 GMS marker는 `iconView` 또는 PNG raster로 미리 렌더링. `designer-icon`이 4등급 × 3사이즈(small/md/lg) PNG 12개 자산 책임.

---

## 3. Atom Components

### 3.1 `GradeChip`

**정전 위치**: `mm-shared-v2.jsx` line 143–155.

| Prop | 타입 | 기본값 |
|---|---|---|
| `grade` | enum {S,A,B,C} | .S |
| `size` | enum {sm, md, lg} | .md |

**dimension** (sm/md/lg): 20/24/32 sq, 글자 10/11/14pt, IBM Plex Mono Medium.

**색 매핑**: design-system § 1.7.

### 3.2 `Stars`

**정전 위치**: `mm-shared.jsx` line 125–136.

| Prop | 타입 | 기본값 |
|---|---|---|
| `value` | Double | 4.5 |
| `size` | CGFloat | 12 |

**스펙**: 5 stars, fill `Color.MM.gold`, empty `Color.MM.line`. half star: full 처리(시안과 동일 — 0.5 ≤ frac → full).

### 3.3 `Photo` (placeholder)

**정전 위치**: `mm-shared.jsx` line 139~.

| Prop | 타입 | 기본값 |
|---|---|---|
| `width` | CGFloat | .infinity |
| `height` | CGFloat | 200 |
| `tone` | enum {warm, cool, matcha, deep, cream} | .warm |
| `radius` | CGFloat | 0 |
| `label` | String? | "PHOTO" |

**용도**: 이미지 로딩 전 placeholder + 디자인 카탈로그 데모. 실 이미지는 `AsyncImage` + `redacted(reason: .placeholder)` 패턴, `Data` 모듈에서 처리.

### 3.4 `CountryFlag`

**정전 위치**: `mm-shared-v2.jsx` line 174–179.

| Prop | 타입 | 기본값 |
|---|---|---|
| `code` | String (ISO 3166-1 alpha-2) | "jp" |
| `size` | CGFloat | 18 |

**구현**: 시안은 emoji 사용. 정식 출시 시 SVG 자산으로 교체(국가별 flag set 약 30개 예상). `designer-icon` 책임.

### 3.5 `Chip` (Filter / Sort / Category)

**정전 위치**: 다양 (`Screen2MapWorld` line 142, `Screen2MapCity` line 202, `Screen2Search` line 480, `Screen2Wishlist` line 700).

| Prop | 타입 | 기본값 |
|---|---|---|
| `label` | String | — |
| `count` | Int? | nil |
| `leadingIcon` | String? | nil |
| `trailingFlag` | CountryCode? | nil |
| `selected` | Bool | false |
| `style` | enum {primary, surface, ghost} | .surface |

**스펙**:
- height: 28 (padding 6/12 V/H) / 30 (padding 7/12) / 34 (padding 7/14).
- radius: 14~20 (`MMRadius.xl` 또는 pill).
- selected primary: bg `Color.MM.deep`, fg `Color.MM.paper`, weight 600.
- selected surface: bg `Color.MM.matchaPale`, fg `Color.MM.deep`, border `Color.MM.matchaSoft`, ✓ prefix.
- unselected: bg `Color.MM.paper`, fg `Color.MM.text`, border `Color.MM.line`.

**count suffix**: opacity 0.6, IBM Plex Mono.

### 3.6 `Avatar`

**정전 위치**: `Screen2Reviews` line 440, `Screen2Feed` line 630, `Screen2Profile` line 782.

| Prop | 타입 | 기본값 |
|---|---|---|
| `initial` | String (1글자) | — |
| `size` | CGFloat | 32 |
| `tint` | Color | `.MM.matcha` |
| `ringStyle` | enum {none, story, gradient} | .none |
| `imageURL` | URL? | nil |

**variants**:
- profile (size 64): `LinearGradient(matcha → rose)` 2pt ring + cream inner.
- story (size 56): 동일 그라디언트 ring, 2pt 내부 padding.
- avatar (size 32~38): 단색 fill + `Color.MM.paper` 글자.

---

## 4. Card Components

### 4.1 `StoreCard`

**정전 위치**: `Screen2MapCity` line 220 (horizontal carousel), `Screen2Search` line 493 (list row), `Screen2MapPreview` line 261 (large floating).

**variants**:
1. **horizontal** (지도 위 carousel): width 280, height auto, photo 72×72, radius `MMRadius.xxl`, shadow `MMShadow.medium`.
2. **listRow** (검색 결과): full width, photo 68×68, padding 12 V, divider bottom.
3. **floating** (매장 미리보기): full width minus 32, photo height 150 hero, padding 14/16, radius `MMRadius.xxxl`, shadow `MMShadow.float`. CTA button row 포함.

| Prop | 타입 |
|---|---|
| `name` | String |
| `location` | String? |
| `grade` | Grade |
| `distance` | String? |
| `rating` | Double |
| `reviewCount` | Int |
| `photoTone` | PhotoTone |
| `imageURL` | URL? |
| `isOpen` | Bool |
| `closingTime` | String? |
| `isBookmarked` | Bool |
| `variant` | enum {horizontal, listRow, floating} |

### 4.2 `ReviewCard`

**정전 위치**: `Screen2Reviews` line 437–457.

| Prop | 타입 |
|---|---|
| `author` | User (name + avatar) |
| `date` | String (relative) |
| `rating` | Int |
| `title` | String |
| `body` | String |
| `photoTone` | PhotoTone? |
| `likeCount` | Int |
| `replyCount` | Int |

**스펙**: padding 16 V, divider bottom (`Color.MM.lineSoft`), avatar 32, body 12pt line-height 1.6.

### 4.3 `FeedPostCard`

**정전 위치**: `Screen2Feed` line 627–658.

| Prop | 타입 |
|---|---|
| `author` | User |
| `country` | CountryCode |
| `location` | String |
| `relativeTime` | String |
| `body` | String |
| `imageURLs` | [URL] |
| `likeCount` | Int |
| `commentCount` | Int |
| `isLiked` | Bool |
| `isBookmarked` | Bool |

**스펙**: 카드 간 8pt gap (배경 `Color.MM.bg` 사이로), 카드 자체 `Color.MM.paper`. 사진은 좌우 padding 무시(`marginLeft:-16, marginRight:-16`), height 300.

---

## 5. Input Components

### 5.1 `SearchField`

**정전 위치**: `Screen2MapWorld` line 136 (floating glass), `Screen2Search` line 471 (inline outlined).

**variants**:
- **floating**: bg `Color.MM.paper @ 96%` + `.ultraThinMaterial`, radius 14, padding 12/14, shadow `MMShadow.medium`. trailing 28×28 deep button (filter).
- **inline**: bg `Color.MM.paper`, border 1pt `Color.MM.line`, radius 20 (height 40), padding 0/14.

| Prop | 타입 |
|---|---|
| `placeholder` | String |
| `text` | Binding<String> |
| `onCommit` | () -> Void |
| `trailingAction` | enum {none, filter, clear} |
| `style` | enum {floating, inline} |

### 5.2 `ReviewTextEditor`

**정전 위치**: `Screen2ReviewWrite` line 578.

- bg `Color.MM.paper`, border 1pt `Color.MM.lineSoft`, radius `MMRadius.lg`.
- padding 14, font `MMTypography.callout`, line-height 1.7.
- minimum height 100pt, autosize.
- 커서 blink: `MMMotion.blink`.

### 5.3 `TagSelector`

**정전 위치**: `Screen2ReviewWrite` line 568–574.

- Chip의 `surface selected` variant 활용 + ✓ prefix 표시.
- multi-select.

| Prop | 타입 |
|---|---|
| `tags` | [Tag] |
| `selection` | Binding<Set<Tag>> |
| `wrap` | Bool (default true) |

---

## 6. Button Components

### 6.1 `PrimaryButton`

**정전 위치**: `Screen2Login` line 53 (Apple 검정), `Screen2Location` line 121 (deep), `Screen2MapPreview` line 280 (deep + icon), `Screen2ReviewWrite` line 527 (작은 등록).

**variants**:
- **fullWidth (height 54~56)**: bg `Color.MM.deep`, fg `Color.MM.paper`, radius `MMRadius.pill`, font `Pretendard Semibold 15`.
- **compact (height 36)**: 동일 색, padding 6/14, radius `MMRadius.xl`, font 12 weight 600.

| Prop | 타입 |
|---|---|
| `title` | String |
| `leadingIcon` | String? |
| `width` | enum {fullWidth, compact} |
| `state` | enum {enabled, loading, disabled} |
| `action` | () -> Void |

**Apple Sign In 변형**: bg `#000`(예외 — Apple HIG 강제). `Color.MM.appleBlack` 별도 토큰으로 분리.

### 6.2 `SecondaryButton`

**정전 위치**: `Screen2Login` line 59 (Passkey 라운드), `Screen2Profile` line 790 (편집).

- bg `Color.MM.paper`, border 1.5pt `Color.MM.deep`, fg `Color.MM.deep`.
- radius pill 또는 `MMRadius.xl`.

### 6.3 `GhostButton`

**정전 위치**: `Screen2Location` line 122 (나중에 설정), `Screen2Login` line 85 (이메일로 가입).

- bg transparent, fg `Color.MM.muted` 또는 `.text`.
- underline (offset 4pt, color `Color.MM.line`)을 `이메일로 가입하기`에서 사용.

### 6.4 `IconButton`

**정전 위치**: `Screen2StoreDetail` line 305 (back/share/bookmark glass 36×36), `Screen2MapCity` line 211 (compass/zoom 40×40).

| Prop | 타입 |
|---|---|
| `icon` | String |
| `size` | enum {sm=32, md=36, lg=40} |
| `style` | enum {glass, surface, deep} |
| `action` | () -> Void |

- **glass**: bg `Color.MM.paper @ 92%` + `.ultraThinMaterial`, no border.
- **surface**: bg `Color.MM.paper`, shadow `MMShadow.small~medium`.
- **deep**: bg `Color.MM.deep`, fg `Color.MM.paper`.

### 6.5 `FloatingActionButton`

**정전 위치**: `Screen2Feed` 스토리 plus(line 614), 매장 상세 quick-action grid(line 328).

- size 40~48, radius full, deep bg, paper icon.

---

## 7. Container Components

### 7.1 `Sheet` (Modal frame)

iOS 기본 `.sheet(isPresented:)` 사용 + presentation detents `[.medium, .large]`.

- handle: 36 × 5pt rounded, `Color.MM.line` 50%.
- header padding: 8 V / 16 H.
- close button: `IconButton.glass`.
- footer CTA: `PrimaryButton.fullWidth` (height 54).

### 7.2 `ContentSection`

**정전 위치**: 위시리스트 region header (`Screen2Wishlist` line 712).

| Prop | 타입 |
|---|---|
| `monoLabel` | String (uppercase, IBM Plex Mono 9pt, letterSpacing 0.2em) |
| `trailing` | View (count, action 등) |
| `children` | View |

- 분리선: 가운데 1pt `Color.MM.lineSoft` flex.

### 7.3 `StatHero` (통계 카드)

**정전 위치**: `Screen2MapWorld` line 161 (지도 통계 banner), `Screen2Profile` line 794 (프로필 통계).

- bg `Color.MM.paper`, radius `MMRadius.xxl`, padding 16~18, shadow `MMShadow.large` 또는 border `Color.MM.lineSoft`.
- 라벨: `MMTypography.monoLabel` color `Color.MM.rose` (액센트).
- 숫자: `MMTypography.statNumber` (28~34pt Noto Serif).
- 간격: vertical divider 1pt `Color.MM.lineSoft`.

---

## 8. Icon System

본 카탈로그에서는 **어디에 어떤 이름의 아이콘을 사용하는지**만 명시. 실제 SVG 자산 정의는 `designer-icon`이 `docs/design/icons.md`에 작성 + `LocalPackages/DesignSystem/Sources/Resources/Symbols/`에 납품.

> **정합 상태 (2026-05-04)**: `docs/design/icons.md` § 1과 본 § 8.1이 **1:1 매칭 완료** (designer-icon 보고). UI 28종 + 탭바 4쌍(map/users/bookmark/user × line/fill) + MatchaPin 4등급(S/A/B/C) + 로고 마크 1종 + 앱 아이콘 B canon. 이름 충돌 4건은 designer-icon이 rename 처리 (location→pin, x-close→close, arrow-back→arrow-left+arrow-right, more→menu).
>
> **iOS 사용 인터페이스**: `Image.mm(.search).foregroundStyle(MM2.deep)` 패턴 (icons.md § 1 SwiftUI 예시). `MMIcon` enum이 SSOT — 본 § 8.1의 name 컬럼이 enum case와 1:1.

### 8.1 사용 아이콘 인벤토리 (정전 mm-shared.jsx 기반, MVP 필수)

| name | 사용처 |
|---|---|
| `pin` | (예비) 일반 지도 핀 |
| `search` | 검색바, 피드 헤더 |
| `star` / `star-empty` | Stars 컴포넌트 |
| `heart` / `heart-fill` | 피드 좋아요 |
| `bookmark` / `bookmark-fill` | 매장 / 피드 / 위시리스트 |
| `share` | 매장 상세 헤더, 피드 |
| `arrow-left` / `arrow-right` | 네비게이션 back / next |
| `chevron-right` / `chevron-down` | 리스트 trailing, accordian |
| `plus` | 스토리 추가 |
| `close` | 모달 닫기, 검색 clear, 사진 제거 |
| `check` | 속성 체크, 태그 selected |
| `filter` | (예비) |
| `sliders` | 검색 필터 trailing |
| `list` / `grid` | 위시리스트 view toggle |
| `map` | 탭바 지도 |
| `compass` | 길찾기 CTA, 지도 my-location |
| `clock` | 영업 시간 |
| `phone` | 매장 전화 |
| `globe` | 매장 웹사이트 |
| `user` / `users` | 탭바 내정보 / 피드 / 친구 |
| `camera` | 사진 추가 |
| `edit` | 리뷰 작성 진입 |
| `settings` | 프로필 우상단 |
| `bell` | 알림 |
| `message` | 댓글 |
| `world-pin` | 지도 컨트롤 |
| `menu` | 더보기 ⋯ |
| `sort` | 정렬 |

→ `designer-icon`이 위 28개 아이콘을 SVG로 납품. SF Symbols 의존 금지.

### 8.2 컴포넌트 → 아이콘 사용 매트릭스 (designer-icon 정합 검증용)

각 컴포넌트가 어떤 아이콘 name을 어느 상태/variant에서 호출하는지 SSOT. designer-icon이 본 표를 SSOT로 누락/중복 검증. 신규 컴포넌트 추가 시 본 표에 반드시 한 줄 추가.

| 컴포넌트 | 사용 아이콘 (state/variant) | 비고 |
|---|---|---|
| **TabBar2** | tabbar/`map` + `map-fill` (활성) / tabbar/`users` + `users-fill` / tabbar/`bookmark` + `bookmark-fill` / tabbar/`user` + `user-fill` | icons.md § 2. 28×28 viewBox. 활성/비활성 fill 토글 |
| **MatchaPin** | pin/`matcha-pin-S/A/B/C` | icons.md § 3. 36×44 viewBox. SwiftUI는 `PinAsset.S` enum |
| **GradeChip** | (아이콘 없음 — 글자 S/A/B/C만) | — |
| **Stars** | `star` (line/fill 토글) | icons.md star-empty은 1파일 fill 토글 |
| **Photo** | (아이콘 없음 — placeholder gradient) | — |
| **CountryFlag** | (이모지 — 향후 SVG flag set v1.1) | — |
| **Chip** | leading: `sort` / `compass` / 등 컨텍스트별 / trailing: `chevron-down` (드롭다운 variant) | line variant only |
| **Avatar** | (아이콘 없음 — initial 1글자 또는 imageURL) | story ring은 그라디언트, 아이콘 X |
| **StoreCard.horizontal** | (아이콘 없음 — Photo + GradeChip + Stars만) | — |
| **StoreCard.listRow** | trailing: `bookmark` / `bookmark-fill` (북마크 상태) | — |
| **StoreCard.floating** | leading CTA: `compass` (길찾기) + `phone` (전화) | — |
| **ReviewCard** | trailing actions: `heart` / `heart-fill` + `message` (댓글) | — |
| **FeedPostCard** | trailing menu: `menu` (⋯) / actions: `heart`+`heart-fill` + `message` + `share` + `bookmark`+`bookmark-fill` | — |
| **WishlistRow** | trailing: `bookmark-fill` (저장됨) | 저장된 상태만 표시 |
| **SearchField.floating** | leading: `search` / trailing 28×28 deep: `sliders` (필터) | bg glass |
| **SearchField.inline** | leading: `search` / trailing: `close` (clear) | search 결과 화면 |
| **ReviewTextEditor** | (아이콘 없음 — blink 커서) | — |
| **TagSelector** | selected prefix: `check` (✓) | matchaPale variant |
| **PrimaryButton.fullWidth** | optional leadingIcon: `compass` / 등 | Apple Sign In은 별도 svg path |
| **PrimaryButton.compact** | (아이콘 없음 — 텍스트만) | "등록" 등 |
| **SecondaryButton** | (아이콘 없음) | — |
| **GhostButton** | (아이콘 없음) | — |
| **IconButton.glass** | 컨텍스트별: `arrow-left` (back) / `share` / `bookmark`+`bookmark-fill` | 매장 상세 헤더 |
| **IconButton.surface** | 컨텍스트별: `plus` / `world-pin` / `compass` (지도 컨트롤) | 40×40 |
| **IconButton.deep** | 컨텍스트별: `sliders` (검색바 trailing) | 28×28 |
| **FloatingActionButton** | `plus` (스토리 추가) / `edit` (리뷰 작성 진입) | 40~48 |
| **Sheet (Modal frame)** | close 위치: `IconButton.glass(close)` | grab handle은 도형 |
| **ContentSection** | (아이콘 없음 — mono 라벨만) | — |
| **StatHero** | (아이콘 없음 — 숫자 + mono 라벨) | — |
| **Photo upload grid (10 ReviewWrite)** | "추가" 슬롯: `camera` + 작은 라벨 / 각 사진 우상단 close: `close` | — |
| **Quick action grid (07 Detail)** | 4개 액션: `compass` (길찾기 강조 deep) / `phone` / `globe` / `share` | grid 4×1 |
| **영업시간 카드 (07 Detail)** | leading: `clock` / trailing: `chevron-down` (expand) | — |
| **Story Ring (11 Feed)** | "내" 추가 표시: `plus` (small badge) | 다른 친구는 아이콘 없음 |
| **AdBannerSlot (M2)** | (아이콘 없음 — 광고 disclosure mono 라벨 "광고/Ad" 만) | — |
| **InterstitialAdHost (M3)** | (시스템 GMS SDK 자체 처리 — 본 디자인 시스템 외) | — |
| **RewardedAdSheet (M4)** | 잠금 → 잎 모핑: `bookmark-fill` 또는 leaf-fill (별도 자산 — designer-icon P2) / close: `close` | — |
| **ATT Prompt (M1)** | 중앙 SVG (별 + 잎 sparkle) — designer-icon P2 자산 / CTA: 아이콘 없음 | — |
| **NavBar (모든 화면)** | leading: `arrow-left` (push 화면) | — |
| **Bell trailing (11 Feed / 13 Profile)** | `bell` | — |
| **List/Grid view toggle (12 Wishlist)** | `list` + `grid` | active 색 deep / inactive muted |
| **Settings entry (13 Profile)** | leading: `settings` | — |
| **Disclosure rows (13 Profile menu list)** | leading 컨텍스트별: `bookmark` (위시) / `edit` (내 리뷰) / `users` (친구) / `bell` (알림) / trailing: `chevron-right` | — |

#### 누락/추가 후보

본 매트릭스 작성 시점 누락 0건. 후속 컴포넌트 추가 시 designer-icon에 즉시 SendMessage:

| 후보 | 컨텍스트 | 우선순위 |
|---|---|---|
| `leaf-fill` | RewardedAdSheet 모핑 reveal | P2 (v1.0 또는 v1.1) |
| `lock` / `lock-open` | C3 Locked Card 잠금 표시 | P2 |
| `globe-search` | 04 World "여행 모드" 인디케이터 (해외 도시 미리보기) | P1 (po-growth 합의 후) |
| `card-stack` | C1 Collection Grid 도감 진입점 | P1 |
| `flame` / `fire` | 인기 매장 표시 (검색 09b "지금 인기") | P2 |
| `info` | tooltip / 광고 disclosure 확장 | P2 |

→ designer-icon은 본 후보 6건 검토 후 `icons.md § 1` 인벤토리에 추가 또는 거절. 결정 시 본 § 8.2도 갱신.

---

## 9. 광고 슬롯 (AdMob 통합 컴포넌트 — `po-growth` 합의 필요)

`po-growth`가 광고 정책을 확정하면 본 섹션에 추가. 후보 슬롯:

| 위치 | 타입 | 노출 정책 |
|---|---|---|
| 지도 화면 하단 (TabBar 위) | 320×50 또는 320×100 배너 | 항시 노출, 첫 60초 차단 |
| 매장 상세 진입 시 | 인터스티셜 | 5번째 진입마다 (TBD) |
| 위시리스트 도감 잠금 해제 | 보상형 | 사용자 자발 |

**컴포넌트 후보**: `AdBannerSlot` / `InterstitialAdHost` / `RewardedAdSheet`. 디자인 토큰: `Color.MM.lineSoft` 1pt top border + height 50/100.

> **결정 대기**: `po-growth`에 `SendMessage`로 광고 슬롯 위치/사이즈/카피 합의 요청.

---

## 10. 6개 언어 길이 검증 (각 컴포넌트)

design-system § 7 의 max-width 룰을 컴포넌트별로 적용:

| 컴포넌트 | 길이 정책 |
|---|---|
| TabBar2 라벨 | 1줄 / max 6글자(de). 초과 시 약어. |
| Chip label | 1줄 / max 12글자(en). 초과 시 truncate ellipsis. |
| StoreCard 매장명 | 2줄 lineLimit, minimumScaleFactor 0.9. |
| PrimaryButton title | 1줄 / max 22글자(de). 초과 시 short-form. |
| ReviewCard title | 1줄, body 무제한. |
| Stat label | 1줄 / max 6글자. |

→ `qa-localization`이 6개 언어로 회귀.

---

## 11. 변경 이력

| 일자 | 변경 | 사유 |
|---|---|---|
| 2026-05-04 | 최초 작성 | Phase 1 컴포넌트 카탈로그 |

---

References:
- `docs/design/design-system.md` (토큰)
- `docs/design/handoff-mapping.md` (화면 ↔ View 매핑)
- `docs/design/icons.md` (아이콘 자산 — designer-icon 작성 예정)
- 정전: `_handoff/matchamap/project/mm-shared-v2.jsx` / `mm-screens-v2.jsx`
