import XCTest
@testable import FeatureStore

final class FeatureStoreTests: XCTestCase {
    func test_version_isStable() {
        XCTAssertEqual(FeatureStore.version, "0.1.0")
    }
}
