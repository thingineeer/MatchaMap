# Icon Library Catalog — MatchaMap

> Owner: `designer-icon` · 정합성 검토자: `designer-lead`, `ios-map`, `ios-lead`
> 원본 SVG: `_design_assets/svg/{icon|tabbar|pin|appicon|logo}/*.svg`
> 빌드 적재 목적지: `LocalPackages/DesignSystem/Sources/Resources/Symbols/*.svg|.pdf` + `MatchaMap/Assets.xcassets/Symbols/`

---

## 0. 공통 규약

| 항목 | 규칙 |
|---|---|
| **viewBox** | UI = `0 0 24 24` · 탭바 = `0 0 28 28` · 핀 = `0 0 36 44` · 앱아이콘 = `0 0 1024 1024` · 로고 = `0 0 84 100` |
| **stroke** | `1.5px`, `linecap=round`, `linejoin=round` |
| **padding** | viewBox 가장자리에서 `2px` (탭바도 동일) — 가장자리 1.5–2px 안전 영역 |
| **색상** | `currentColor` 사용. SwiftUI에서 `.foregroundStyle(MM2.deep)` 형태로 토큰 주입. 핀과 앱아이콘은 예외(다중 컬러). 로고는 정전 색(deep + matchaSoft) |
| **fill 규칙** | line 아이콘 = `fill="none"` + `stroke="currentColor"`. 채움 변형은 `*-fill.svg`로 별도 파일 |
| **대칭** | 좌우 대칭 의도 아이콘은 cx=12 (UI) / cx=14 (탭바) / cx=18 (핀) / cx=42 (로고) / cx=512 (앱아이콘) 기준 검증. 각 SVG 헤더 주석에 `symmetry=...` 명시 |
| **수동 좌표** | 모든 좌표는 손으로 작성. 자동 변환된 SVG의 `transform` 어트리뷰트 절대 금지 (예외: 앱아이콘 C의 rosette 회전 + settings 톱니 8-fold는 의도적) |
| **SF Symbols 의존** | **금지**. 모든 심볼은 자체 SVG (`decisions-design.md` 참조) |

---

## 1. UI 아이콘 — components.md §8.1 정합 (28종 + star fill 토글)

`_design_assets/svg/icon/*.svg`. components.md §8.1 명단과 1:1 매칭.

| name | 파일 | 대칭 | line/fill | 사용처 (components.md §8.1) |
|---|---|---|---|---|
| pin | `icon/pin.svg` | 좌우 | line | 매장 주소 prefix, 일반 지도 핀 (UI). 매장 마커는 별도 36×44 |
| search | `icon/search.svg` | 비대칭 | line | 검색바, 피드 헤더 |
| star | `icon/star.svg` | 좌우 | line(+fill prop 토글) | Stars 컴포넌트. star-empty = 동일 파일 fill 토글 |
| heart | `icon/heart.svg` | 좌우 | line | 피드 좋아요 (off) |
| heart-fill | `icon/heart-fill.svg` | 좌우 | fill | 피드 좋아요 (on) |
| bookmark | `icon/bookmark.svg` | 좌우 | line | 매장 / 위시리스트 (off) |
| bookmark-fill | `icon/bookmark-fill.svg` | 좌우 | fill | 매장 / 위시리스트 (on) |
| share | `icon/share.svg` | 좌우 | line | 매장 상세 헤더, 피드 |
| arrow-left | `icon/arrow-left.svg` | 비대칭 | line | NavBar back |
| arrow-right | `icon/arrow-right.svg` | 비대칭 | line | NavBar next, list trailing |
| chevron-right | `icon/chevron-right.svg` | 비대칭 | line | 리스트 disclosure |
| chevron-down | `icon/chevron-down.svg` | 좌우 | line | 드롭다운, accordion |
| plus | `icon/plus.svg` | 양 축 | line | 스토리/리뷰 추가 |
| close | `icon/close.svg` | 양 대각 | line | 모달 닫기, 검색 clear, 사진 제거 |
| check | `icon/check.svg` | 비대칭 | line | 속성 체크, 태그 selected |
| filter | `icon/filter.svg` | 좌우 | line | 매장 리스트 필터 |
| sliders | `icon/sliders.svg` | 비대칭 | line | 검색 필터 trailing, 고급 필터 |
| list | `icon/list.svg` | 비대칭 | line | 위시리스트 view toggle (list mode) |
| grid | `icon/grid.svg` | 양 축 | line | 위시리스트 view toggle (grid mode) |
| map | `tabbar/map.svg` (탭바와 공유) | 좌우 | line | 탭바 지도 (UI 단독 사용 시 동일 자산) |
| compass | `icon/compass.svg` | 좌우 | line | 길찾기 CTA, my-location |
| clock | `icon/clock.svg` | 좌우 | line | 영업 시간 |
| phone | `icon/phone.svg` | 비대칭 | line | 매장 전화 |
| globe | `icon/globe.svg` | 좌우 | line | 매장 웹사이트 |
| user | `tabbar/user.svg` (탭바와 공유) | 좌우 | line | 탭바 내정보 (UI 단독 사용 동일 자산) |
| users | `tabbar/users.svg` (탭바와 공유) | 비대칭 | line | 탭바 피드, 친구 |
| camera | `icon/camera.svg` | 좌우 | line | 사진 추가, 프로필 사진 |
| edit | `icon/edit.svg` | 비대칭 | line | 리뷰 작성 진입 |
| settings | `icon/settings.svg` | 8-fold | line | 프로필 우상단 |
| bell | `icon/bell.svg` | 좌우 | line | 알림 |
| message | `icon/message.svg` | 비대칭 | line | 댓글 |
| world-pin | `icon/world-pin.svg` | 좌우 | line | 지도 컨트롤 (글로벌 토글) |
| menu | `icon/menu.svg` | 좌우 (3 dots ⋯) | fill | 더보기 ⋯ (components.md §8.1 menu = ⋯) |
| sort | `icon/sort.svg` | 좌우 | line | 정렬 토글 |
| leaf-fill | `icon/leaf-fill.svg` | 대각선(NE-SW) | fill | RewardedAdSheet (M4) 잠금 → 잎 reveal 시각 효과. P2 |
| lock | `icon/lock.svg` | 좌우 | line | C3 Locked Card 잠금 표시. P2 |
| lock-open | `icon/lock-open.svg` | 본체 좌우 (shackle 비대칭) | line | 잠금 해제 상태 (보상형 광고 시청 후). P2 |
| globe-search | `icon/globe-search.svg` | 비대칭 | line | 04 World "여행 모드" 인디케이터 (icp.md P1 Top Need 2). P1 |
| card-stack | `icon/card-stack.svg` | 좌우 | line | C1 Collection Grid → 도감 진입점. P1 |
| flame | `icon/flame.svg` | 좌우 | line | 인기 매장 표시 (검색 09b "지금 인기"). P2 |
| info | `icon/info.svg` | 좌우 | line | tooltip / 광고 disclosure inline 안내. P2 |

> **star-empty 정책**: 별도 파일 미작성. `star.svg`는 `fill="none"` line이므로 그대로가 line variant. SwiftUI에서 `Image("star").renderingMode(.template).foregroundStyle(...)`로 사용. fill variant가 필요하면 `star-fill.svg` 추후 추가.
>
> **map / user / users 공유**: 탭바와 일반 UI에서 동일 자산 사용. 탭바는 28×28 viewBox, UI는 24×24 다운스케일이지만 marker 본 자산을 그대로 활용 (디자인 일관성 보호).

### SwiftUI 사용 예시

```swift
// LocalPackages/DesignSystem/Sources/Components/MMIcon.swift
import SwiftUI

public enum MMIcon: String, CaseIterable {
    case pin, search, star
    case heart, heartFill = "heart-fill"
    case bookmark, bookmarkFill = "bookmark-fill"
    case share
    case arrowLeft = "arrow-left", arrowRight = "arrow-right"
    case chevronRight = "chevron-right", chevronDown = "chevron-down"
    case plus, close, check, filter, sliders
    case list, grid
    case compass, clock, phone, globe
    case camera, edit, settings, bell, message
    case worldPin = "world-pin"
    case menu, sort
    case map, user, users  // 탭바 공유
    case leafFill = "leaf-fill"
    case lock, lockOpen = "lock-open"
    case globeSearch = "globe-search"
    case cardStack = "card-stack"
    case flame, info
}

public extension Image {
    static func mm(_ icon: MMIcon, size: CGFloat = 24) -> some View {
        Image(icon.rawValue, bundle: .module)
            .renderingMode(.template)
            .resizable()
            .frame(width: size, height: size)
    }
}

// 사용
Image.mm(.search).foregroundStyle(MM2.deep)
Image.mm(.heartFill, size: 20).foregroundStyle(MM2.rose)
```

---

## 2. 탭바 아이콘 4쌍 (28×28)

> 4개 탭: **지도(map) / 피드(users) / 위시리스트(bookmark) / 내정보(user)**.
> 활성/비활성 모두 동일한 viewBox, padding 2px. 활성 = fill 채움, 비활성 = line.

| Tab | Inactive | Active | 라벨(KR) | 라벨(EN) |
|---|---|---|---|---|
| 지도 | `tabbar/map.svg` | `tabbar/map-fill.svg` | 지도 | Map |
| 피드 | `tabbar/users.svg` | `tabbar/users-fill.svg` | 피드 | Feed |
| 위시리스트 | `tabbar/bookmark.svg` | `tabbar/bookmark-fill.svg` | 위시 | Saved |
| 내정보 | `tabbar/user.svg` | `tabbar/user-fill.svg` | 내정보 | Me |

### 색상 토큰

- **Active**: `MM2.deep #3d4a2d`
- **Inactive**: `MM2.muted #a39e92`
- **Active label weight**: 600 / **Inactive**: 500

---

## 3. 매장 핀 — MatchaPin 4등급 (36×44)

`_design_assets/svg/pin/matcha-pin-{S,A,B,C}.svg`. 정전 좌표: `mm-shared-v2.jsx` line 135-136 `MatchaPin2`.

cx=18 좌우 대칭, tip=(18, 42).

| Grade | 파일 | bg | leaf | 비고 |
|---|---|---|---|---|
| **S** | `pin/matcha-pin-S.svg` | `#3d4a2d` (MM2.deep) | `#a8b994` (MM2.matchaSoft) | 최고 등급 |
| **A** | `pin/matcha-pin-A.svg` | `#7a9560` (MM2.matcha) | `#f0e8d4` (warm cream) | 추천 |
| **B** | `pin/matcha-pin-B.svg` | `#c98b85` (MM2.rose) | `#ffffff` | 무난 |
| **C** | `pin/matcha-pin-C.svg` | `#ffffff` | `#7a9560` (MM2.matcha) | 그 외 (white pin은 stroke=deep 1px) |

각 SVG는 그림자 ellipse (cx=18 cy=42 rx=6 ry=1.5)를 별도 레이어로 분리 — Maps zoom level이 낮을 때 SDK 측에서 제거 가능.

### 사이즈 변형 (P1, Phase 2 합의 후)

components.md §8 요구: small=24 / md=36 / lg=48 × 4등급 = 12 PNG. `@1x/@2x/@3x` Asset Catalog 형식. fastlane lane `generate_pin_pngs`로 자동 export — Phase 2 시작 시 `ios-map`과 합의 후 작성.

drop-shadow 비포함 변형은 raster 시점에 ellipse 제거하여 `-noshadow` 접미사로 별도 export.

### Phase 1 잔재 → 정식 매핑

`pin/{basic, premium, iconic}.svg` 3종은 Phase 1 자체 카탈로그 잔재. v1.0.0 출시 빌드는 정식 4등급(S/A/B/C)만 사용. 자세한 매핑 표는 `_design_assets/svg/pin/README.md`.

### iOS 적재 (ios-map과 합의 항목)

```swift
let marker = GMSMarker()
marker.iconView = PinView(grade: .S)
marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)  // tip = (18, 42) of 36×44
```

이름 규약: `matcha-pin-S/A/B/C`. SwiftUI `PinAsset.S` enum 캡슐화.
클러스터링 뱃지는 v1.0.1 백로그.

---

## 4. 앱 아이콘 — B 채택 (canon)

> ACCEPTED 2026-05-04 by `po-lead`.
> Canon: `_design_assets/svg/appicon/B-glass-leaf.svg` (1024×1024).
> 비교/추천 문서: `docs/design/app-icon-decision.md`. 가중 합계 B=67 / A=52 / C=43.

vein 시그니처(6 비대칭) = MM 동결 패턴 — v2.x까지 vein 좌표 변경 금지.

PNG 슬롯 export는 Phase 2 ios-lead 슬롯 이름 합의 후 fastlane lane `generate_appicon_slots` 일괄 생성.

---

## 5. 로고 마크

`_design_assets/svg/logo/logo-mark.svg` — viewBox 84×100 (정전 `Screen2Splash` line 11-15).

- 본체: `#3d4a2d` (MM2.deep) — 매장 핀 형태.
- 잎: `#a8b994` (MM2.matchaSoft) — pin 안에 살짝 담긴 잎.
- 잎 vein: `#3d4a2d` opacity 0.4 stroke 0.8.

`_design_assets/svg/logo/logo-wordmark.svg` — viewBox 240×60. 마크 + "MATCHAMAP" 문자열(IBM Plex Mono). 실제 SwiftUI 사용 시 `Image("logo-mark") + Text("MATCHAMAP")` 분리 권장. 본 SVG는 ASO/스토어 자료용 단일 자산.

PDF vector + favicon 32×32 export는 P1.

---

## 6. 검증 체크리스트 (designer-icon 자기검증)

- [x] 모든 UI SVG가 `viewBox="0 0 24 24"` 일치 (28종 + star fill 토글, 탭바 공유 3종 포함).
- [x] 모든 탭바 SVG가 `viewBox="0 0 28 28"` 일치 (4 line + 4 fill).
- [x] 좌우 대칭 의도 아이콘은 헤더 주석에 `symmetry=vertical-axis` 명시.
- [x] 좌표 안전 영역 padding 2px 준수.
- [x] `transform` 어트리뷰트 사용 최소화 (앱아이콘 C rosette + settings 8-fold는 의도적, 헤더 주석에 명시).
- [x] line 아이콘은 `fill="none"`, fill 변형은 별도 `*-fill.svg`.
- [x] 핀 4등급 cx=18 좌우 대칭, tip y=42 일치, 정전 좌표 그대로 이식.
- [x] 앱 아이콘 B canon, cx=512 좌우 대칭, 안전 영역 824×824 통과.
- [x] 로고 마크 cx=42 좌우 대칭, 정전 84×100 viewBox 보존.
- [x] components.md §8.1 28종 명단 1:1 매칭 (star/star-empty은 1파일 + fill 토글).

---

## 7. 추가 작업 백로그

- [ ] **P0 — Phase 2 시작 전**: 28개 일반 아이콘 SVG → PDF vector 변환 (Asset Catalog SVG 직접 적재 가능하나 PDF 호환 필요 시).
- [ ] **P0**: MatchaPin md(36)×4등급 PNG @1x/@2x/@3x — fastlane lane `generate_pin_pngs`.
- [ ] **P1**: MatchaPin small(24)/lg(48) × 4등급 PNG.
- [ ] **P1**: 로고 마크 PDF vector + favicon 32×32.
- [ ] **P2 (v1.1)**: Lottie `matcha-leaf-rotate` (위치 권한 화면 LottiePlaceholder 대체).
- [ ] **P2 (v1.1)**: 국가 flag set ~30종 (MVP는 emoji 사용).
- [ ] 클러스터링 뱃지 디자인 (`ios-map` 요청 시 v1.0.1).
- [ ] 라이트/다크/Tinted 변형 (앱 아이콘 채택 후 fastlane export 단계).

---

## 8. Changelog

| 일자 | 변경 |
|---|---|
| 2026-05-04 | 초안 — UI 17 + 탭바 4쌍 + 핀 3종 + 앱아이콘 후보 3 |
| 2026-05-04 | 앱 아이콘 B 채택 canon. 핀 4등급(S/A/B/C) 추가 — components.md §8 정전 매핑. UI 누락 13건(heart-fill/bookmark-fill/list/grid/compass/clock/phone/globe/edit/settings/bell/message/world-pin) 추가. 충돌 4건 rename(location→pin, x-close→close, arrow-back→arrow-left+arrow-right 신규, more→menu). 로고 마크 추가. components §8.1 28종 1:1 매칭. |
| 2026-05-04 | designer-lead §8.2 후보 6건 모두 수용. 7 SVG 신규 (leaf-fill, lock, lock-open, globe-search, card-stack, flame, info). MMIcon enum 갱신. P1: globe-search/card-stack. P2: leaf-fill/lock/lock-open/flame/info. |

---

생성: 2026-05-04 · Owner: `designer-icon`
