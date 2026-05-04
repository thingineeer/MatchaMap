// FeatureMap — 지도 화면.
// 의존: Domain, DesignSystem (+ Phase 3에서 GoogleMaps).
//
// Phase 3에서 채울 항목:
// - MapScreen.swift          (SwiftUI View — GMSMapView UIViewRepresentable 래퍼 포함)
// - MapViewModel.swift       (@Observable, Domain UseCase 주입)
// - MapMarkerFactory.swift   (DesignSystem MatchaPin SVG → GMSMarker.icon UIImage 변환)
// - MapPermissionFlow.swift  (CLLocationManager 권한 + reverseGeocode → travel_mode)
//
// handoff-phase3-ios-map.md 5건(viewBox/anchor/그림자/등급매핑/Asset 이름)을 시작 시 우선 처리.

import Domain
import DesignSystem

public enum FeatureMap {
    public static let version: String = "0.1.0"
}
