import Foundation

/// 친구 피드 이벤트. schema.md §7 feed_events. fanout-on-write (친구 ≤ 500).
/// 클라 read = `audienceUids array-contains me`.
public struct FeedEvent: Sendable, Hashable, Identifiable, Codable {
    public let id: String                      // ULID == eventId
    public let actorUid: String
    public let actor: FriendUser
    public let type: EventType
    public let target: Target
    public let payload: Payload?
    public let countryCode: String?
    public let visibility: Visibility
    public let audienceUidsCount: Int          // 클라는 보통 미사용. 분석/디버그용.
    public let createdAt: Date

    /// 좋아요/댓글은 본 이벤트 doc 본체에 카운트 저장 X — likes 서브컬렉션 또는 별도 reviews.likeCount 참조.
    /// 본 엔티티에 대한 *클라이언트 측 옵티미스틱* 좋아요/댓글 상태는 ViewModel에서 별도 관리.

    public init(
        id: String,
        actorUid: String,
        actor: FriendUser,
        type: EventType,
        target: Target,
        payload: Payload? = nil,
        countryCode: String? = nil,
        visibility: Visibility = .friends,
        audienceUidsCount: Int = 0,
        createdAt: Date
    ) {
        self.id = id
        self.actorUid = actorUid
        self.actor = actor
        self.type = type
        self.target = target
        self.payload = payload
        self.countryCode = countryCode
        self.visibility = visibility
        self.audienceUidsCount = audienceUidsCount
        self.createdAt = createdAt
    }
}

public extension FeedEvent {
    enum EventType: String, Sendable, Codable, CaseIterable, Hashable {
        case collection
        case review
        case checkin
        case friendAdded = "friend_added"
    }

    enum Visibility: String, Sendable, Codable, CaseIterable, Hashable {
        case friends
        case publicFeed = "public"
    }

    /// schema.md §7.1 target. type별로 의미가 다름.
    enum Target: Sendable, Hashable, Codable {
        case store(StoreSnapshot)
        case review(reviewId: String, store: StoreSnapshot)
        case collectionItem(itemId: String, store: StoreSnapshot)
        case user(FriendUser)

        public var targetId: String {
            switch self {
            case .store(let s): return s.placeId
            case .review(let id, _): return id
            case .collectionItem(let id, _): return id
            case .user(let u): return u.uid
            }
        }
    }

    /// type별 payload (디노멀 미리보기 데이터). schema.md §7.1.
    enum Payload: Sendable, Hashable, Codable {
        case review(rating: Int, bodyExcerpt: String, photoURL: URL?)
        case collection(drink: CollectionItem.Drink, grade: CollectionItem.Grade?, colorHex: String?)
        case checkin(note: String?)
        case friendAdded
    }
}
