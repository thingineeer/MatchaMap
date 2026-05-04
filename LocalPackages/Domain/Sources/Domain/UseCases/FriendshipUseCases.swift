import Foundation

public protocol ListFriendsUseCase: Sendable {
    func callAsFunction(uid: String, cursor: PaginationCursor?, limit: Int) async throws -> Page<Friendship>
}

public struct ListFriendsUseCaseImpl: ListFriendsUseCase {
    private let repo: FriendshipRepository
    public init(repository: FriendshipRepository) { self.repo = repository }
    public func callAsFunction(uid: String, cursor: PaginationCursor?, limit: Int = 20) async throws -> Page<Friendship> {
        guard !uid.isEmpty else { throw MMDomainError.invalidInput("uid") }
        return try await repo.acceptedFriends(uid: uid, cursor: cursor, limit: limit)
    }
}

public protocol RequestFriendUseCase: Sendable {
    func callAsFunction(targetUid: String, addMethod: Friendship.AddMethod) async throws
}

public struct RequestFriendUseCaseImpl: RequestFriendUseCase {
    private let repo: FriendshipRepository
    public init(repository: FriendshipRepository) { self.repo = repository }
    public func callAsFunction(targetUid: String, addMethod: Friendship.AddMethod) async throws {
        guard !targetUid.isEmpty else { throw MMDomainError.invalidInput("targetUid") }
        try await repo.request(targetUid: targetUid, addMethod: addMethod)
    }
}

public protocol AcceptFriendUseCase: Sendable {
    func callAsFunction(requesterUid: String) async throws
}

public struct AcceptFriendUseCaseImpl: AcceptFriendUseCase {
    private let repo: FriendshipRepository
    public init(repository: FriendshipRepository) { self.repo = repository }
    public func callAsFunction(requesterUid: String) async throws {
        guard !requesterUid.isEmpty else { throw MMDomainError.invalidInput("requesterUid") }
        try await repo.accept(requesterUid: requesterUid)
    }
}

public protocol RemoveFriendUseCase: Sendable {
    func callAsFunction(otherUid: String) async throws
}

public struct RemoveFriendUseCaseImpl: RemoveFriendUseCase {
    private let repo: FriendshipRepository
    public init(repository: FriendshipRepository) { self.repo = repository }
    public func callAsFunction(otherUid: String) async throws {
        guard !otherUid.isEmpty else { throw MMDomainError.invalidInput("otherUid") }
        try await repo.remove(otherUid: otherUid)
    }
}
