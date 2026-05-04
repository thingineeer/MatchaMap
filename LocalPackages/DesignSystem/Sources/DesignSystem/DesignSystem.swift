// DesignSystem — MM2 토큰, 컴포넌트, SVG/이미지 리소스.
// SwiftUI만 의존. Domain import 금지.
//
// Phase 3에서 채울 항목:
// - Tokens/Colors.swift     (MM2 화이트톤 팔레트)
// - Tokens/Typography.swift (Pretendard 토큰)
// - Tokens/Spacing.swift
// - Components/MMButton.swift
// - Components/MMCard.swift
// - Components/MMTag.swift
// - Components/MMRatingBadge.swift
// - Components/MMSearchBar.swift
// - Components/MMEmptyState.swift
// - Pins/MatchaPinView.swift  (basic/premium/iconic SVG 임포트)

import SwiftUI

public enum DesignSystem {
    public static let version: String = "0.1.0"
}

/// MM2 팔레트 토큰의 진입점 — 실제 컬러는 Asset Catalog로 본 모듈 번들에 추가될 예정.
public enum MMColor {
    /// 토큰 이름과 핸드오프 매핑은 docs/design/handoff-mapping.md § 컬러 참조.
    public static var matchaPrimary: Color { .green } // TODO(Phase 3): Color("MatchaPrimary", bundle: .module)
    public static var surface: Color { .white }
    public static var onSurface: Color { .black }
}

public enum MMSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
}
