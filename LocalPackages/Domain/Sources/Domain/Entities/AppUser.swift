import Foundation

/// 가입에 사용된 인증 방식. schema.md §1.1 `authMethod` enum 정합.
public enum AuthMethod: String, Sendable, Codable, CaseIterable {
    case apple
    case passkey
}

/// MatchaMap의 인증된 사용자 프로필.
/// schema.md §1 `users/{uid}`와 1:1 매핑. uid == doc.id == auth.uid 3중 invariant.
public struct AppUser: Sendable, Hashable, Identifiable, Codable {
    public let uid: String
    public let displayName: String
    public let photoURL: URL?
    public let locale: String        // BCP-47 (`ko-KR`)
    public let homeCountry: Country
    public let country: Country?
    public let cohortD0: Date
    public let authMethod: AuthMethod
    public let stats: UserStats
    public let createdAt: Date
    public let updatedAt: Date

    public var id: String { uid }

    public init(
        uid: String,
        displayName: String,
        photoURL: URL? = nil,
        locale: String,
        homeCountry: Country,
        country: Country? = nil,
        cohortD0: Date,
        authMethod: AuthMethod,
        stats: UserStats = .zero,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.uid = uid
        self.displayName = displayName
        self.photoURL = photoURL
        self.locale = locale
        self.homeCountry = homeCountry
        self.country = country
        self.cohortD0 = cohortD0
        self.authMethod = authMethod
        self.stats = stats
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// schema.md §1.1 `travelMode` computed 필드 정합.
    public var isTraveling: Bool {
        guard let country else { return false }
        return country != homeCountry
    }
}
