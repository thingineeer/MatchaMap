import Foundation

/// 매장 상세 탭 — handoff-mapping.md 화면 7 "탭(소개/메뉴/리뷰)".
public enum StoreDetailTab: String, Sendable, CaseIterable, Hashable {
    case overview
    case menu
    case reviews
}
