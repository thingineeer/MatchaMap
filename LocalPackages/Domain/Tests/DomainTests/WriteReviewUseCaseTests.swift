import XCTest
@testable import Domain

final class WriteReviewUseCaseTests: XCTestCase {

    private func draft(
        storeId: String = "store-1",
        rating: Int = 5,
        body: String = "정말 깊은 우스차였어요. 거품이 곱고 향이 진합니다.",
        photos: [URL] = [],
        tags: [ReviewTag] = [.usucha],
        drink: ReviewDrink? = .usucha
    ) -> ReviewDraft {
        ReviewDraft(storeId: storeId, rating: rating, body: body, photos: photos, tags: tags, drink: drink)
    }

    func test_returnsReviewId_whenValid() async throws {
        let repo = MockReviewRepository()
        repo.stubWriteResult = "rev-abc"
        let sut = WriteReviewUseCaseImpl(repository: repo)

        let id = try await sut(draft())

        XCTAssertEqual(id, "rev-abc")
        XCTAssertEqual(repo.writeCallCount, 1)
        XCTAssertEqual(repo.lastDraft?.storeId, "store-1")
    }

    func test_throws_whenStoreIdEmpty() async {
        let repo = MockReviewRepository()
        let sut = WriteReviewUseCaseImpl(repository: repo)

        do {
            _ = try await sut(draft(storeId: ""))
            XCTFail("expected throw")
        } catch let error as MMDomainError {
            XCTAssertEqual(error, .invalidInput("storeId"))
            XCTAssertEqual(repo.writeCallCount, 0)
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func test_throws_whenRatingOutOfRange() async {
        let repo = MockReviewRepository()
        let sut = WriteReviewUseCaseImpl(repository: repo)

        for bad in [0, -1, 6, 100] {
            do {
                _ = try await sut(draft(rating: bad))
                XCTFail("expected throw for rating \(bad)")
            } catch let error as MMDomainError {
                XCTAssertEqual(error, .invalidInput("rating"))
            } catch {
                XCTFail("unexpected: \(error)")
            }
        }
    }

    func test_throws_whenBodyEmptyOrWhitespace() async {
        let repo = MockReviewRepository()
        let sut = WriteReviewUseCaseImpl(repository: repo)

        for body in ["", "   ", "\n\n\t"] {
            do {
                _ = try await sut(draft(body: body))
                XCTFail("expected throw for body=\(body.debugDescription)")
            } catch let error as MMDomainError {
                XCTAssertEqual(error, .invalidInput("body"))
            } catch {
                XCTFail("unexpected: \(error)")
            }
        }
    }

    func test_throws_whenBodyTooLong() async {
        let repo = MockReviewRepository()
        let sut = WriteReviewUseCaseImpl(repository: repo)
        let body = String(repeating: "a", count: 2001)

        do {
            _ = try await sut(draft(body: body))
            XCTFail("expected throw")
        } catch let error as MMDomainError {
            XCTAssertEqual(error, .invalidInput("body"))
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func test_throws_whenPhotosExceedFour() async throws {
        let repo = MockReviewRepository()
        let sut = WriteReviewUseCaseImpl(repository: repo)
        let urls = (0..<5).compactMap { URL(string: "https://example.com/\($0).jpg") }
        XCTAssertEqual(urls.count, 5)

        do {
            _ = try await sut(draft(photos: urls))
            XCTFail("expected throw")
        } catch let error as MMDomainError {
            XCTAssertEqual(error, .invalidInput("photos"))
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func test_acceptsExactlyFourPhotos() async throws {
        let repo = MockReviewRepository()
        repo.stubWriteResult = "ok"
        let sut = WriteReviewUseCaseImpl(repository: repo)
        let urls = (0..<4).compactMap { URL(string: "https://example.com/\($0).jpg") }

        let id = try await sut(draft(photos: urls))
        XCTAssertEqual(id, "ok")
    }

    func test_throws_whenTagsExceedEight() async {
        let repo = MockReviewRepository()
        let sut = WriteReviewUseCaseImpl(repository: repo)
        // 10 dup tags
        let tags: [ReviewTag] = Array(repeating: .usucha, count: 9)

        do {
            _ = try await sut(draft(tags: tags))
            XCTFail("expected throw")
        } catch let error as MMDomainError {
            XCTAssertEqual(error, .invalidInput("tags"))
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func test_propagatesRepositoryError() async {
        let repo = MockReviewRepository()
        repo.stubError = MMDomainError.network("offline")
        let sut = WriteReviewUseCaseImpl(repository: repo)

        do {
            _ = try await sut(draft())
            XCTFail("expected throw")
        } catch let error as MMDomainError {
            XCTAssertEqual(error, .network("offline"))
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }
}
