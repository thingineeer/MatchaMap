import XCTest
@testable import Domain

final class GetStoreReviewsUseCaseTests: XCTestCase {

    func test_returnsPage_whenRepositorySucceeds() async throws {
        let repo = MockReviewRepository()
        repo.stubPage = ReviewPage(items: [.preview(id: "r1"), .preview(id: "r2")], nextCursor: "cur1")
        let sut = GetStoreReviewsUseCaseImpl(repository: repo)

        let page = try await sut(storeId: "store-1", sort: .latest, limit: 20, cursor: nil)

        XCTAssertEqual(page.items.count, 2)
        XCTAssertEqual(page.nextCursor, "cur1")
        XCTAssertEqual(repo.reviewsCallCount, 1)
        XCTAssertEqual(repo.lastStoreId, "store-1")
        XCTAssertEqual(repo.lastSort, .latest)
        XCTAssertEqual(repo.lastLimit, 20)
        XCTAssertNil(repo.lastCursor)
    }

    func test_passesCursor_forPagination() async throws {
        let repo = MockReviewRepository()
        let sut = GetStoreReviewsUseCaseImpl(repository: repo)

        _ = try await sut(storeId: "s", sort: .rating, limit: 10, cursor: "next-token")

        XCTAssertEqual(repo.lastCursor, "next-token")
        XCTAssertEqual(repo.lastSort, .rating)
        XCTAssertEqual(repo.lastLimit, 10)
    }

    func test_throwsInvalidInput_whenStoreIdEmpty() async {
        let repo = MockReviewRepository()
        let sut = GetStoreReviewsUseCaseImpl(repository: repo)

        do {
            _ = try await sut(storeId: "", sort: .latest, limit: 20, cursor: nil)
            XCTFail("expected throw")
        } catch let error as MMDomainError {
            XCTAssertEqual(error, .invalidInput("storeId"))
            XCTAssertEqual(repo.reviewsCallCount, 0)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func test_throwsInvalidInput_whenLimitOutOfRange() async {
        let repo = MockReviewRepository()
        let sut = GetStoreReviewsUseCaseImpl(repository: repo)

        for bad in [0, -1, 51, 100] {
            do {
                _ = try await sut(storeId: "s", sort: .latest, limit: bad, cursor: nil)
                XCTFail("expected throw for limit \(bad)")
            } catch let error as MMDomainError {
                XCTAssertEqual(error, .invalidInput("limit"))
            } catch {
                XCTFail("unexpected error: \(error)")
            }
        }
        XCTAssertEqual(repo.reviewsCallCount, 0)
    }

    func test_propagatesError() async {
        let repo = MockReviewRepository()
        repo.stubError = MMDomainError.network("offline")
        let sut = GetStoreReviewsUseCaseImpl(repository: repo)

        do {
            _ = try await sut(storeId: "s", sort: .latest, limit: 20, cursor: nil)
            XCTFail("expected throw")
        } catch let error as MMDomainError {
            XCTAssertEqual(error, .network("offline"))
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}
