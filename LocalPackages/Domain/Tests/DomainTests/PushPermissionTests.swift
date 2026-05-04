import XCTest
@testable import Domain

final class PushPermissionTests: XCTestCase {

    func test_canDeliver_whenGranted() {
        let p = PushPermission(status: .granted, soundEnabled: true, alertEnabled: true, badgeEnabled: true)
        XCTAssertTrue(p.canDeliver)
    }

    func test_canDeliver_whenProvisional() {
        let p = PushPermission(status: .provisional, soundEnabled: false, alertEnabled: true, badgeEnabled: false)
        XCTAssertTrue(p.canDeliver)
    }

    func test_canDeliver_falseWhenDenied() {
        let p = PushPermission(status: .denied, soundEnabled: false, alertEnabled: false, badgeEnabled: false)
        XCTAssertFalse(p.canDeliver)
    }

    func test_canDeliver_falseWhenNotDetermined() {
        let p = PushPermission.notDetermined
        XCTAssertFalse(p.canDeliver)
    }
}
