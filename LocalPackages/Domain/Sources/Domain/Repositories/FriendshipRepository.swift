import Foundation

/// schema.md §6 friendships. 양방향 doc 정합은 Functions 책임.
/// 클라 read는 자기 서브컬렉션만. write는 콜러블 (`requestFriend`/`acceptFriend`/`removeFriend`).
public protocol FriendshipRepository: Sendable {
    /// 내 친구 목록 (status=accepted).
    func acceptedFriends(uid: String, cursor: PaginationCursor?, limit: Int) async throws -> Page<Friendship>

    /// 받은 요청 (status=pending_incoming).
    func incomingRequests(uid: String) async throws -> [Friendship]

    /// 친구 요청 (콜러블 `requestFriend`).
    func request(targetUid: String, addMethod: Friendship.AddMethod) async throws

    /// 수락 (콜러블 `acceptFriend`).
    func accept(requesterUid: String) async throws

    /// 해제/거부 (콜러블 `removeFriend`).
    func remove(otherUid: String) async throws
}

/// 사용자 프로필 — schema.md §1.
public struct UserProfile: Sendable, Hashable, Identifiable, Codable {
    public var id: String { uid }
    public let uid: String
    public let displayName: String
    public let photoURL: URL?
    public let countryCode: String?
    public let homeCountryCode: String
    public let stats: UserStats
    public let cohortD0: Date

    public init(
        uid: String,
        displayName: String,
        photoURL: URL? = nil,
        countryCode: String? = nil,
        homeCountryCode: String,
        stats: UserStats,
        cohortD0: Date
    ) {
        self.uid = uid
        self.displayName = displayName
        self.photoURL = photoURL
        self.countryCode = countryCode
        self.homeCountryCode = homeCountryCode
        self.stats = stats
        self.cohortD0 = cohortD0
    }
}

public protocol UserRepository: Sendable {
    func profile(uid: String) async throws -> UserProfile
}
