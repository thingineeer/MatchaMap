import XCTest
import Domain
@testable import FeatureStore

@MainActor
final class StoreDetailViewModelTests: XCTestCase {

    private func makeSUT(
        storeId: String = "s-1",
        storeRepo: MockStoreRepository = MockStoreRepository(),
        reviewRepo: MockReviewRepository = MockReviewRepository()
    ) -> (StoreDetailViewModel, MockStoreRepository, MockReviewRepository) {
        let getStore = GetStoreDetailsUseCaseImpl(repository: storeRepo)
        let getReviews = GetStoreReviewsUseCaseImpl(repository: reviewRepo)
        let vm = StoreDetailViewModel(
            storeId: storeId,
            getStoreDetails: getStore,
            getStoreReviews: getReviews
        )
        return (vm, storeRepo, reviewRepo)
    }

    func test_onAppear_loadsStoreAndFirstReviewPage() async {
        let storeRepo = MockStoreRepository()
        storeRepo.stubStore = .preview(id: "s-1", matchaScore: 4.6)
        let reviewRepo = MockReviewRepository()
        reviewRepo.stubPage = ReviewPage(items: [.preview(id: "r1"), .preview(id: "r2")], nextCursor: "next")
        let (sut, _, _) = makeSUT(storeRepo: storeRepo, reviewRepo: reviewRepo)

        await sut.onAppear()

        XCTAssertEqual(sut.store.value?.id, "s-1")
        XCTAssertEqual(sut.reviews.value?.items.count, 2)
        XCTAssertEqual(reviewRepo.lastSort, .latest)
        XCTAssertEqual(reviewRepo.lastLimit, 20)
    }

    func test_onAppear_sets_failed_whenStoreLoadFails() async {
        let storeRepo = MockStoreRepository()
        storeRepo.stubError = MMDomainError.notFound
        let (sut, _, _) = makeSUT(storeRepo: storeRepo)

        await sut.onAppear()

        XCTAssertEqual(sut.store.error, .notFound)
        // reviews도 같은 repo의 stubError가 아니지만, 동일 error type을 reviewRepo가 안 가짐
        XCTAssertNil(sut.reviews.error)
    }

    func test_retry_refetches() async {
        let storeRepo = MockStoreRepository()
        storeRepo.stubStore = .preview(id: "s-1")
        let (sut, _, reviewRepo) = makeSUT(storeRepo: storeRepo)
        await sut.onAppear()
        let firstCount = reviewRepo.reviewsCallCount

        await sut.retry()

        XCTAssertEqual(reviewRepo.reviewsCallCount, firstCount + 1)
    }

    func test_selectSort_reloadsReviews_whenChanged() async {
        let (sut, storeRepo, reviewRepo) = makeSUT()
        storeRepo.stubStore = .preview()
        await sut.onAppear()
        let baseCalls = reviewRepo.reviewsCallCount

        await sut.selectSort(.rating)

        XCTAssertEqual(sut.sort, .rating)
        XCTAssertEqual(reviewRepo.lastSort, .rating)
        XCTAssertEqual(reviewRepo.reviewsCallCount, baseCalls + 1)
    }

    func test_selectSort_skips_whenSame() async {
        let (sut, storeRepo, reviewRepo) = makeSUT()
        storeRepo.stubStore = .preview()
        await sut.onAppear()
        let baseCalls = reviewRepo.reviewsCallCount

        await sut.selectSort(.latest)  // already .latest

        XCTAssertEqual(reviewRepo.reviewsCallCount, baseCalls, "동일 sort 재선택 시 재조회 안 함")
    }

    func test_ratingDistribution_isNil_whenNoReviews() async {
        let storeRepo = MockStoreRepository()
        storeRepo.stubStore = Store(
            id: "x",
            name: "Empty",
            location: Coordinate(latitude: 0, longitude: 0),
            grade: .basic,
            matchaScore: 3.0,
            countryCode: "KR",
            reviewCount: 0,
            ratingHistogram: [:]
        )
        let (sut, _, _) = makeSUT(storeRepo: storeRepo)
        await sut.onAppear()

        XCTAssertNil(sut.ratingDistribution)
    }

    func test_ratingDistribution_returnsFiveBucketsDescending() async {
        let storeRepo = MockStoreRepository()
        storeRepo.stubStore = Store(
            id: "x",
            name: "Filled",
            location: Coordinate(latitude: 0, longitude: 0),
            grade: .premium,
            matchaScore: 4.0,
            countryCode: "KR",
            reviewCount: 10,
            ratingAvg: 4.0,
            ratingHistogram: [5: 5, 4: 3, 3: 1, 2: 1, 1: 0]
        )
        let (sut, _, _) = makeSUT(storeRepo: storeRepo)
        await sut.onAppear()

        let dist = sut.ratingDistribution
        XCTAssertNotNil(dist)
        XCTAssertEqual(dist?.count, 5)
        XCTAssertEqual(dist?.first?.rating, 5, "5점부터 내림차순")
        XCTAssertEqual(dist?.last?.rating, 1)
        let five = dist?.first
        XCTAssertEqual(five?.count, 5)
        XCTAssertEqual(five?.fraction, 0.5, accuracy: 0.001)
    }

    func test_selectedTab_isOverviewByDefault_andCanChange() async {
        let (sut, _, _) = makeSUT()
        XCTAssertEqual(sut.selectedTab, .overview)
        sut.selectedTab = .reviews
        XCTAssertEqual(sut.selectedTab, .reviews)
    }
}
