import XCTest
import Domain
@testable import FeatureStore

/// ADR-304 — 게스트 사용자 리뷰 작성 차단 테스트.
@MainActor
final class ReviewWriteGuestModeTests: XCTestCase {

    @MainActor
    final class StubUploader: PhotoUploader {
        nonisolated init() {}
        func upload(localData: Data, fileName: String) async throws -> URL {
            URL(string: "https://stub.example.com/\(fileName)")!
        }
    }

    private func makeSUT(authState: AuthState) -> (ReviewWriteViewModel, MockReviewRepository) {
        let repo = MockReviewRepository()
        let vm = ReviewWriteViewModel(
            storeId: "store-1",
            writeReview: WriteReviewUseCaseImpl(repository: repo),
            uploader: StubUploader(),
            authState: authState
        )
        return (vm, repo)
    }

    func test_canSubmit_falseForGuest_evenWithValidForm() {
        let (sut, _) = makeSUT(authState: .guest(anonymousUid: "anon-1"))
        sut.rating = 5
        sut.body = "맛있어요"
        XCTAssertFalse(sut.canSubmit, "게스트는 form이 valid해도 canSubmit=false")
        XCTAssertTrue(sut.isGuestBlocked)
    }

    func test_submit_triggersOnRequireLogin_forGuest() async {
        let (sut, repo) = makeSUT(authState: .guest(anonymousUid: "anon-1"))
        sut.rating = 5
        sut.body = "맛있어요"
        var captured: ReviewWriteViewModel.LoginGate?
        sut.onRequireLogin = { captured = $0 }

        await sut.submit()

        XCTAssertEqual(captured, .review)
        XCTAssertEqual(repo.writeCallCount, 0, "게스트는 서버 호출 없음")
    }

    func test_canSubmit_trueForAuthenticated() {
        let (sut, _) = makeSUT(authState: .authenticated(.fixture(uid: "u")))
        sut.rating = 4
        sut.body = "괜찮아요"
        XCTAssertTrue(sut.canSubmit)
        XCTAssertFalse(sut.isGuestBlocked)
    }

    func test_updateAuthState_unblocksAfterLogin() {
        let (sut, _) = makeSUT(authState: .guest(anonymousUid: "anon-1"))
        sut.rating = 5
        sut.body = "본문"
        XCTAssertFalse(sut.canSubmit)

        sut.updateAuthState(.authenticated(.fixture(uid: "u")))

        XCTAssertTrue(sut.canSubmit)
    }
}
