import Foundation

/// 리뷰 태그 — schema.md §3.1 reviews.tags enum.
public enum ReviewTag: String, Sendable, Codable, CaseIterable {
    case koicha
    case usucha
    case latte
    case dessert
    case bitter
    case sweet
    case umami
    case traditional
    case modern
    case instagrammable
}

/// 리뷰 음료 종류 — schema.md §3.1 reviews.drink enum.
public enum ReviewDrink: String, Sendable, Codable, CaseIterable {
    case usucha
    case koicha
    case matchaLatte = "matcha_latte"
    case icedMatcha = "iced_matcha"
    case dessert
    case other
}

/// 리뷰 작성자 디노멀 — schema.md §3.1 reviews.author{}.
public struct ReviewAuthor: Sendable, Hashable, Codable {
    public let uid: String
    public let displayName: String
    public let photoURL: URL?

    public init(uid: String, displayName: String, photoURL: URL? = nil) {
        self.uid = uid
        self.displayName = displayName
        self.photoURL = photoURL
    }
}

/// 리뷰 매장 디노멀 — schema.md §3.1 reviews.store{}.
public struct ReviewStoreSnapshot: Sendable, Hashable, Codable {
    public let placeId: String
    public let name: String
    public let city: String
    public let country: String           // ISO-3166 alpha-2
    public let primaryPhotoURL: URL?

    public init(placeId: String, name: String, city: String, country: String, primaryPhotoURL: URL? = nil) {
        self.placeId = placeId
        self.name = name
        self.city = city
        self.country = country
        self.primaryPhotoURL = primaryPhotoURL
    }
}

public struct Review: Sendable, Hashable, Identifiable, Codable {
    public let id: String                // reviewId (ULID)
    public let storeId: String
    public let uid: String
    public let rating: Int               // 1~5
    public let body: String              // 1~2000 chars
    public let photos: [URL]             // 0~4 items
    public let tags: [ReviewTag]
    public let drink: ReviewDrink?
    public let country: String           // ISO-3166 alpha-2 (디노멀 from stores.country)
    public let author: ReviewAuthor
    public let store: ReviewStoreSnapshot
    public let likeCount: Int
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: String,
        storeId: String,
        uid: String,
        rating: Int,
        body: String,
        photos: [URL] = [],
        tags: [ReviewTag] = [],
        drink: ReviewDrink? = nil,
        country: String,
        author: ReviewAuthor,
        store: ReviewStoreSnapshot,
        likeCount: Int = 0,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.storeId = storeId
        self.uid = uid
        self.rating = rating
        self.body = body
        self.photos = photos
        self.tags = tags
        self.drink = drink
        self.country = country
        self.author = author
        self.store = store
        self.likeCount = likeCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// 리뷰 정렬 기준 — handoff-mapping.md 화면 8 (최신/별점/도움순).
public enum ReviewSortOrder: String, Sendable, Codable, CaseIterable {
    case latest      // createdAt DESC (인덱스 storeId+createdAt)
    case rating      // rating DESC, createdAt DESC (인덱스 storeId+rating+createdAt)
    case helpful     // likeCount DESC, createdAt DESC
}

/// 리뷰 작성 입력 — WriteReviewUseCase 입력.
public struct ReviewDraft: Sendable, Hashable {
    public let storeId: String
    public let rating: Int
    public let body: String
    public let photos: [URL]
    public let tags: [ReviewTag]
    public let drink: ReviewDrink?

    public init(
        storeId: String,
        rating: Int,
        body: String,
        photos: [URL] = [],
        tags: [ReviewTag] = [],
        drink: ReviewDrink? = nil
    ) {
        self.storeId = storeId
        self.rating = rating
        self.body = body
        self.photos = photos
        self.tags = tags
        self.drink = drink
    }
}
