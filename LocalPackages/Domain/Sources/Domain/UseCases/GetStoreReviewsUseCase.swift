import Foundation

public protocol GetStoreReviewsUseCase: Sendable {
    func callAsFunction(
        storeId: String,
        sort: ReviewSortOrder,
        limit: Int,
        cursor: String?
    ) async throws -> ReviewPage
}

public struct GetStoreReviewsUseCaseImpl: GetStoreReviewsUseCase {
    private let repository: ReviewRepository

    public init(repository: ReviewRepository) {
        self.repository = repository
    }

    public func callAsFunction(
        storeId: String,
        sort: ReviewSortOrder,
        limit: Int = 20,
        cursor: String? = nil
    ) async throws -> ReviewPage {
        guard !storeId.isEmpty else { throw MMDomainError.invalidInput("storeId") }
        guard limit > 0 && limit <= 50 else { throw MMDomainError.invalidInput("limit") }
        return try await repository.reviews(storeId: storeId, sort: sort, limit: limit, cursor: cursor)
    }
}
