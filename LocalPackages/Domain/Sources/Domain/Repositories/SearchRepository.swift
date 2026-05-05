import Foundation

/// api-contract.md §2.2 mergeStoreSearch 정합. Data 모듈이 Cloud Functions 콜러블로 구현.
public protocol SearchRepository: Sendable {
    func searchStores(_ query: StoreSearchQuery) async throws -> SearchPage
}
