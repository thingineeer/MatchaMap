import Foundation

// MARK: - List

public protocol ListCollectionItemsUseCase: Sendable {
    func callAsFunction(uid: String, cursor: PaginationCursor?, limit: Int) async throws -> Page<CollectionItem>
}

public struct ListCollectionItemsUseCaseImpl: ListCollectionItemsUseCase {
    private let repo: CollectionRepository
    public init(repository: CollectionRepository) { self.repo = repository }
    public func callAsFunction(uid: String, cursor: PaginationCursor?, limit: Int = 20) async throws -> Page<CollectionItem> {
        guard !uid.isEmpty else { throw MMDomainError.invalidInput("uid") }
        guard limit > 0, limit <= 50 else { throw MMDomainError.invalidInput("limit") }
        return try await repo.items(uid: uid, cursor: cursor, limit: limit)
    }
}

// MARK: - Add

public protocol AddCollectionItemUseCase: Sendable {
    func callAsFunction(_ draft: CollectionItemDraft) async throws -> AddCollectionItemResult
}

public struct AddCollectionItemUseCaseImpl: AddCollectionItemUseCase {
    private let repo: CollectionRepository
    public init(repository: CollectionRepository) { self.repo = repository }
    public func callAsFunction(_ draft: CollectionItemDraft) async throws -> AddCollectionItemResult {
        guard !draft.storeId.isEmpty else { throw MMDomainError.invalidInput("storeId") }
        if draft.viaReview, (draft.linkedReviewId ?? "").isEmpty {
            throw MMDomainError.invalidInput("linkedReviewId")
        }
        if let note = draft.note, note.count > 500 {
            throw MMDomainError.invalidInput("note.length")
        }
        if draft.photoURLs.count > 3 {
            throw MMDomainError.invalidInput("photoURLs.count")
        }
        return try await repo.add(draft)
    }
}

// MARK: - Update

public protocol UpdateCollectionItemUseCase: Sendable {
    func callAsFunction(uid: String, itemId: String, patch: CollectionItemPatch) async throws
}

public struct UpdateCollectionItemUseCaseImpl: UpdateCollectionItemUseCase {
    private let repo: CollectionRepository
    public init(repository: CollectionRepository) { self.repo = repository }
    public func callAsFunction(uid: String, itemId: String, patch: CollectionItemPatch) async throws {
        guard !uid.isEmpty, !itemId.isEmpty else { throw MMDomainError.invalidInput("ids") }
        try await repo.update(uid: uid, itemId: itemId, patch: patch)
    }
}
