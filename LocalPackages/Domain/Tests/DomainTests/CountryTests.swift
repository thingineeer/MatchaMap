import XCTest
@testable import Domain

final class CountryTests: XCTestCase {

    func test_init_withValidISO3166Alpha2_succeeds() {
        XCTAssertEqual(Country(rawValue: "KR")?.rawValue, "KR")
        XCTAssertEqual(Country(rawValue: "JP")?.rawValue, "JP")
        XCTAssertEqual(Country(rawValue: "US")?.rawValue, "US")
    }

    func test_init_lowercaseInput_isNormalizedToUppercase() {
        XCTAssertEqual(Country(rawValue: "kr")?.rawValue, "KR")
        XCTAssertEqual(Country(rawValue: "Jp")?.rawValue, "JP")
    }

    func test_init_invalidLength_returnsNil() {
        XCTAssertNil(Country(rawValue: ""))
        XCTAssertNil(Country(rawValue: "K"))
        XCTAssertNil(Country(rawValue: "KOR"))
    }

    func test_init_nonAlphabetic_returnsNil() {
        XCTAssertNil(Country(rawValue: "K1"))
        XCTAssertNil(Country(rawValue: "12"))
        XCTAssertNil(Country(rawValue: "K!"))
    }

    func test_codable_roundTrip() throws {
        let original = Country(rawValue: "KR")!
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Country.self, from: encoded)
        XCTAssertEqual(decoded, original)
    }
}
