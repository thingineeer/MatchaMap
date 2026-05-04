import Foundation

public protocol ListWishlistItemsUseCase: Sendable {
    func callAsFunction(uid: String, cursor: PaginationCursor?, limit: Int) async throws -> Page<WishlistItem>
}

public struct ListWishlistItemsUseCaseImpl: ListWishlistItemsUseCase {
    private let repo: WishlistRepository
    public init(repository: WishlistRepository) { self.repo = repository }
    public func callAsFunction(uid: String, cursor: PaginationCursor?, limit: Int = 20) async throws -> Page<WishlistItem> {
        guard !uid.isEmpty else { throw MMDomainError.invalidInput("uid") }
        guard limit > 0, limit <= 50 else { throw MMDomainError.invalidInput("limit") }
        return try await repo.items(uid: uid, cursor: cursor, limit: limit)
    }
}

public protocol ToggleWishlistUseCase: Sendable {
    @discardableResult
    func callAsFunction(uid: String, store: StoreSnapshot, note: String?) async throws -> Bool
}

public struct ToggleWishlistUseCaseImpl: ToggleWishlistUseCase {
    private let repo: WishlistRepository
    public init(repository: WishlistRepository) { self.repo = repository }
    @discardableResult
    public func callAsFunction(uid: String, store: StoreSnapshot, note: String?) async throws -> Bool {
        guard !uid.isEmpty, !store.placeId.isEmpty else {
            throw MMDomainError.invalidInput("ids")
        }
        if let note, note.count > 200 { throw MMDomainError.invalidInput("note.length") }
        return try await repo.toggle(uid: uid, store: store, note: note)
    }
}
