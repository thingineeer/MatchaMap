import Foundation

/// Preview/Test 양쪽에서 재사용하는 stub.
/// Tests가 아닌 Sources에 두어 Feature 모듈의 #Preview에서도 참조 가능.
/// 운영 빌드에서도 import되긴 하나 stub 데이터 외 부수효과 없음(번들 크기 미미).
public final class MockStoreRepository: StoreRepository, @unchecked Sendable {

    public var stubStore: Store?
    public var stubStores: [Store] = []
    public var stubError: Error?

    /// 호출 횟수 — 테스트에서 검증용.
    public private(set) var storeDetailsCallCount: Int = 0
    public private(set) var lastRequestedID: String?

    public init() {}

    public func storeDetails(id: String) async throws -> Store {
        storeDetailsCallCount += 1
        lastRequestedID = id
        if let stubError { throw stubError }
        if let stubStore { return stubStore }
        return Store.preview(id: id)
    }

    public func storesInBounds(_ bounds: BoundingBox) async throws -> [Store] {
        if let stubError { throw stubError }
        return stubStores
    }
}

public extension Store {
    /// Preview/Test 픽스처. 의도된 더미 값.
    static func preview(
        id: String = "preview-1",
        name: String = "Matcha House Seoul",
        matchaScore: Double = 4.7,
        countryCode: String = "KR"
    ) -> Store {
        Store(
            id: id,
            name: name,
            location: Coordinate(latitude: 37.5665, longitude: 126.9780),
            grade: .from(matchaScore: matchaScore),
            matchaScore: matchaScore,
            countryCode: countryCode,
            city: "Seoul",
            address: "Seoul, Jongno-gu",
            photoURLs: [],
            primaryPhotoURL: nil,
            coverPhotoURL: nil,
            priceLevel: 3,
            openingHours: nil,
            pinTier: matchaScore >= 4.5 ? .S : .A,
            origin: StoreOrigin(region: "uji", country: "JP", grade: "ceremonial"),
            reviewCount: 128,
            ratingAvg: matchaScore,
            ratingHistogram: [5: 80, 4: 30, 3: 10, 2: 5, 1: 3],
            tagsTop: ["usucha", "traditional", "umami"],
            verified: true
        )
    }

    /// 테스트용 fixture — preview의 alias.
    static func fixture(
        id: String = "fix-1",
        name: String = "Test Store",
        matchaScore: Double = 4.0,
        countryCode: String = "KR"
    ) -> Store {
        preview(id: id, name: name, matchaScore: matchaScore, countryCode: countryCode)
    }
}
