import XCTest
@testable import Domain

final class GetStoreDetailsUseCaseTests: XCTestCase {

    func test_callAsFunction_returnsStore_whenRepositorySucceeds() async throws {
        // Given
        let repo = MockStoreRepository()
        repo.stubStore = .fixture(id: "abc", name: "말차하우스", matchaScore: 4.6)
        let sut = GetStoreDetailsUseCaseImpl(repository: repo)

        // When
        let store = try await sut(id: "abc")

        // Then
        XCTAssertEqual(store.id, "abc")
        XCTAssertEqual(store.name, "말차하우스")
        XCTAssertEqual(store.grade, .iconic)
        XCTAssertEqual(repo.storeDetailsCallCount, 1)
        XCTAssertEqual(repo.lastRequestedID, "abc")
    }

    func test_callAsFunction_throwsInvalidInput_whenIDEmpty() async {
        // Given
        let repo = MockStoreRepository()
        let sut = GetStoreDetailsUseCaseImpl(repository: repo)

        // When / Then
        do {
            _ = try await sut(id: "")
            XCTFail("expected throw")
        } catch let error as MMDomainError {
            XCTAssertEqual(error, .invalidInput("id"))
            XCTAssertEqual(repo.storeDetailsCallCount, 0, "repository must not be called for invalid id")
        } catch {
            XCTFail("unexpected error type: \(error)")
        }
    }

    func test_callAsFunction_propagatesNotFound_whenRepositoryThrows() async {
        // Given
        let repo = MockStoreRepository()
        repo.stubError = MMDomainError.notFound
        let sut = GetStoreDetailsUseCaseImpl(repository: repo)

        // When / Then
        do {
            _ = try await sut(id: "missing")
            XCTFail("expected throw")
        } catch let error as MMDomainError {
            XCTAssertEqual(error, .notFound)
        } catch {
            XCTFail("unexpected error type: \(error)")
        }
    }
}
