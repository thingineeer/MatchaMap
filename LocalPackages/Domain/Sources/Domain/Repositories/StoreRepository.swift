public protocol StoreRepository: Sendable {
    func storeDetails(id: String) async throws -> Store
    func storesInBounds(_ bounds: BoundingBox) async throws -> [Store]
}
