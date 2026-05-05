import Foundation
import Observation
import Domain

/// 매장 상세 화면(handoff-mapping.md 화면 7,8) ViewModel.
/// - 진입 시 매장 정보 + 첫 페이지 리뷰 동시 로드 (병렬)
/// - 탭 전환은 in-memory cached, 리뷰는 정렬 변경 시 cursor reset 후 재로드
/// - 에러 시 skeleton + retry (ios-store agent §에러)
@MainActor
@Observable
public final class StoreDetailViewModel {

    // MARK: - State (read-only from view)
    public private(set) var storeId: String
    public private(set) var store: LoadState<Store> = .idle
    public private(set) var reviews: LoadState<ReviewPage> = .idle
    public private(set) var sort: ReviewSortOrder = .latest
    public var selectedTab: StoreDetailTab = .overview

    // MARK: - Dependencies
    private let getStoreDetails: any GetStoreDetailsUseCase
    private let getStoreReviews: any GetStoreReviewsUseCase

    public init(
        storeId: String,
        getStoreDetails: any GetStoreDetailsUseCase,
        getStoreReviews: any GetStoreReviewsUseCase
    ) {
        self.storeId = storeId
        self.getStoreDetails = getStoreDetails
        self.getStoreReviews = getStoreReviews
    }

    // MARK: - Intents

    public func onAppear() async {
        await load()
    }

    public func retry() async {
        await load()
    }

    public func selectSort(_ newSort: ReviewSortOrder) async {
        guard sort != newSort else { return }
        sort = newSort
        await loadReviews()
    }

    /// 매장 + 첫 페이지 리뷰 병렬 로드.
    private func load() async {
        store = .loading
        reviews = .loading
        async let storeTask: Void = loadStore()
        async let reviewsTask: Void = loadReviewsInternal(sort: sort)
        _ = await (storeTask, reviewsTask)
    }

    private func loadStore() async {
        do {
            let result = try await getStoreDetails(id: storeId)
            store = .loaded(result)
        } catch {
            store = .failed(mmError(error))
        }
    }

    private func loadReviews() async {
        reviews = .loading
        await loadReviewsInternal(sort: sort)
    }

    private func loadReviewsInternal(sort: ReviewSortOrder) async {
        do {
            let page = try await getStoreReviews(storeId: storeId, sort: sort, limit: 20, cursor: nil)
            reviews = .loaded(page)
        } catch {
            reviews = .failed(mmError(error))
        }
    }

    // MARK: - Derived

    /// 별점 분포 막대(1~5). 합계 0이면 nil. (handoff-mapping 화면 8 rating summary)
    public var ratingDistribution: [(rating: Int, count: Int, fraction: Double)]? {
        guard let s = store.value, s.reviewCount > 0 else { return nil }
        let total = max(s.reviewCount, 1)
        return (1...5).reversed().map { rating in
            let count = s.ratingHistogram[rating] ?? 0
            return (rating: rating, count: count, fraction: Double(count) / Double(total))
        }
    }
}
