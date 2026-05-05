import Foundation

public final class MockSearchRepository: SearchRepository, @unchecked Sendable {

    public var stubPage: SearchPage = .empty
    public var stubError: Error?

    public private(set) var callCount: Int = 0
    public private(set) var lastQuery: StoreSearchQuery?

    public init() {}

    public func searchStores(_ query: StoreSearchQuery) async throws -> SearchPage {
        callCount += 1
        lastQuery = query
        if let stubError { throw stubError }
        return stubPage
    }
}

public extension SearchResult {
    static func preview(
        storeId: String? = "preview-1",
        name: String = "말차하우스",
        countryCode: String = "KR",
        city: String? = "Seoul",
        rating: Double? = 4.6,
        pinTier: StorePinTier? = .S,
        isFirstParty: Bool = true
    ) -> SearchResult {
        SearchResult(
            storeId: storeId,
            placeId: storeId,
            name: name,
            location: Coordinate(latitude: 37.5665, longitude: 126.9780),
            countryCode: countryCode,
            city: city,
            rating: rating,
            isFirstParty: isFirstParty,
            primaryPhotoURL: nil,
            pinTier: pinTier
        )
    }
}
