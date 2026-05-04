public protocol GetStoreDetailsUseCase: Sendable {
    func callAsFunction(id: String) async throws -> Store
}

public struct GetStoreDetailsUseCaseImpl: GetStoreDetailsUseCase {
    private let repository: StoreRepository

    public init(repository: StoreRepository) {
        self.repository = repository
    }

    public func callAsFunction(id: String) async throws -> Store {
        guard !id.isEmpty else { throw MMDomainError.invalidInput("id") }
        return try await repository.storeDetails(id: id)
    }
}
