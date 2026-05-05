// FeatureCollection — 도감(컬렉션), 위시리스트, 프로필.
// 의존: Domain, DesignSystem. Data import 금지.
//
// 구성:
// - Grid/CollectionGridView + ViewModel — 도감 그리드 (LazyVGrid 250+ 항목 60fps)
// - Memory/MemoryPageView — 도감 카드 상세 (등급/원산지/colorTier 5단계)
// - Wishlist/WishlistView + ViewModel — 국가별 그룹 + 미니 세계지도 (Google Maps SDK 비사용)
// - Wishlist/MiniWorldMapView — 디자이너 SVG 도착 전 stub
// - Profile/ProfileView + ViewModel — 통계 hero + 최근 도감 carousel + 메뉴
// - Support/MatchaColorTier+Domain — Domain ↔ DesignSystem 변환 유틸

import Domain
import DesignSystem

public enum FeatureCollection {
    public static let version: String = "0.2.0"
}
