import Foundation

public protocol SearchStoresUseCase: Sendable {
    func callAsFunction(_ query: StoreSearchQuery) async throws -> SearchPage
}

public struct SearchStoresUseCaseImpl: SearchStoresUseCase {
    private let repository: SearchRepository

    public init(repository: SearchRepository) {
        self.repository = repository
    }

    public func callAsFunction(_ query: StoreSearchQuery) async throws -> SearchPage {
        let trimmed = query.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw MMDomainError.invalidInput("query") }
        guard trimmed.count <= 100 else { throw MMDomainError.invalidInput("query") }
        guard query.maxResults > 0 && query.maxResults <= 50 else {
            throw MMDomainError.invalidInput("maxResults")
        }
        return try await repository.searchStores(query)
    }
}
