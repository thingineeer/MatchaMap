import Foundation

public protocol LoadFeedUseCase: Sendable {
    func callAsFunction(uid: String, cursor: PaginationCursor?, limit: Int) async throws -> Page<FeedEvent>
}

public struct LoadFeedUseCaseImpl: LoadFeedUseCase {
    private let repo: FeedRepository
    public init(repository: FeedRepository) { self.repo = repository }
    public func callAsFunction(uid: String, cursor: PaginationCursor?, limit: Int = 20) async throws -> Page<FeedEvent> {
        guard !uid.isEmpty else { throw MMDomainError.invalidInput("uid") }
        guard limit > 0, limit <= 50 else { throw MMDomainError.invalidInput("limit") }
        return try await repo.myFeed(uid: uid, cursor: cursor, limit: limit)
    }
}

public protocol ToggleLikeUseCase: Sendable {
    @discardableResult
    func callAsFunction(uid: String, targetType: FeedEvent.EventType, targetId: String) async throws -> Bool
}

public struct ToggleLikeUseCaseImpl: ToggleLikeUseCase {
    private let repo: FeedRepository
    public init(repository: FeedRepository) { self.repo = repository }
    @discardableResult
    public func callAsFunction(uid: String, targetType: FeedEvent.EventType, targetId: String) async throws -> Bool {
        guard !uid.isEmpty, !targetId.isEmpty else { throw MMDomainError.invalidInput("ids") }
        return try await repo.toggleLike(targetType: targetType, targetId: targetId, uid: uid)
    }
}

public protocol AddCommentUseCase: Sendable {
    func callAsFunction(uid: String, targetType: FeedEvent.EventType, targetId: String, body: String) async throws -> Comment
}

public struct AddCommentUseCaseImpl: AddCommentUseCase {
    private let repo: FeedRepository
    public init(repository: FeedRepository) { self.repo = repository }
    public func callAsFunction(uid: String, targetType: FeedEvent.EventType, targetId: String, body: String) async throws -> Comment {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty, !targetId.isEmpty else { throw MMDomainError.invalidInput("ids") }
        guard !trimmed.isEmpty else { throw MMDomainError.invalidInput("body.empty") }
        guard trimmed.count <= 500 else { throw MMDomainError.invalidInput("body.length") }
        return try await repo.addComment(targetType: targetType, targetId: targetId, uid: uid, body: trimmed)
    }
}
