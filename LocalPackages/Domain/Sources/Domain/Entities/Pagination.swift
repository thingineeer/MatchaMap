import Foundation

/// Cursor-based 페이지네이션 — ADR-302 D5.
/// offset/page 사용 금지. 모든 리스트 화면 공통 사용.
public struct PaginationCursor: Sendable, Hashable, Codable {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }
}

public struct Page<Item: Sendable & Hashable>: Sendable, Hashable {
    public let items: [Item]
    public let nextCursor: PaginationCursor?

    public init(items: [Item], nextCursor: PaginationCursor? = nil) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

extension Page: Codable where Item: Codable {}

/// 사용자 통계 디노멀 — schema.md §1.4 + 프로필 single read.
public struct UserStats: Sendable, Hashable, Codable {
    public let collectionCount: Int
    public let reviewCount: Int
    public let wishlistCount: Int
    public let friendCount: Int

    public init(
        collectionCount: Int = 0,
        reviewCount: Int = 0,
        wishlistCount: Int = 0,
        friendCount: Int = 0
    ) {
        self.collectionCount = collectionCount
        self.reviewCount = reviewCount
        self.wishlistCount = wishlistCount
        self.friendCount = friendCount
    }

    public static let zero = UserStats()
}
