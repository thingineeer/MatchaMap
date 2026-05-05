import XCTest
import Domain
@testable import FeatureStore

@MainActor
final class ReviewWriteViewModelTests: XCTestCase {

    /// 임의 결과 또는 에러 큐를 따라 응답하는 mock uploader.
    final class StubUploader: PhotoUploader, @unchecked Sendable {
        // FIFO outcomes
        var outcomes: [Result<URL, Error>] = []
        private(set) var calls: Int = 0
        let lock = NSLock()

        func upload(localData: Data, fileName: String) async throws -> URL {
            lock.lock()
            calls += 1
            let outcome = outcomes.isEmpty
                ? Result<URL, Error>.success(URL(string: "https://uploaded.example.com/\(fileName)")!)
                : outcomes.removeFirst()
            lock.unlock()
            switch outcome {
            case .success(let u): return u
            case .failure(let e): throw e
            }
        }
    }

    private func makeSUT(
        storeId: String = "store-1",
        repo: MockReviewRepository = MockReviewRepository(),
        uploader: StubUploader = StubUploader()
    ) -> (ReviewWriteViewModel, MockReviewRepository, StubUploader) {
        let useCase = WriteReviewUseCaseImpl(repository: repo)
        let vm = ReviewWriteViewModel(storeId: storeId, writeReview: useCase, uploader: uploader)
        return (vm, repo, uploader)
    }

    // MARK: - Form

    func test_canSubmit_requiresRatingAndBody() {
        let (sut, _, _) = makeSUT()
        XCTAssertFalse(sut.canSubmit, "초기 상태")
        sut.rating = 5
        XCTAssertFalse(sut.canSubmit, "본문 비어있음")
        sut.body = "   "
        XCTAssertFalse(sut.canSubmit, "공백만")
        sut.body = "맛있어요"
        XCTAssertTrue(sut.canSubmit)
    }

    func test_addPhoto_respectsLimit() {
        let (sut, _, _) = makeSUT()

        for i in 0..<10 {
            sut.addPhoto(data: Data([UInt8(i)]), fileName: "\(i).jpg")
        }

        XCTAssertEqual(sut.photos.count, ReviewWriteViewModel.photoMax)
    }

    func test_removePhoto_removesById() {
        let (sut, _, _) = makeSUT()
        sut.addPhoto(data: Data([1]), fileName: "a.jpg")
        sut.addPhoto(data: Data([2]), fileName: "b.jpg")
        let firstId = sut.photos[0].id

        sut.removePhoto(id: firstId)

        XCTAssertEqual(sut.photos.count, 1)
        XCTAssertEqual(sut.photos.first?.fileName, "b.jpg")
    }

    func test_toggleTag_togglesMembership() {
        let (sut, _, _) = makeSUT()
        sut.toggleTag(.usucha)
        XCTAssertTrue(sut.tags.contains(.usucha))
        sut.toggleTag(.usucha)
        XCTAssertFalse(sut.tags.contains(.usucha))
    }

    // MARK: - Photo upload queue

    func test_uploadPendingPhotos_marksUploadedAndFailedSlots() async {
        let uploader = StubUploader()
        uploader.outcomes = [
            .success(URL(string: "https://ok/1.jpg")!),
            .failure(MMDomainError.network("offline")),
            .success(URL(string: "https://ok/3.jpg")!)
        ]
        let (sut, _, _) = makeSUT(uploader: uploader)
        sut.addPhoto(data: Data([1]), fileName: "1.jpg")
        sut.addPhoto(data: Data([2]), fileName: "2.jpg")
        sut.addPhoto(data: Data([3]), fileName: "3.jpg")

        await sut.uploadPendingPhotos()

        let statuses = sut.photos.map(\.status)
        if case .uploaded = statuses[0] {} else { XCTFail("0 should be uploaded") }
        if case .failed = statuses[1] {} else { XCTFail("1 should be failed") }
        if case .uploaded = statuses[2] {} else { XCTFail("2 should be uploaded") }
        XCTAssertEqual(uploader.calls, 3)
    }

    func test_retryPhoto_onlyTouchesGivenSlot() async {
        let uploader = StubUploader()
        uploader.outcomes = [
            .failure(MMDomainError.network("offline")),
            .success(URL(string: "https://ok/retry.jpg")!)
        ]
        let (sut, _, _) = makeSUT(uploader: uploader)
        sut.addPhoto(data: Data([9]), fileName: "9.jpg")
        await sut.uploadPendingPhotos()
        let id = sut.photos[0].id
        XCTAssertEqual(uploader.calls, 1)
        guard case .failed = sut.photos[0].status else {
            return XCTFail("setup failed")
        }

        await sut.retryPhoto(id: id)

        XCTAssertEqual(uploader.calls, 2)
        if case .uploaded = sut.photos[0].status {} else { XCTFail("retry should mark uploaded") }
    }

    // MARK: - Submit

    func test_submit_setsValidationError_whenInvalid() async {
        let (sut, repo, _) = makeSUT()
        sut.rating = 0   // invalid
        sut.body = "x"

        await sut.submit()

        XCTAssertEqual(sut.validationError, .invalidInput("rating"))
        XCTAssertEqual(repo.writeCallCount, 0)
    }

    func test_submit_uploadsPhotosThenWrites_onSuccess() async {
        let uploader = StubUploader()
        uploader.outcomes = [
            .success(URL(string: "https://ok/p1.jpg")!),
            .success(URL(string: "https://ok/p2.jpg")!)
        ]
        let repo = MockReviewRepository()
        repo.stubWriteResult = "rev-xyz"
        let (sut, _, _) = makeSUT(repo: repo, uploader: uploader)
        sut.rating = 4
        sut.body = "맛있어요"
        sut.toggleTag(.usucha)
        sut.toggleTag(.modern)
        sut.drink = .usucha
        sut.addPhoto(data: Data([1]), fileName: "p1.jpg")
        sut.addPhoto(data: Data([2]), fileName: "p2.jpg")

        await sut.submit()

        XCTAssertEqual(sut.submission.value, "rev-xyz")
        XCTAssertEqual(repo.writeCallCount, 1)
        XCTAssertEqual(uploader.calls, 2)

        let draft = repo.lastDraft
        XCTAssertEqual(draft?.rating, 4)
        XCTAssertEqual(draft?.body, "맛있어요")
        XCTAssertEqual(draft?.photos.count, 2)
        XCTAssertEqual(Set(draft?.tags ?? []), Set([.usucha, .modern]))
        XCTAssertEqual(draft?.drink, .usucha)
    }

    func test_submit_haltsWithPartialError_whenSomePhotosFail() async {
        let uploader = StubUploader()
        uploader.outcomes = [
            .success(URL(string: "https://ok/p1.jpg")!),
            .failure(MMDomainError.network("flaky"))
        ]
        let repo = MockReviewRepository()
        let (sut, _, _) = makeSUT(repo: repo, uploader: uploader)
        sut.rating = 5
        sut.body = "리뷰 본문"
        sut.addPhoto(data: Data([1]), fileName: "p1.jpg")
        sut.addPhoto(data: Data([2]), fileName: "p2.jpg")

        await sut.submit()

        XCTAssertEqual(repo.writeCallCount, 0, "사진이 부분 업로드되면 등록 안 함")
        XCTAssertEqual(sut.validationError, .network("photo_upload_partial"))
    }

    func test_submit_propagatesRepoError() async {
        let repo = MockReviewRepository()
        repo.stubError = MMDomainError.network("server-down")
        let (sut, _, _) = makeSUT(repo: repo)
        sut.rating = 5
        sut.body = "리뷰"

        await sut.submit()

        XCTAssertEqual(sut.submission.error, .network("server-down"))
    }

    // MARK: - Snapshot (네트워크 끊김 로컬 저장)

    func test_snapshot_andRestore_preservesFormState() async {
        let uploader = StubUploader()
        uploader.outcomes = [.success(URL(string: "https://ok/p1.jpg")!)]
        let (sut, _, _) = makeSUT(uploader: uploader)
        sut.rating = 4
        sut.body = "맛있어요"
        sut.toggleTag(.modern)
        sut.drink = .matchaLatte
        sut.addPhoto(data: Data([1]), fileName: "p1.jpg")
        await sut.uploadPendingPhotos()

        let snap = sut.snapshot()
        XCTAssertEqual(snap.rating, 4)
        XCTAssertEqual(snap.body, "맛있어요")
        XCTAssertEqual(snap.tags, [.modern])
        XCTAssertEqual(snap.drink, .matchaLatte)
        XCTAssertEqual(snap.uploadedPhotoURLs.count, 1)

        let (sut2, _, _) = makeSUT()
        sut2.restore(from: snap)
        XCTAssertEqual(sut2.rating, 4)
        XCTAssertEqual(sut2.body, "맛있어요")
        XCTAssertEqual(sut2.tags, [.modern])
        XCTAssertEqual(sut2.drink, .matchaLatte)
        XCTAssertEqual(sut2.photos.count, 1)
        XCTAssertEqual(sut2.photos.first?.uploadedURL?.absoluteString, "https://ok/p1.jpg")
    }
}
