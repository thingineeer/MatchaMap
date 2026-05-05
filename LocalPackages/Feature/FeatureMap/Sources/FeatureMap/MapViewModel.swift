import Foundation
import Domain
import Observation

/// Map ViewModel — Phase 3 MVP는 mock 매장 5개를 도쿄+서울에 배치.
/// Phase 4/5에서 GMSMapView 교체 시 viewport 쿼리(`storesInBounds`)로 갱신.
@MainActor
@Observable
public final class MapViewModel {
    public private(set) var markers: [Store] = []
    public private(set) var error: String?

    public init() {
        self.markers = Self.bootstrapStores()
    }

    /// 도쿄+서울 5개 시드 매장 — Phase 3 placeholder. 실제 viewport 쿼리는 Phase 4.
    public static func bootstrapStores() -> [Store] {
        [
            Store(
                id: "seed-seoul-1",
                name: "Matcha House Seoul",
                location: Coordinate(latitude: 37.5665, longitude: 126.9780),
                grade: .iconic,
                matchaScore: 4.7,
                countryCode: "KR",
                city: "Seoul",
                address: "Seoul, Jongno-gu",
                pinTier: .S,
                origin: StoreOrigin(region: "uji", country: "JP", grade: "ceremonial"),
                reviewCount: 128,
                ratingAvg: 4.7,
                ratingHistogram: [5: 80, 4: 30, 3: 10, 2: 5, 1: 3],
                tagsTop: ["usucha", "umami"],
                verified: true
            ),
            Store(
                id: "seed-seoul-2",
                name: "우지 다실",
                location: Coordinate(latitude: 37.5172, longitude: 127.0473),
                grade: .premium,
                matchaScore: 4.3,
                countryCode: "KR",
                city: "Seoul",
                pinTier: .A,
                reviewCount: 64,
                ratingAvg: 4.3,
                tagsTop: ["traditional"]
            ),
            Store(
                id: "seed-tokyo-1",
                name: "茶寮 都路里",
                location: Coordinate(latitude: 35.6762, longitude: 139.6503),
                grade: .iconic,
                matchaScore: 4.8,
                countryCode: "JP",
                city: "Tokyo",
                pinTier: .S,
                reviewCount: 412,
                ratingAvg: 4.8,
                tagsTop: ["koicha", "traditional"]
            ),
            Store(
                id: "seed-tokyo-2",
                name: "Matcha Lab Shibuya",
                location: Coordinate(latitude: 35.6595, longitude: 139.7004),
                grade: .premium,
                matchaScore: 4.2,
                countryCode: "JP",
                city: "Tokyo",
                pinTier: .A,
                reviewCount: 88,
                ratingAvg: 4.2,
                tagsTop: ["modern", "latte"]
            ),
            Store(
                id: "seed-kyoto-1",
                name: "宇治園",
                location: Coordinate(latitude: 34.8841, longitude: 135.7997),
                grade: .iconic,
                matchaScore: 4.9,
                countryCode: "JP",
                city: "Kyoto",
                pinTier: .S,
                reviewCount: 622,
                ratingAvg: 4.9,
                tagsTop: ["koicha", "ceremonial"]
            )
        ]
    }
}
