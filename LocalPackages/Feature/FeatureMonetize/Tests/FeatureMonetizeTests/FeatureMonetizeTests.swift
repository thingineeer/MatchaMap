import XCTest
@testable import FeatureMonetize

final class FeatureMonetizeTests: XCTestCase {
    func test_version_isStable() {
        XCTAssertEqual(FeatureMonetize.version, "0.1.0")
    }
}
