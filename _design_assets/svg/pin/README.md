# Pin SVG Assets

> Owner: `designer-icon` · 협업: `ios-map`, `designer-lead` (components.md §8.2 정전 매핑)

## Files

### MatchaPin 4등급 (정식 — components.md §8.1 정전 매핑)

`viewBox 36×44`, `cx=18` 좌우 대칭, `tip=(18, 42)`. 정전: `mm-shared-v2.jsx` line 135-136 `MatchaPin2`.

| Grade | 파일 | 색상 (정전 line 124-128) |
|---|---|---|
| S | `matcha-pin-S.svg` | bg=`#3d4a2d`(MM2.deep), leaf=`#a8b994`(MM2.matchaSoft) |
| A | `matcha-pin-A.svg` | bg=`#7a9560`(MM2.matcha), leaf=`#f0e8d4`(warm cream) |
| B | `matcha-pin-B.svg` | bg=`#c98b85`(MM2.rose), leaf=`#ffffff` |
| C | `matcha-pin-C.svg` | bg=`#ffffff`, leaf=`#7a9560`(MM2.matcha), stroke=`#3d4a2d` |

각 파일 첫 라인 그림자 ellipse(cx=18 cy=42 rx=6 ry=1.5)는 별도 레이어로 분리 — Maps zoom level이 낮을 때 SDK 측에서 제거 가능.

### 등급 매핑 (Phase 1 잔재 ↔ 정식 이름)

Phase 1 자체 카탈로그에서 사용한 이름 ↔ components.md §8 정전 매핑:

| Phase 1 (잔재) | components 정식 | 비고 |
|---|---|---|
| `basic.svg` | `matcha-pin-B.svg` 또는 `matcha-pin-A.svg` | 일반 등급 — 정식은 A 또는 B 사용 |
| `premium.svg` | (별도 디자인) | 정식 4등급에 premium 별도 슬롯 없음. iconic.svg 또는 새 6번째 SVG 필요 시 추후 |
| `iconic.svg` | `matcha-pin-S.svg`에 가깝지만 rosette 디자인 | S 등급은 정전 좌표 (단순 잎) 사용. iconic은 v1.1 별도 명세 |

**결정**: v1.0.0은 정식 4등급(S/A/B/C)만 사용. basic/premium/iconic 3종은 디자인 자료로 보존하되 출시 빌드에 미포함. `ios-map`은 `matcha-pin-{S,A,B,C}.svg` 4개만 Asset Catalog에 적재.

### 사이즈 변형 (P1 — Phase 2 시작 후 제공)

components.md §8.2 요구: small=24px / md=36px / lg=48px × 4등급 = 12 PNG.

- 마스터 36×44 SVG → fastlane lane(`generate_pin_pngs`)에서 24/36/48 비율 다운/업스케일.
- @1x/@2x/@3x = 36×44 마스터를 1x로 두고 2x=72×88, 3x=108×132 raster.
- drop-shadow 포함/비포함 두 버전:
  - shadow ON: 본 SVG 그대로 (ellipse 포함)
  - shadow OFF: ellipse 제거 후 raster (Asset 이름에 `-noshadow` 접미사)

본 단계에서는 SVG 마스터(shadow ON 4종)만 납품. PNG export는 Phase 2 ios-map과 합의 후.

## anchor / GMS 사용

```swift
let marker = GMSMarker()
marker.iconView = PinView(grade: .S)  // SwiftUI Image("matcha-pin-S")
marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)  // tip = (18, 42) of 36×44
```

## 변경 이력

| 일자 | 변경 |
|---|---|
| 2026-05-04 | 초안: basic/premium/iconic 3종 (Phase 1 카탈로그) |
| 2026-05-04 | components.md §8 정합: 정식 4등급 S/A/B/C 추가. 정전 좌표 기반. |
