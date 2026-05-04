import XCTest
@testable import Core

final class AppLoggerTests: XCTestCase {

    func test_init_doesNotCrash() {
        // OSLog는 부수효과만 있으므로 인스턴스화 자체가 깨지지 않는지만 본다.
        let logger = AppLogger(category: .app)
        logger.debug("init smoke")
        logger.info("init smoke")
        // 도달했으면 통과.
        XCTAssertTrue(true)
    }

    func test_logCategory_rawValuesStable() {
        XCTAssertEqual(LogCategory.app.rawValue, "app")
        XCTAssertEqual(LogCategory.data.rawValue, "data")
        XCTAssertEqual(LogCategory.ui.rawValue, "ui")
        XCTAssertEqual(LogCategory.analytics.rawValue, "analytics")
        XCTAssertEqual(LogCategory.ads.rawValue, "ads")
    }
}
