import Foundation
import Observation
import Domain

@MainActor
@Observable
public final class SearchViewModel {

    // MARK: - State
    public var query: String = "" {
        didSet { onQueryChanged(oldValue: oldValue, newValue: query) }
    }
    public var filters: StoreSearchFilters = .none
    public private(set) var results: LoadState<SearchPage> = .idle
    public private(set) var recentQueries: [String] = []
    public private(set) var recentStores: [SearchResult] = []

    // MARK: - Config / Deps
    private let locale: String
    private let searchStores: any SearchStoresUseCase
    private let cache: SearchCache
    private let debouncer: Debouncer

    public init(
        locale: String,
        searchStores: any SearchStoresUseCase,
        cache: SearchCache = SearchCache(),
        debounceMilliseconds: Int = 250,
        sleeper: (@Sendable (Duration) async throws -> Void)? = nil
    ) {
        self.locale = locale
        self.searchStores = searchStores
        self.cache = cache
        if let sleeper {
            self.debouncer = Debouncer(milliseconds: debounceMilliseconds, sleeper: sleeper)
        } else {
            self.debouncer = Debouncer(milliseconds: debounceMilliseconds)
        }
    }

    // MARK: - Lifecycle

    public func onAppear() async {
        await refreshCache()
    }

    public func refreshCache() async {
        recentQueries = await cache.queries()
        recentStores = await cache.stores()
    }

    public func applyFilters(_ next: StoreSearchFilters) async {
        filters = next
        await runSearch()
    }

    /// 사용자가 결과 항목을 탭했을 때 호출 — 최근 본 매장 캐시에 추가.
    public func onSelectResult(_ result: SearchResult) async {
        await cache.touchStore(result)
        await refreshCache()
    }

    /// 사용자가 명시적으로 submit (return 키) 했을 때 — 디바운스 우회 즉시 검색.
    public func onSubmit() async {
        debouncer.cancel()
        await runSearch()
    }

    public func clearQuery() {
        query = ""
        results = .idle
        debouncer.cancel()
    }

    // MARK: - Internals

    private func onQueryChanged(oldValue: String, newValue: String) {
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            results = .idle
            debouncer.cancel()
            return
        }
        debouncer.schedule { [weak self] in
            await self?.runSearch()
        }
    }

    private func runSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = .idle
            return
        }
        results = .loading
        let q = StoreSearchQuery(
            query: trimmed,
            viewport: nil,
            locale: locale,
            filters: filters,
            maxResults: 20,
            cursor: nil
        )
        do {
            let page = try await searchStores(q)
            results = .loaded(page)
            await cache.addQuery(trimmed)
            await refreshCache()
        } catch {
            results = .failed(mmError(error))
        }
    }

    // MARK: - Derived: 도시별 그룹 (handoff-mapping 화면 9)

    /// 결과를 도시(city)별 그룹으로 묶는다. city가 nil이면 country code로 fallback.
    public var groupedResults: [(groupKey: String, items: [SearchResult])] {
        guard let page = results.value else { return [] }
        var orderedKeys: [String] = []
        var bucket: [String: [SearchResult]] = [:]
        for r in page.results {
            let key = r.city ?? r.countryCode
            if bucket[key] == nil {
                orderedKeys.append(key)
                bucket[key] = []
            }
            bucket[key, default: []].append(r)
        }
        return orderedKeys.map { ($0, bucket[$0] ?? []) }
    }
}
