import XCTest
@testable import FeatureCollection

final class FeatureCollectionTests: XCTestCase {
    func test_version_isStable() {
        XCTAssertEqual(FeatureCollection.version, "0.1.0")
    }
}
