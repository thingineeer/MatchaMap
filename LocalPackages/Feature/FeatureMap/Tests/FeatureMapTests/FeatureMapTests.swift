import XCTest
@testable import FeatureMap

final class FeatureMapTests: XCTestCase {
    func test_version_isStable() {
        XCTAssertEqual(FeatureMap.version, "0.1.0")
    }
}
