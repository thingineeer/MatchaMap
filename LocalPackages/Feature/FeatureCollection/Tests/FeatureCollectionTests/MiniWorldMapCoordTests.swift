import Testing
import Foundation
import DesignSystem
@testable import FeatureCollection

@Suite("MiniWorldMap / 원산지 좌표 정합")
struct MiniWorldMapCoordTests {

    @Test("8 origin region (uji/nishio/shizuoka/kagoshima/boseong/hadong/jeju) 모두 좌표 존재")
    func allKnownOriginsHaveCoords() {
        let known = ["uji", "nishio", "shizuoka", "kagoshima", "boseong", "hadong", "jeju"]
        for r in known {
            #expect(MatchaOriginCoords.coord(for: r) != nil, "\(r) coord must exist")
        }
    }

    @Test("other / unknown / nil → 좌표 없음 (mini-map 표시 X)")
    func unknownOriginsHaveNoCoords() {
        #expect(MatchaOriginCoords.coord(for: "other") == nil)
        #expect(MatchaOriginCoords.coord(for: "unknown") == nil)
        #expect(MatchaOriginCoords.coord(for: nil) == nil)
        #expect(MatchaOriginCoords.coord(for: "") == nil)
    }

    @Test("normalizedPosition — equirectangular 투영 정합 (lng=0, lat=0 → x=0.5, y=0.5)")
    func equirectangularProjection() {
        let center = GeoCoord(latitude: 0, longitude: 0)
        let pos = MatchaOriginCoords.normalizedPosition(for: center)
        #expect(abs(pos.x - 0.5) < 0.001)
        #expect(abs(pos.y - 0.5) < 0.001)
    }

    @Test("동/서 끝 좌표 — lng=180 → x≈1, lng=-180 → x≈0")
    func longitudeBounds() {
        let east = MatchaOriginCoords.normalizedPosition(for: GeoCoord(latitude: 0, longitude: 180))
        let west = MatchaOriginCoords.normalizedPosition(for: GeoCoord(latitude: 0, longitude: -180))
        #expect(abs(east.x - 1.0) < 0.001)
        #expect(abs(west.x - 0.0) < 0.001)
    }

    @Test("우지 좌표 검증 — lat≈34.88, lng≈135.80 (kyoto)")
    func ujiCoordIsValid() {
        let uji = MatchaOriginCoords.coord(for: "uji")!
        #expect(abs(uji.latitude - 34.88) < 0.5)
        #expect(abs(uji.longitude - 135.80) < 0.5)
    }

    @Test("WishlistViewModel.countryCenter — 6개 마켓(KR/JP/US/GB/DE/FR) 모두 매핑")
    func countryCenterCoversAllMVPMarkets() {
        let markets = ["KR", "JP", "US", "GB", "DE", "FR"]
        for m in markets {
            #expect(WishlistViewModel.countryCenter(for: m) != nil, "\(m) center must exist")
        }
        #expect(WishlistViewModel.countryCenter(for: "ZZ") == nil)
    }
}
