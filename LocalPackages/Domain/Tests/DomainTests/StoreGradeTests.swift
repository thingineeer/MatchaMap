import XCTest
@testable import Domain

final class StoreGradeTests: XCTestCase {

    func test_from_matchaScore_lowScore_isBasic() {
        XCTAssertEqual(StoreGrade.from(matchaScore: 0.0), .basic)
        XCTAssertEqual(StoreGrade.from(matchaScore: 3.49), .basic)
    }

    func test_from_matchaScore_midScore_isPremium() {
        XCTAssertEqual(StoreGrade.from(matchaScore: 3.5), .premium)
        XCTAssertEqual(StoreGrade.from(matchaScore: 4.49), .premium)
    }

    func test_from_matchaScore_highScore_isIconic() {
        XCTAssertEqual(StoreGrade.from(matchaScore: 4.5), .iconic)
        XCTAssertEqual(StoreGrade.from(matchaScore: 5.0), .iconic)
    }
}
