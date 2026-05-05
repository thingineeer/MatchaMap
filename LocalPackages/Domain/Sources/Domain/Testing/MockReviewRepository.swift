import Foundation

public final class MockReviewRepository: ReviewRepository, @unchecked Sendable {

    public var stubPage: ReviewPage = .empty
    public var stubError: Error?
    public var stubWriteResult: String = "rev_preview_1"

    public private(set) var reviewsCallCount: Int = 0
    public private(set) var lastStoreId: String?
    public private(set) var lastSort: ReviewSortOrder?
    public private(set) var lastLimit: Int?
    public private(set) var lastCursor: String?

    public private(set) var writeCallCount: Int = 0
    public private(set) var lastDraft: ReviewDraft?

    public init() {}

    public func reviews(
        storeId: String,
        sort: ReviewSortOrder,
        limit: Int,
        cursor: String?
    ) async throws -> ReviewPage {
        reviewsCallCount += 1
        lastStoreId = storeId
        lastSort = sort
        lastLimit = limit
        lastCursor = cursor
        if let stubError { throw stubError }
        return stubPage
    }

    public func writeReview(_ draft: ReviewDraft) async throws -> String {
        writeCallCount += 1
        lastDraft = draft
        if let stubError { throw stubError }
        return stubWriteResult
    }
}

public extension Review {
    /// Preview/Test fixture.
    static func preview(
        id: String = "rev-1",
        storeId: String = "preview-1",
        rating: Int = 5,
        body: String = "최고의 우스차였어요. 거품이 정말 곱고 향이 진합니다.",
        country: String = "KR",
        authorName: String = "말차러버",
        storeName: String = "Matcha House Seoul",
        likeCount: Int = 0
    ) -> Review {
        Review(
            id: id,
            storeId: storeId,
            uid: "uid-preview",
            rating: rating,
            body: body,
            photos: [],
            tags: [.usucha, .traditional],
            drink: .usucha,
            country: country,
            author: ReviewAuthor(uid: "uid-preview", displayName: authorName),
            store: ReviewStoreSnapshot(placeId: storeId, name: storeName, city: "Seoul", country: country),
            likeCount: likeCount,
            createdAt: Date(timeIntervalSince1970: 1_756_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_756_000_000)
        )
    }

    static func fixture(
        id: String = "rev-fix",
        storeId: String = "fix-1",
        rating: Int = 4,
        body: String = "Test review body."
    ) -> Review {
        preview(id: id, storeId: storeId, rating: rating, body: body)
    }
}
