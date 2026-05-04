# LocalPackages/Feature/FeatureMap

> 지도 화면 + 매장 핀 마커 + 카메라 제어. **소유: `ios-map`**.

## 책임

- `MapScreen` SwiftUI View.
- `GMSMapView` UIViewRepresentable 래퍼.
- 매장 핀 마커 + 클러스터링.
- 카메라 컨트롤 (현재 위치, 검색 결과 fit).
- 위치 권한 흐름 + reverseGeocode → `travel_mode` 계산.

## 의존

- 내부: `Domain`, `DesignSystem`.
- 외부 (Phase 3): `GoogleMaps`.

## 금지

- `import Data` — 직접 Repository 구현체 import 금지.
- 다른 `Feature/*` 모듈 import.

## Phase 3 시작 시 우선 처리

`handoff-phase3-ios-map.md` 5건:
1. viewBox 36×44, retina 1x/2x/3x.
2. anchor = tip(18, 42) — `groundAnchor = (0.5, 1.0)`.
3. 그림자 별도 레이어.
4. 등급 매핑 — `StoreGrade.from(matchaScore:)` 사용 (Domain 결정).
5. Asset 이름 규약 — ios-lead가 결정 후 designer-icon 합의.
