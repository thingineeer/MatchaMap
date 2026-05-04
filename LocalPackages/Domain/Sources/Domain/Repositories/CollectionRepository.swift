import Foundation

/// schema.md §5 collections + §1.4 stats. fanout 책임은 Functions.
/// 클라 직접 write 금지 — `addCollectionItem` 콜러블 통과.
public protocol CollectionRepository: Sendable {
    /// 사용자 도감 목록 (cursor 페이지네이션, 디폴트 20).
    func items(uid: String, cursor: PaginationCursor?, limit: Int) async throws -> Page<CollectionItem>

    /// 단일 아이템 (메모리 페이지 진입).
    func item(uid: String, itemId: String) async throws -> CollectionItem

    /// 도감 추가 — 콜러블 `addCollectionItem` 매핑.
    /// schema.md §5.5 fanout. 응답: 신규 itemId + 갱신 후 collectionCount.
    func add(_ draft: CollectionItemDraft) async throws -> AddCollectionItemResult

    /// 메모 / 사진 / colorTier 등 일부 필드만 갱신.
    func update(uid: String, itemId: String, patch: CollectionItemPatch) async throws

    /// 삭제 — Functions가 collectionCount -1 + feed_events fanoutStatus invalidate.
    func remove(uid: String, itemId: String) async throws
}

/// 사용자 입력 폼. server 콜러블 페이로드 1:1 매핑.
public struct CollectionItemDraft: Sendable, Hashable, Codable {
    public let storeId: String
    public let drink: CollectionItem.Drink
    public let grade: CollectionItem.Grade?
    public let originRegion: CollectionItem.OriginRegion?
    public let colorTier: CollectionItem.ColorTier?
    public let note: String?
    public let photoURLs: [URL]
    public let visitedAt: Date?
    public let viaReview: Bool
    public let linkedReviewId: String?

    public init(
        storeId: String,
        drink: CollectionItem.Drink,
        grade: CollectionItem.Grade? = nil,
        originRegion: CollectionItem.OriginRegion? = nil,
        colorTier: CollectionItem.ColorTier? = nil,
        note: String? = nil,
        photoURLs: [URL] = [],
        visitedAt: Date? = nil,
        viaReview: Bool = false,
        linkedReviewId: String? = nil
    ) {
        self.storeId = storeId
        self.drink = drink
        self.grade = grade
        self.originRegion = originRegion
        self.colorTier = colorTier
        self.note = note
        self.photoURLs = photoURLs
        self.visitedAt = visitedAt
        self.viaReview = viaReview
        self.linkedReviewId = linkedReviewId
    }
}

public struct CollectionItemPatch: Sendable, Hashable, Codable {
    public let note: String?
    public let grade: CollectionItem.Grade?
    public let originRegion: CollectionItem.OriginRegion?
    public let colorTier: CollectionItem.ColorTier?
    public let photoURLs: [URL]?

    public init(
        note: String? = nil,
        grade: CollectionItem.Grade? = nil,
        originRegion: CollectionItem.OriginRegion? = nil,
        colorTier: CollectionItem.ColorTier? = nil,
        photoURLs: [URL]? = nil
    ) {
        self.note = note
        self.grade = grade
        self.originRegion = originRegion
        self.colorTier = colorTier
        self.photoURLs = photoURLs
    }
}

public struct AddCollectionItemResult: Sendable, Hashable, Codable {
    public let itemId: String
    public let collectionCount: Int

    public init(itemId: String, collectionCount: Int) {
        self.itemId = itemId
        self.collectionCount = collectionCount
    }
}
