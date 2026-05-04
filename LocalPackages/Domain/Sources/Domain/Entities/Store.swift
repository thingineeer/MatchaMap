import Foundation

public enum StoreGrade: String, Sendable, Codable, CaseIterable {
    case basic
    case premium
    case iconic

    /// 매장 매차스코어(0.0~5.0)에서 등급으로 매핑.
    /// 기준은 handoff-phase3-ios-map.md §4 합의 의제 — Phase 3에서 server-data와 최종 동기화.
    public static func from(matchaScore: Double) -> StoreGrade {
        switch matchaScore {
        case ..<3.5:        return .basic
        case 3.5..<4.5:     return .premium
        default:            return .iconic
        }
    }
}

public struct Store: Sendable, Hashable, Identifiable, Codable {
    public let id: String
    public let name: String
    public let location: Coordinate
    public let grade: StoreGrade
    public let matchaScore: Double
    public let countryCode: String      // ISO-3166 alpha-2
    public let address: String?
    public let photoURLs: [URL]

    public init(
        id: String,
        name: String,
        location: Coordinate,
        grade: StoreGrade,
        matchaScore: Double,
        countryCode: String,
        address: String? = nil,
        photoURLs: [URL] = []
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.grade = grade
        self.matchaScore = matchaScore
        self.countryCode = countryCode
        self.address = address
        self.photoURLs = photoURLs
    }
}
