import XCTest
@testable import Domain

final class OpeningHoursTests: XCTestCase {

    func test_isClosed_whenSlotMissingOrEmpty() {
        let oh = OpeningHours(slots: [
            .mon: [OpeningHours.Slot(open: "09:00", close: "21:00")],
            .tue: []
        ])

        XCTAssertFalse(oh.isClosed(on: .mon))
        XCTAssertTrue(oh.isClosed(on: .tue), "empty slots = closed")
        XCTAssertTrue(oh.isClosed(on: .sun), "missing day = closed")
    }
}
