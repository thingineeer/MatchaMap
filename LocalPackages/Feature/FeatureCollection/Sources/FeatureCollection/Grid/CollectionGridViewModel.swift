import Foundation
import Domain
import Observation

/// 도감 그리드 ViewModel.
/// LazyVGrid + cursor 페이지네이션 + prefetch.
/// 250+ 항목 60fps 목표 — items: [CollectionItem] 배열 + ID 기반 diffing(SwiftUI가 처리).
/// ADR-304: 게스트는 도감 자체 차단 — `onAppear` 호출 시 `state == .guestRequired`로 빈 상태.
@MainActor
@Observable
public final class CollectionGridViewModel {
    /// ADR-304 — 게스트 차단 여부를 UI가 단일 불값으로 관찰.
    public enum State: Sendable, Equatable {
        case ready          // 정식 사용자 — 일반 로딩 흐름
        case guestRequired  // 게스트 — 빈 상태 + 로그인 CTA
    }

    public private(set) var state: State = .ready
    public private(set) var items: [CollectionItem] = []
    public private(set) var isLoading: Bool = false
    public private(set) var error: String?
    public private(set) var hasMore: Bool = true
    /// 보상형 광고로 unlock된 슬롯 수 — FeatureMonetize에서 주입.
    public var unlockedSlots: Int = 0

    /// ADR-304 — 게스트 차단 시 로그인 시트 트리거.
    public var onRequireLogin: ((LoginIntent) -> Void)?

    private var cursor: PaginationCursor?
    private let uid: String
    private var authState: AuthState
    private let listUseCase: any ListCollectionItemsUseCase
    private let pageSize: Int

    public init(
        uid: String,
        authState: AuthState = .authenticated(.fixture()),
        listUseCase: any ListCollectionItemsUseCase,
        pageSize: Int = 20
    ) {
        self.uid = uid
        self.authState = authState
        self.listUseCase = listUseCase
        self.pageSize = pageSize
        self.state = authState.isAuthenticated ? .ready : .guestRequired
    }

    public func updateAuthState(_ newValue: AuthState) {
        self.authState = newValue
        self.state = newValue.isAuthenticated ? .ready : .guestRequired
    }

    public func loadInitial() async {
        if authState.isGuest {
            state = .guestRequired
            return
        }
        guard items.isEmpty, !isLoading else { return }
        await fetchPage(reset: true)
    }

    public func loadMoreIfNeeded(currentItem: CollectionItem?) async {
        if authState.isGuest { return }
        guard let currentItem else { return }
        guard hasMore, !isLoading else { return }
        // prefetch: 끝에서 5번째 항목을 봤을 때 다음 페이지 로드.
        let triggerIndex = max(0, items.count - 5)
        guard let idx = items.firstIndex(of: currentItem), idx >= triggerIndex else { return }
        await fetchPage(reset: false)
    }

    public func refresh() async {
        if authState.isGuest {
            state = .guestRequired
            return
        }
        cursor = nil
        hasMore = true
        await fetchPage(reset: true)
    }

    /// 도감 슬롯 unlock 요청 — 게스트는 즉시 로그인 시트 요구.
    public func requestUnlock(slotIndex: Int) {
        if authState.isGuest {
            onRequireLogin?(.collectionUnlock)
            return
        }
        // 정식 사용자 흐름은 FeatureMonetize 보상형 광고에서 처리(외부 콜백).
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
