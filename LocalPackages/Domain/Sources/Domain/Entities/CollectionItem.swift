import Foundation

/// 도감(컬렉션) 카드. schema.md §5 collections/{uid}/items/{itemId} 매핑.
/// ADR-302 v1.1 colorTier 5단계 + jeju 추가 정합.
public struct CollectionItem: Sendable, Hashable, Identifiable, Codable {
    public let id: String                      // ULID == itemId == doc.id
    public let uid: String
    public let storeId: String                 // Google Place ID
    public let drink: Drink
    public let grade: Grade?
    public let originRegion: OriginRegion?
    public let colorTier: ColorTier?
    public let colorHex: String?               // 렌더용 mirror; colorTier 저장 시 Functions가 채움
    public let note: String?
    public let photoURLs: [URL]
    public let countryCode: String             // ISO-3166 alpha-2 디노멀
    public let store: StoreSnapshot
    public let viaReview: Bool
    public let linkedReviewId: String?
    public let visitedAt: Date
    public let createdAt: Date

    public init(
        id: String,
        uid: String,
        storeId: String,
        drink: Drink,
        grade: Grade? = nil,
        originRegion: OriginRegion? = nil,
        colorTier: ColorTier? = nil,
        colorHex: String? = nil,
        note: String? = nil,
        photoURLs: [URL] = [],
        countryCode: String,
        store: StoreSnapshot,
        viaReview: Bool = false,
        linkedReviewId: String? = nil,
        visitedAt: Date,
        createdAt: Date
    ) {
        self.id = id
        self.uid = uid
        self.storeId = storeId
        self.drink = drink
        self.grade = grade
        self.originRegion = originRegion
        self.colorTier = colorTier
        self.colorHex = colorHex
        self.note = note
        self.photoURLs = photoURLs
        self.countryCode = countryCode
        self.store = store
        self.viaReview = viaReview
        self.linkedReviewId = linkedReviewId
        self.visitedAt = visitedAt
        self.createdAt = createdAt
    }
}

public extension CollectionItem {
    enum Drink: String, Sendable, Codable, CaseIterable, Hashable {
        case usucha
        case koicha
        case matchaLatte = "matcha_latte"
        case icedMatcha = "iced_matcha"
        case matchaDessert = "matcha_dessert"
        case other
    }

    enum Grade: String, Sendable, Codable, CaseIterable, Hashable {
        case ceremonial
        case premium
        case standard
        case culinary
        case unknown
    }

    /// schema.md §5.1 + ADR-302 v1.1 — `stores.origin.region` enum 정합 + `jeju` 추가 + `unknown`.
    enum OriginRegion: String, Sendable, Codable, CaseIterable, Hashable {
        case uji
        case nishio
        case kagoshima
        case shizuoka
        case boseong
        case hadong
        case jeju
        case other
        case unknown
    }

    /// schema.md §5.1 v1.1 — 5단계 색감 enum. MMColor 5단계 토큰과 1:1.
    /// 사용자 입력 단순화 + 분석/필터 효율 (designer-lead Q2 합의).
    enum ColorTier: String, Sendable, Codable, CaseIterable, Hashable {
        case matchaSoft
        case matchaPale
        case matcha
        case deepMatcha
        case deep

        public static let allOrdered: [ColorTier] = [
            .matchaSoft, .matchaPale, .matcha, .deepMatcha, .deep
        ]
    }
}

/// 도감/위시리스트/피드에 디노멀 복제되는 매장 스냅샷.
/// schema.md §5.1 / §4.1 / §7.1 store map.
public struct StoreSnapshot: Sendable, Hashable, Codable {
    public let placeId: String
    public let name: String
    public let city: String
    public let countryCode: String
    public let primaryPhotoURL: URL?

    public init(
        placeId: String,
        name: String,
        city: String,
        countryCode: String,
        primaryPhotoURL: URL? = nil
    ) {
        self.placeId = placeId
        self.name = name
        self.city = city
        self.countryCode = countryCode
        self.primaryPhotoURL = primaryPhotoURL
    }
}
