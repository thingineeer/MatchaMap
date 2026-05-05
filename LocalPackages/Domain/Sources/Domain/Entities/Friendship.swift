import Foundation

/// 친구 그래프 엣지. schema.md §6 friendships/{uid}/edges/{friendUid}.
/// 양방향 두 doc 저장 → Functions 책임. 본 엔티티는 한 쪽 view.
public struct Friendship: Sendable, Hashable, Identifiable, Codable {
    public var id: String { friendUid }
    public let uid: String                   // 본인 uid
    public let friendUid: String
    public let status: Status
    public let friend: FriendUser
    public let addMethod: AddMethod
    public let requestedAt: Date
    public let acceptedAt: Date?

    public init(
        uid: String,
        friendUid: String,
        status: Status,
        friend: FriendUser,
        addMethod: AddMethod,
        requestedAt: Date,
        acceptedAt: Date? = nil
    ) {
        self.uid = uid
        self.friendUid = friendUid
        self.status = status
        self.friend = friend
        self.addMethod = addMethod
        self.requestedAt = requestedAt
        self.acceptedAt = acceptedAt
    }
}

public extension Friendship {
    enum Status: String, Sendable, Codable, CaseIterable, Hashable {
        case pendingOutgoing = "pending_outgoing"
        case pendingIncoming = "pending_incoming"
        case accepted
        case blocked
    }

    enum AddMethod: String, Sendable, Codable, CaseIterable, Hashable {
        case qr
        case username
        case shareLink = "share_link"
        case addressBook = "address_book"
    }
}

/// 친구/액터의 디노멀 user 스냅샷.
/// schema.md §6.1 / §7.1 / users §1.
public struct FriendUser: Sendable, Hashable, Codable {
    public let uid: String
    public let displayName: String
    public let photoURL: URL?
    public let countryCode: String?

    public init(
        uid: String,
        displayName: String,
        photoURL: URL? = nil,
        countryCode: String? = nil
    ) {
        self.uid = uid
        self.displayName = displayName
        self.photoURL = photoURL
        self.countryCode = countryCode
    }
}
