import XCTest
@testable import DesignSystem

final class MMSpacingTests: XCTestCase {

    func test_spacingScale_isMonotonicallyIncreasing() {
        XCTAssertLessThan(MMSpacing.xs, MMSpacing.sm)
        XCTAssertLessThan(MMSpacing.sm, MMSpacing.md)
        XCTAssertLessThan(MMSpacing.md, MMSpacing.lg)
        XCTAssertLessThan(MMSpacing.lg, MMSpacing.xl)
    }
}
