// Core — 가장 아래 레이어. Foundation/OSLog만 의존.
//
// 본 파일은 모듈 진입점. 실제 타입은 하위 폴더로 확장 예정:
// - Logger (OSLog 래퍼, subsystem = AppEnvironment.bundleIdentifier)
// - AppEnvironment (Bundle 정보, build/version)
// - HTTPClient protocol (URLSession 구현은 Data에)

import Foundation
import OSLog

public enum Core {
    public static let version: String = "0.1.0"
}

public enum LogCategory: String, Sendable {
    case app
    case data
    case ui
    case analytics
    case ads
}

public struct AppLogger: Sendable {
    private let logger: Logger

    public init(category: LogCategory, subsystem: String = "th1ngjin.MatchaMap") {
        self.logger = Logger(subsystem: subsystem, category: category.rawValue)
    }

    public func debug(_ message: String) { logger.debug("\(message, privacy: .public)") }
    public func info(_ message: String) { logger.info("\(message, privacy: .public)") }
    public func error(_ message: String) { logger.error("\(message, privacy: .public)") }
}

public protocol HTTPClient: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}
