import XCTest
@testable import Domain

final class BoundingBoxTests: XCTestCase {

    func test_contains_pointInsideBounds() {
        let sw = Coordinate(latitude: 37.0, longitude: 126.0)
        let ne = Coordinate(latitude: 38.0, longitude: 128.0)
        let box = BoundingBox(southWest: sw, northEast: ne)
        XCTAssertTrue(box.contains(Coordinate(latitude: 37.5, longitude: 127.0)))
    }

    func test_contains_pointOnBoundaryIsIncluded() {
        let sw = Coordinate(latitude: 37.0, longitude: 126.0)
        let ne = Coordinate(latitude: 38.0, longitude: 128.0)
        let box = BoundingBox(southWest: sw, northEast: ne)
        XCTAssertTrue(box.contains(sw))
        XCTAssertTrue(box.contains(ne))
    }

    func test_contains_pointOutsideBounds() {
        let sw = Coordinate(latitude: 37.0, longitude: 126.0)
        let ne = Coordinate(latitude: 38.0, longitude: 128.0)
        let box = BoundingBox(southWest: sw, northEast: ne)
        XCTAssertFalse(box.contains(Coordinate(latitude: 36.0, longitude: 127.0)))
        XCTAssertFalse(box.contains(Coordinate(latitude: 37.5, longitude: 125.0)))
    }
}
