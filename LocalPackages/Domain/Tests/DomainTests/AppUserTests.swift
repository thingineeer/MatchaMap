import XCTest
@testable import Domain

final class AppUserTests: XCTestCase {

    func test_init_withRequiredFields_succeeds() {
        let user = AppUser.fixture()
        XCTAssertEqual(user.uid, "test-uid")
        XCTAssertFalse(user.isTraveling)
        XCTAssertEqual(user.authMethod, .apple)
    }

    func test_travelMode_isTrueWhenCountryDiffersFromHome() {
        let kr = Country(rawValue: "KR")!
        let jp = Country(rawValue: "JP")!
        let user = AppUser.fixture(homeCountry: kr, country: jp)
        XCTAssertTrue(user.isTraveling)
    }

    func test_travelMode_isFalseWhenCountryMatchesHome() {
        let kr = Country(rawValue: "KR")!
        let user = AppUser.fixture(homeCountry: kr, country: kr)
        XCTAssertFalse(user.isTraveling)
    }

    func test_travelMode_isFalseWhenCountryUnknown() {
        let kr = Country(rawValue: "KR")!
        let user = AppUser.fixture(homeCountry: kr, country: nil)
        XCTAssertFalse(user.isTraveling)
    }

    func test_codable_roundTrip() throws {
        let original = AppUser.fixture()
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppUser.self, from: encoded)
        XCTAssertEqual(decoded, original)
    }
}
