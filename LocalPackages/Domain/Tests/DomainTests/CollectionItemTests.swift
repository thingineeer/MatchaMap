import Testing
import Foundation
@testable import Domain

@Suite("CollectionItem entity / colorTier 5tier / origin enums")
struct CollectionItemTests {
    @Test("colorTier ordered 5단계 — MMColor 토큰 1:1")
    func colorTierFiveSteps() {
        let ordered = CollectionItem.ColorTier.allOrdered
        #expect(ordered.count == 5)
        #expect(ordered == [.matchaSoft, .matchaPale, .matcha, .deepMatcha, .deep])
    }

    @Test("originRegion enum 9종 정합 — uji/nishio/kagoshima/shizuoka/boseong/hadong/jeju/other/unknown")
    func originRegionEnumParity() {
        let names = Set(CollectionItem.OriginRegion.allCases.map(\.rawValue))
        #expect(names == ["uji", "nishio", "kagoshima", "shizuoka", "boseong", "hadong", "jeju", "other", "unknown"])
        // ADR-302 v1.1 jeju 추가 핵심.
        #expect(CollectionItem.OriginRegion.jeju.rawValue == "jeju")
    }

    @Test("grade enum — culinary 통합(cooking 폐기) + unknown")
    func gradeEnumCulinaryNotCooking() {
        let names = Set(CollectionItem.Grade.allCases.map(\.rawValue))
        #expect(names == ["ceremonial", "premium", "standard", "culinary", "unknown"])
        #expect(!names.contains("cooking"))
    }

    @Test("drink enum schema rawValue 정합")
    func drinkEnumRawValues() {
        #expect(CollectionItem.Drink.matchaLatte.rawValue == "matcha_latte")
        #expect(CollectionItem.Drink.matchaDessert.rawValue == "matcha_dessert")
        #expect(CollectionItem.Drink.icedMatcha.rawValue == "iced_matcha")
    }

    @Test("Codable round-trip 보존 — colorTier 포함")
    func codableRoundTrip() throws {
        let item = CollectionItem.fixture(originRegion: .jeju, colorTier: .deepMatcha)
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(CollectionItem.self, from: data)
        #expect(decoded == item)
    }
}
