import XCTest
@testable import FeatureSocial

final class FeatureSocialTests: XCTestCase {
    func test_version_isStable() {
        XCTAssertEqual(FeatureSocial.version, "0.2.0")
    }
}
