import Foundation

/// schema.md §7 feed_events. fanout-on-write (친구 ≤ 500).
/// 좋아요/댓글은 reviews 본체의 likes/comments 서브컬렉션 기준.
public protocol FeedRepository: Sendable {
    /// 내 친구 피드 (audience-based) — `audienceUids array-contains me`.
    func myFeed(uid: String, cursor: PaginationCursor?, limit: Int) async throws -> Page<FeedEvent>

    /// 좋아요 토글 — 옵티미스틱 UI는 ViewModel에서 적용, 본 메서드는 서버 동기화.
    /// 반환: 서버 측 토글 후 상태(true=좋아요됨).
    @discardableResult
    func toggleLike(targetType: FeedEvent.EventType, targetId: String, uid: String) async throws -> Bool

    /// 댓글 추가 — 옵티미스틱 ID는 클라가 생성, 서버가 ULID 부여 후 갱신.
    func addComment(targetType: FeedEvent.EventType, targetId: String, uid: String, body: String) async throws -> Comment

    /// 댓글 목록 (cursor).
    func comments(targetType: FeedEvent.EventType, targetId: String, cursor: PaginationCursor?, limit: Int) async throws -> Page<Comment>
}

public struct Comment: Sendable, Hashable, Identifiable, Codable {
    public let id: String                      // ULID (옵티미스틱 시 임시 UUID 사용 후 서버 응답으로 교체)
    public let uid: String
    public let author: FriendUser
    public let body: String
    public let createdAt: Date

    public init(
        id: String,
        uid: String,
        author: FriendUser,
        body: String,
        createdAt: Date
    ) {
        self.id = id
        self.uid = uid
        self.author = author
        self.body = body
        self.createdAt = createdAt
    }
}
