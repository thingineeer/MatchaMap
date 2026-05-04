import XCTest
@testable import Data
import Foundation

final class URLSessionHTTPClientTests: XCTestCase {

    func test_init_doesNotCrash() {
        _ = URLSessionHTTPClient()
        // Phase 3에서 URLProtocol stub로 send(...) 동작을 검증.
        XCTAssertTrue(true)
    }
}
