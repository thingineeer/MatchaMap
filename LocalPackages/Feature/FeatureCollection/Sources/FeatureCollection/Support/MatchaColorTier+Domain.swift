import Domain
import DesignSystem

/// Domain `CollectionItem.ColorTier` ↔ DesignSystem `MatchaColorTier` 변환.
/// 두 enum이 동일하지만 모듈 분리 정책상 변환 layer 둠 — Feature 모듈 내 유틸.
public extension CollectionItem.ColorTier {
    var dsTier: MatchaColorTier {
        switch self {
        case .matchaSoft: return .matchaSoft
        case .matchaPale: return .matchaPale
        case .matcha:     return .matcha
        case .deepMatcha: return .deepMatcha
        case .deep:       return .deep
        }
    }
}

public extension MatchaColorTier {
    var domain: CollectionItem.ColorTier {
        switch self {
        case .matchaSoft: return .matchaSoft
        case .matchaPale: return .matchaPale
        case .matcha:     return .matcha
        case .deepMatcha: return .deepMatcha
        case .deep:       return .deep
        }
    }
}
