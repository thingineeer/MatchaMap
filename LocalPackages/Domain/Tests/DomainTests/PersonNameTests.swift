import XCTest
@testable import Domain

final class PersonNameTests: XCTestCase {

    func test_displayName_prefersNicknameWhenSet() {
        let name = PersonName(givenName: "Jin", familyName: "Lee", nickname: "MatchaFan")
        XCTAssertEqual(name.displayName, "MatchaFan")
    }

    func test_displayName_fallsBackToGivenAndFamily() {
        let name = PersonName(givenName: "Jin", familyName: "Lee", nickname: nil)
        XCTAssertEqual(name.displayName, "Jin Lee")
    }

    func test_displayName_usesGivenOnlyWhenFamilyMissing() {
        let name = PersonName(givenName: "Jin", familyName: nil, nickname: nil)
        XCTAssertEqual(name.displayName, "Jin")
    }

    func test_displayName_returnsNilWhenAllEmpty() {
        let name = PersonName(givenName: nil, familyName: nil, nickname: nil)
        XCTAssertNil(name.displayName)
    }

    func test_isEmpty_whenAllNil() {
        XCTAssertTrue(PersonName(givenName: nil, familyName: nil, nickname: nil).isEmpty)
        XCTAssertFalse(PersonName(givenName: "Jin", familyName: nil, nickname: nil).isEmpty)
    }
}
