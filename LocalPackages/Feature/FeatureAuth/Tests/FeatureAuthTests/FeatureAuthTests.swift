import XCTest
@testable import FeatureAuth

final class FeatureAuthTests: XCTestCase {
    func test_version_isStable() {
        XCTAssertEqual(FeatureAuth.version, "0.1.0")
    }
}
