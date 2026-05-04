import Foundation
import Domain
import Observation

/// 도감 그리드 ViewModel.
/// LazyVGrid + cursor 페이지네이션 + prefetch.
/// 250+ 항목 60fps 목표 — items: [CollectionItem] 배열 + ID 기반 diffing(SwiftUI가 처리).
@MainActor
@Observable
public final class CollectionGridViewModel {
    public private(set) var items: [CollectionItem] = []
    public private(set) var isLoading: Bool = false
    public private(set) var error: String?
    public private(set) var hasMore: Bool = true
    /// 보상형 광고로 unlock된 슬롯 수 — FeatureMonetize에서 주입.
    public var unlockedSlots: Int = 0

    private var cursor: PaginationCursor?
    private let uid: String
    private let listUseCase: any ListCollectionItemsUseCase
    private let pageSize: Int

    public init(
        uid: String,
        listUseCase: any ListCollectionItemsUseCase,
        pageSize: Int = 20
    ) {
        self.uid = uid
        self.listUseCase = listUseCase
        self.pageSize = pageSize
    }

    public func loadInitial() async {
        guard items.isEmpty, !isLoading else { return }
        await fetchPage(reset: true)
    }

    public func loadMoreIfNeeded(currentItem: CollectionItem?) async {
        guard let currentItem else { return }
        guard hasMore, !isLoading else { return }
        // prefetch: 끝에서 5번째 항목을 봤을 때 다음 페이지 로드.
        let triggerIndex = max(0, items.count - 5)
        guard let idx = items.firstIndex(of: currentItem), idx >= triggerIndex else { return }
        await fetchPage(reset: false)
    }

    public func refresh() async {
        cursor = nil
        hasMore = true
        await fetchPage(reset: true)
    }

    private func fetchPage(reset: Bool) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let page = try await listUseCase(uid: uid, cursor: reset ? nil : cursor, limit: pageSize)
            if reset {
                items = page.items
            } else {
                items.append(contentsOf: page.items)
            }
            cursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch {
            self.error = String(describing: error)
        }
    }
}
