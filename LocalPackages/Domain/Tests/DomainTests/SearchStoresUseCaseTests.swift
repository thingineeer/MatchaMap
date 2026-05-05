import XCTest
@testable import Domain

final class SearchStoresUseCaseTests: XCTestCase {

    private func q(
        _ text: String,
        max: Int = 20,
        cursor: String? = nil,
        filters: StoreSearchFilters = .none
    ) -> StoreSearchQuery {
        StoreSearchQuery(query: text, viewport: nil, locale: "ko-KR", filters: filters, maxResults: max, cursor: cursor)
    }

    func test_returnsPage_whenValid() async throws {
        let repo = MockSearchRepository()
        repo.stubPage = SearchPage(results: [.preview()], nextCursor: "next1")
        let sut = SearchStoresUseCaseImpl(repository: repo)

        let page = try await sut(q("말차"))

        XCTAssertEqual(page.results.count, 1)
        XCTAssertEqual(page.nextCursor, "next1")
        XCTAssertEqual(repo.callCount, 1)
        XCTAssertEqual(repo.lastQuery?.query, "말차")
    }

    func test_throws_whenQueryEmpty() async {
        let repo = MockSearchRepository()
        let sut = SearchStoresUseCaseImpl(repository: repo)

        for empty in ["", "   ", "\n"] {
            do {
                _ = try await sut(q(empty))
                XCTFail("expected throw for \(empty.debugDescription)")
            } catch let error as MMDomainError {
                XCTAssertEqual(error, .invalidInput("query"))
            } catch {
                XCTFail("unexpected: \(error)")
            }
        }
        XCTAssertEqual(repo.callCount, 0)
    }

    func test_throws_whenQueryTooLong() async {
        let repo = MockSearchRepository()
        let sut = SearchStoresUseCaseImpl(repository: repo)
        let long = String(repeating: "ㄱ", count: 101)

        do {
            _ = try await sut(q(long))
            XCTFail("expected throw")
        } catch let error as MMDomainError {
            XCTAssertEqual(error, .invalidInput("query"))
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func test_throws_whenMaxResultsOutOfRange() async {
        let repo = MockSearchRepository()
        let sut = SearchStoresUseCaseImpl(repository: repo)

        for bad in [0, -1, 51, 100] {
            do {
                _ = try await sut(q("matcha", max: bad))
                XCTFail("expected throw for max=\(bad)")
            } catch let error as MMDomainError {
                XCTAssertEqual(error, .invalidInput("maxResults"))
            } catch {
                XCTFail("unexpected: \(error)")
            }
        }
    }

    func test_passesFiltersAndCursor() async throws {
        let repo = MockSearchRepository()
        let sut = SearchStoresUseCaseImpl(repository: repo)
        let filters = StoreSearchFilters(
            pinTiers: [.S, .A],
            drinks: [.usucha],
            priceLevels: [2, 3],
            maxDistanceMeters: 1500,
            openNow: true
        )

        _ = try await sut(q("matcha", max: 30, cursor: "abc", filters: filters))

        XCTAssertEqual(repo.lastQuery?.cursor, "abc")
        XCTAssertEqual(repo.lastQuery?.maxResults, 30)
        XCTAssertEqual(repo.lastQuery?.filters.pinTiers, [.S, .A])
        XCTAssertEqual(repo.lastQuery?.filters.drinks, [.usucha])
        XCTAssertEqual(repo.lastQuery?.filters.priceLevels, [2, 3])
        XCTAssertEqual(repo.lastQuery?.filters.maxDistanceMeters, 1500)
        XCTAssertTrue(repo.lastQuery?.filters.openNow ?? false)
    }

    func test_filters_isActive_detectsActiveFilters() {
        XCTAssertFalse(StoreSearchFilters.none.isActive)
        XCTAssertTrue(StoreSearchFilters(pinTiers: [.S]).isActive)
        XCTAssertTrue(StoreSearchFilters(drinks: [.usucha]).isActive)
        XCTAssertTrue(StoreSearchFilters(priceLevels: [1]).isActive)
        XCTAssertTrue(StoreSearchFilters(maxDistanceMeters: 500).isActive)
        XCTAssertTrue(StoreSearchFilters(openNow: true).isActive)
    }
}
