import SwiftUI

/// MM2 팔레트 — design-system.md §1 정전. hex 값은 정전과 ±0 일치.
/// Asset Catalog 도입 후 `Color("MMDeep", bundle: .module)` 형태로 갈아끼우기 가능 (designer-lead 후속).
public extension Color {
    enum MM {
        // Surface
        public static let bg          = Color(hex: 0xFBFAF7)
        public static let paper       = Color.white
        public static let cream       = Color(hex: 0xF5F1EA)

        // Brand — matcha 5단계 (ADR-302 v1.1 colorTier와 1:1)
        // SSOT: design-system.md §1.5.1 (designer-lead). server-functions utils/colorTier.ts 정합.
        public static let deep        = Color(hex: 0x3D4A2D)
        public static let deepMatcha  = Color(hex: 0x556B43)   // designer-lead 사인오프 2026-05-04 (designer-icon 위계 분석 채택)
        public static let matcha      = Color(hex: 0x7A9560)
        public static let matchaSoft  = Color(hex: 0xA8B994)
        public static let matchaPale  = Color(hex: 0xE6ECDE)

        // Accent — rose
        public static let rose        = Color(hex: 0xC98B85)
        public static let rosePale    = Color(hex: 0xF0D9D5)
        public static let blush       = Color(hex: 0xE8C4C0)

        // Neutrals
        public static let ink         = Color(hex: 0x2A2A2A)
        public static let text        = Color(hex: 0x4A4A45)
        public static let muted       = Color(hex: 0xA39E92)
        public static let mutedSoft   = Color(hex: 0xC4BFB2)
        public static let line        = Color(hex: 0xEBE7DC)
        public static let lineSoft    = Color(hex: 0xF2EFE6)

        // Functional
        public static let gold        = Color(hex: 0xC9A566)
        public static let appleBlack  = Color.black

        /// colorTier (CollectionItem.ColorTier) 5단계 → hex 매핑.
        /// SSOT: design-system.md §1.5.1 (designer-lead). MMColor 5단계 토큰과 1:1.
        /// server-functions utils/colorTier.ts와 hex 정합 — 변경 시 3곳 동기화.
        public static func matchaTier(_ tier: MatchaColorTier) -> Color {
            switch tier {
            case .matchaSoft:  return matchaSoft    // #A8B994 — 가장 옅음
            case .matchaPale:  return matchaPale    // #E6ECDE
            case .matcha:      return matcha        // #7A9560
            case .deepMatcha:  return deepMatcha    // #556B43
            case .deep:        return deep          // #3D4A2D — 가장 짙음
            }
        }
    }
}

/// Domain CollectionItem.ColorTier에 직접 의존하지 않기 위한 mirror enum.
/// Composition root에서 Domain → DesignSystem 매핑 유틸로 변환.
public enum MatchaColorTier: String, CaseIterable, Sendable, Hashable {
    case matchaSoft
    case matchaPale
    case matcha
    case deepMatcha
    case deep
}

public extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
