import Foundation

/// 검색 결과 단건 — api-contract.md §2.2 mergeStoreSearch.SearchResult 정합.
public struct SearchResult: Sendable, Hashable, Identifiable, Codable {
    public var id: String { storeId ?? placeId ?? name }

    public let storeId: String?
    public let placeId: String?
    public let name: String
    public let location: Coordinate
    public let countryCode: String      // ISO-3166 alpha-2
    public let city: String?
    public let rating: Double?
    public let isFirstParty: Bool       // true = 자사 매장(stores 컬렉션)
    public let primaryPhotoURL: URL?
    public let pinTier: StorePinTier?

    public init(
        storeId: String?,
        placeId: String?,
        name: String,
        location: Coordinate,
        countryCode: String,
        city: String? = nil,
        rating: Double? = nil,
        isFirstParty: Bool,
        primaryPhotoURL: URL? = nil,
        pinTier: StorePinTier? = nil
    ) {
        self.storeId = storeId
        self.placeId = placeId
        self.name = name
        self.location = location
        self.countryCode = countryCode
        self.city = city
        self.rating = rating
        self.isFirstParty = isFirstParty
        self.primaryPhotoURL = primaryPhotoURL
        self.pinTier = pinTier
    }
}

/// 검색 페이지 — cursor-based.
public struct SearchPage: Sendable, Hashable, Codable {
    public let results: [SearchResult]
    public let nextCursor: String?

    public init(results: [SearchResult], nextCursor: String?) {
        self.results = results
        self.nextCursor = nextCursor
    }

    public static let empty = SearchPage(results: [], nextCursor: nil)
}

/// 검색 필터 — handoff-mapping.md 화면 9 + ios-store agent 책임 §5.
public struct StoreSearchFilters: Sendable, Hashable, Codable {
    public var pinTiers: Set<StorePinTier>      // 등급 (S/A/B/C)
    public var drinks: Set<ReviewDrink>          // 메뉴 종류 (usucha/koicha/latte/...)
    public var priceLevels: Set<Int>             // 가격대 1~4
    public var maxDistanceMeters: Double?        // 거리 (현재 위치 기준)
    public var openNow: Bool                     // 오픈 여부

    public init(
        pinTiers: Set<StorePinTier> = [],
        drinks: Set<ReviewDrink> = [],
        priceLevels: Set<Int> = [],
        maxDistanceMeters: Double? = nil,
        openNow: Bool = false
    ) {
        self.pinTiers = pinTiers
        self.drinks = drinks
        self.priceLevels = priceLevels
        self.maxDistanceMeters = maxDistanceMeters
        self.openNow = openNow
    }

    public static let none = StoreSearchFilters()

    public var isActive: Bool {
        !pinTiers.isEmpty || !drinks.isEmpty || !priceLevels.isEmpty || maxDistanceMeters != nil || openNow
    }
}

/// SearchStoresUseCase 입력. mergeStoreSearch 계약과 1:1.
public struct StoreSearchQuery: Sendable, Hashable, Codable {
    public let query: String              // 1~100 chars
    public let viewport: BoundingBox?
    public let locale: String             // BCP-47
    public let filters: StoreSearchFilters
    public let maxResults: Int
    public let cursor: String?

    public init(
        query: String,
        viewport: BoundingBox? = nil,
        locale: String,
        filters: StoreSearchFilters = .none,
        maxResults: Int = 20,
        cursor: String? = nil
    ) {
        self.query = query
        self.viewport = viewport
        self.locale = locale
        self.filters = filters
        self.maxResults = maxResults
        self.cursor = cursor
    }
}
