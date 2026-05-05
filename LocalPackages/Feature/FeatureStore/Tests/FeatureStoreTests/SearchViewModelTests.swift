import XCTest
import Domain
@testable import FeatureStore

@MainActor
final class SearchViewModelTests: XCTestCase {

    /// 즉시 sleep을 통과시키는 테스트용 sleeper.
    private let immediateSleeper: @Sendable (Duration) async throws -> Void = { _ in
        // no-op (디바운스 0ms 효과)
    }

    private func makeSUT(
        repo: MockSearchRepository = MockSearchRepository(),
        cache: SearchCache = SearchCache()
    ) -> (SearchViewModel, MockSearchRepository, SearchCache) {
        let useCase = SearchStoresUseCaseImpl(repository: repo)
        let vm = SearchViewModel(
            locale: "ko-KR",
            searchStores: useCase,
            cache: cache,
            debounceMilliseconds: 250,
            sleeper: immediateSleeper
        )
        return (vm, repo, cache)
    }

    func test_query_blank_keepsResultsIdle() async {
        let (sut, repo, _) = makeSUT()

        sut.query = "   "
        // 디바운스 작업이 예약되지만 trimmed empty라 .idle 즉시
        // 잠깐 yield
        await Task.yield()
        await Task.yield()

        if case .idle = sut.results {} else { XCTFail("expected idle") }
        XCTAssertEqual(repo.callCount, 0)
    }

    func test_debounced_singleSearch_afterTyping() async {
        let (sut, repo, _) = makeSUT()
        repo.stubPage = SearchPage(results: [.preview()], nextCursor: nil)

        sut.query = "m"
        sut.query = "ma"
        sut.query = "mat"
        sut.query = "matc"
        sut.query = "match"
        sut.query = "matcha"

        // 디바운스 sleeper가 즉시 통과 → 마지막 작업이 실제 실행
        // 이전 task들은 cancel됨
        for _ in 0..<10 { await Task.yield() }

        XCTAssertEqual(repo.callCount, 1, "디바운스로 마지막 query만 1회 실행")
        XCTAssertEqual(repo.lastQuery?.query, "matcha")
    }

    func test_emptyResultsState() async {
        let (sut, repo, _) = makeSUT()
        repo.stubPage = .empty

        sut.query = "nothing"
        for _ in 0..<10 { await Task.yield() }

        XCTAssertEqual(sut.results.value?.results.count, 0)
        XCTAssertEqual(sut.results.value?.nextCursor, nil)
    }

    func test_failedState_propagatesError() async {
        let (sut, repo, _) = makeSUT()
        repo.stubError = MMDomainError.network("offline")

        sut.query = "m"
        for _ in 0..<10 { await Task.yield() }

        XCTAssertEqual(sut.results.error, .network("offline"))
    }

    func test_clearQuery_resetsResults() async {
        let (sut, repo, _) = makeSUT()
        repo.stubPage = SearchPage(results: [.preview()], nextCursor: nil)

        sut.query = "m"
        for _ in 0..<10 { await Task.yield() }
        XCTAssertNotNil(sut.results.value)

        sut.clearQuery()

        XCTAssertEqual(sut.query, "")
        if case .idle = sut.results {} else { XCTFail("expected idle after clear") }
    }

    func test_addsRecentQuery_afterSuccessfulSearch() async {
        let cache = SearchCache()
        let (sut, repo, _) = makeSUT(cache: cache)
        repo.stubPage = SearchPage(results: [.preview()], nextCursor: nil)

        sut.query = "matcha"
        for _ in 0..<10 { await Task.yield() }

        let recents = await cache.queries()
        XCTAssertEqual(recents.first, "matcha")
        XCTAssertEqual(sut.recentQueries.first, "matcha")
    }

    func test_onSelectResult_addsRecentStore() async {
        let cache = SearchCache()
        let (sut, _, _) = makeSUT(cache: cache)
        let result = SearchResult.preview(storeId: "abc", name: "교토 우지")

        await sut.onSelectResult(result)

        let recents = await cache.stores()
        XCTAssertEqual(recents.first?.name, "교토 우지")
        XCTAssertEqual(sut.recentStores.first?.name, "교토 우지")
    }

    func test_groupedResults_byCity() async {
        let (sut, repo, _) = makeSUT()
        repo.stubPage = SearchPage(results: [
            .preview(storeId: "1", name: "A", city: "Seoul"),
            .preview(storeId: "2", name: "B", city: "Tokyo"),
            .preview(storeId: "3", name: "C", city: "Seoul"),
            .preview(storeId: "4", name: "D", city: nil)  // fallback to country code
        ], nextCursor: nil)

        sut.query = "matcha"
        for _ in 0..<10 { await Task.yield() }

        let groups = sut.groupedResults
        XCTAssertEqual(groups.count, 3)
        XCTAssertEqual(groups[0].groupKey, "Seoul")
        XCTAssertEqual(groups[0].items.count, 2)
        XCTAssertEqual(groups[1].groupKey, "Tokyo")
        XCTAssertEqual(groups[2].groupKey, "KR", "city nil이면 countryCode fallback")
    }

    func test_onSubmit_immediatelySearches_evenWhenDebouncePending() async {
        // 실제 250ms 디바운스 있는 경우라도 onSubmit은 즉시 실행
        let repo = MockSearchRepository()
        repo.stubPage = SearchPage(results: [.preview()], nextCursor: nil)
        let useCase = SearchStoresUseCaseImpl(repository: repo)
        let vm = SearchViewModel(
            locale: "ko-KR",
            searchStores: useCase,
            debounceMilliseconds: 5_000,                      // 5초 — 안 기다리면 안 풀림
            sleeper: { try await Task.sleep(for: $0) }       // 진짜 sleep
        )

        vm.query = "matcha"
        await vm.onSubmit()

        XCTAssertEqual(repo.callCount, 1)
        XCTAssertEqual(repo.lastQuery?.query, "matcha")
    }

    func test_applyFilters_setsAndSearches() async {
        let (sut, repo, _) = makeSUT()
        repo.stubPage = SearchPage(results: [.preview()], nextCursor: nil)
        sut.query = "matcha"
        for _ in 0..<10 { await Task.yield() }
        let baseCalls = repo.callCount

        let filters = StoreSearchFilters(pinTiers: [.S], openNow: true)
        await sut.applyFilters(filters)

        XCTAssertEqual(sut.filters.pinTiers, [.S])
        XCTAssertTrue(sut.filters.openNow)
        XCTAssertEqual(repo.callCount, baseCalls + 1)
    }
}
