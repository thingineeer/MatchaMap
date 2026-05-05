import Foundation
import Domain

/// 최근 검색어(10) + 최근 본 매장(30) in-memory 캐시.
/// ios-store agent §작업 원칙: "캐시(최근 검색 10개 + 최근 본 매장 30개)".
public actor SearchCache {

    private let queriesLimit: Int
    private let storesLimit: Int

    private var recentQueries: [String] = []   // 최신이 index 0
    private var recentStores: [SearchResult] = [] // 최신이 index 0

    public init(queriesLimit: Int = 10, storesLimit: Int = 30) {
        precondition(queriesLimit > 0)
        precondition(storesLimit > 0)
        self.queriesLimit = queriesLimit
        self.storesLimit = storesLimit
    }

    // MARK: Queries

    public func addQuery(_ raw: String) {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        recentQueries.removeAll { $0.caseInsensitiveCompare(normalized) == .orderedSame }
        recentQueries.insert(normalized, at: 0)
        if recentQueries.count > queriesLimit {
            recentQueries.removeLast(recentQueries.count - queriesLimit)
        }
    }

    public func queries() -> [String] { recentQueries }

    public func clearQueries() { recentQueries.removeAll() }

    // MARK: Stores

    public func touchStore(_ result: SearchResult) {
        recentStores.removeAll { $0.id == result.id }
        recentStores.insert(result, at: 0)
        if recentStores.count > storesLimit {
            recentStores.removeLast(recentStores.count - storesLimit)
        }
    }

    public func stores() -> [SearchResult] { recentStores }

    public func clearStores() { recentStores.removeAll() }
}
