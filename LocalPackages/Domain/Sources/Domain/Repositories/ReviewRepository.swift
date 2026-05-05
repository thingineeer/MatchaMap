import Foundation

/// schema.md §3 reviews + §10 collection group queries 정합.
public protocol ReviewRepository: Sendable {
    /// 매장별 리뷰 페이지. cursor-based 페이지네이션 (ADR-302 D5).
    /// - Parameters:
    ///   - storeId: 매장 placeId.
    ///   - sort: 최신/별점/도움순.
    ///   - limit: 디폴트 20.
    ///   - cursor: 마지막 doc id 또는 null (첫 페이지).
    func reviews(
        storeId: String,
        sort: ReviewSortOrder,
        limit: Int,
        cursor: String?
    ) async throws -> ReviewPage

    /// 리뷰 작성. 사진은 사전 업로드 후 URL을 draft.photos로 전달.
    /// 반환: 작성된 reviewId.
    @discardableResult
    func writeReview(_ draft: ReviewDraft) async throws -> String
}

/// cursor-based 페이지 결과 — schema §0.4.
public struct ReviewPage: Sendable, Hashable, Codable {
    public let items: [Review]
    public let nextCursor: String?

    public init(items: [Review], nextCursor: String?) {
        self.items = items
        self.nextCursor = nextCursor
    }

    public static let empty = ReviewPage(items: [], nextCursor: nil)
}
