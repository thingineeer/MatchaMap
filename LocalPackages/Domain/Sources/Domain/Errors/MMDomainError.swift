public enum MMDomainError: Error, Sendable, Hashable {
    case notFound
    case unauthorized
    case permissionDenied
    case network(String)
    case invalidInput(String)
    case unknown(String)

    /// ADR-304 — 게스트 사용자 cap 초과. UI는 본 에러 수신 시 LoginIntent 시트 표시.
    case guestCapExceeded(GuestCapKind)

    /// ADR-304 — 익명 사용자가 정식 자원에 접근 시도. Functions `AUTH_ANONYMOUS_FORBIDDEN` 매핑.
    case anonymousForbidden(GuestGatedAction)
}

/// ADR-304 — 게스트 cap 종류. 위시리스트 5개 / (예약) 도감 N개.
public enum GuestCapKind: String, Sendable, Hashable, CaseIterable {
    case wishlist
    case collection
}

/// ADR-304 — 익명 사용자가 막혀야 할 액션 종류. UI가 LoginIntent로 매핑.
public enum GuestGatedAction: String, Sendable, Hashable, CaseIterable {
    case writeReview
    case addCollectionItem
    case requestFriend
    case acceptFriend
    case verifyRewardedAd
    case registerPushToken
    case viewOtherProfile
}
