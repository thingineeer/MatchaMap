import Foundation
import Domain
import DesignSystem
import Observation

/// 위시리스트 ViewModel.
/// ADR-304 — 게스트 모드 지원:
///   - `authState.isGuest`이면 UserDefaults(suiteName: "matchamap.guest")에 로컬 저장
///   - 게스트 cap = 5. 6번째 추가 시 `onRequireLogin?(.wishlistCap)` 콜백 호출, items 미증가
///   - 로그인 직후 `migrateLocalToFirestore()` 호출 → 로컬 → 서버 일괄 전환
@MainActor
@Observable
public final class WishlistViewModel {
    public private(set) var items: [WishlistItem] = []
    public private(set) var isLoading: Bool = false
    public private(set) var error: String?

    /// 옵티미스틱 토글: tap 즉시 UI 반영, 서버 응답으로 확정.
    /// 실패 시 rollback + error 토스트 (UI 측에서 관찰).
    public private(set) var optimisticPlaceIds: Set<String> = []

    /// ADR-304 — 게스트 5개 cap.
    public static let guestCap = 5

    /// ADR-304 — 게스트가 cap을 넘기거나 정식 인증이 필요한 동작 시 UI에 알림.
    public var onRequireLogin: ((LoginIntent) -> Void)?

    private let uid: String
    private var authState: AuthState
    private let listUseCase: any ListWishlistItemsUseCase
    private let toggleUseCase: any ToggleWishlistUseCase
    private let guestStore: GuestWishlistStore

    public init(
        uid: String,
        authState: AuthState = .authenticated(.fixture()),
        listUseCase: any ListWishlistItemsUseCase,
        toggleUseCase: any ToggleWishlistUseCase,
        guestStore: GuestWishlistStore = UserDefaultsGuestWishlistStore()
    ) {
        self.uid = uid
        self.authState = authState
        self.listUseCase = listUseCase
        self.toggleUseCase = toggleUseCase
        self.guestStore = guestStore
    }

    /// 외부에서 AuthState 갱신 시 호출 (예: AppContainer가 익명→정식 전환했을 때).
    public func updateAuthState(_ newValue: AuthState) {
        self.authState = newValue
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        if authState.isGuest {
            items = guestStore.load()
            return
        }
        do {
            let page = try await listUseCase(uid: uid, cursor: nil, limit: 50)
            items = page.items
        } catch {
            self.error = String(describing: error)
        }
    }

    /// 국가별 그룹 — handoff-mapping §12 "TOKYO/KYOTO/OSAKA" sectionizing.
    public var groupedByCountry: [(country: String, items: [WishlistItem])] {
        Dictionary(grouping: items, by: \.countryCode)
            .map { (country: $0.key, items: $0.value.sorted { $0.addedAt > $1.addedAt }) }
            .sorted { $0.country < $1.country }
    }

    /// 미니 세계지도용 — 각 위시 아이템 매장의 country를 representative coord로 매핑.
    public var worldMapHighlights: [GeoCoord] {
        items.compactMap { Self.countryCenter(for: $0.countryCode) }
    }

    /// 옵티미스틱 토글: 즉시 로컬 상태 변경 → 서버 호출 → 실패 시 rollback.
    /// 게스트일 때:
    ///   - 추가 시 items.count >= guestCap이면 `onRequireLogin(.wishlistCap)` 호출, items 미변경.
    ///   - 그 외(추가/제거)는 UserDefaults에 저장. 서버 호출 안 함.
    public func toggle(store: StoreSnapshot, note: String?) async {
        let pid = store.placeId
        let wasIn = items.contains(where: { $0.storeId == pid })

        // 게스트 모드: 로컬만 처리 + cap 검사.
        if authState.isGuest {
            if !wasIn && items.count >= Self.guestCap {
                onRequireLogin?(.wishlistCap)
                return
            }
            if wasIn {
                items.removeAll { $0.storeId == pid }
            } else {
                items.insert(makeWishItem(store: store, note: note), at: 0)
            }
            guestStore.save(items)
            return
        }

        // 정식 사용자: 옵티미스틱 + 서버.
        optimisticPlaceIds.insert(pid)
        let snapshot = items
        if wasIn {
            items.removeAll { $0.storeId == pid }
        } else {
            items.insert(makeWishItem(store: store, note: note), at: 0)
        }
        do {
            _ = try await toggleUseCase(uid: uid, store: store, note: note)
        } catch {
            items = snapshot
            self.error = String(describing: error)
        }
        optimisticPlaceIds.remove(pid)
    }

    /// ADR-304 — 게스트 → 정식 사용자 전환 직후 호출.
    /// 로컬에 저장된 items를 서버에 batch 추가하고 로컬 store는 비운다.
    /// 부분 실패 시 남은 로컬은 그대로. 호출 후 `load()`로 서버 fresh fetch 권장.
    @discardableResult
    public func migrateLocalToFirestore() async -> Int {
        let local = guestStore.load()
        guard !local.isEmpty else { return 0 }
        var migrated = 0
        for item in local {
            do {
                _ = try await toggleUseCase(uid: uid, store: item.store, note: item.note)
                migrated += 1
            } catch {
                self.error = String(describing: error)
                return migrated
            }
        }
        guestStore.clear()
        return migrated
    }

    /// 국가 중심 좌표 — ISO-3166 alpha-2 → 대표 좌표.
    /// MVP: 자주 쓰는 마켓만 hardcoded. 그 외 nil → mini-map 표시 안 함.
    /// nonisolated: 순수 함수 — actor isolation 불필요.
    public nonisolated static func countryCenter(for code: String) -> GeoCoord? {
        switch code.uppercased() {
        case "KR": return GeoCoord(latitude: 37.5665, longitude: 126.9780)
        case "JP": return GeoCoord(latitude: 35.6762, longitude: 139.6503)
        case "US": return GeoCoord(latitude: 39.8283, longitude: -98.5795)
        case "GB": return GeoCoord(latitude: 51.5074, longitude: -0.1278)
        case "DE": return GeoCoord(latitude: 52.5200, longitude: 13.4050)
        case "FR": return GeoCoord(latitude: 48.8566, longitude: 2.3522)
        case "TW": return GeoCoord(latitude: 25.0330, longitude: 121.5654)
        case "CN": return GeoCoord(latitude: 39.9042, longitude: 116.4074)
        default: return nil
        }
    }

    private func makeWishItem(store: StoreSnapshot, note: String?) -> WishlistItem {
        WishlistItem(
            storeId: store.placeId,
            uid: uid,
            countryCode: store.countryCode,
            store: store,
            note: note,
            addedAt: Date()
        )
    }
}

// MARK: - Guest local store

/// ADR-304 — 게스트 위시리스트 영속 인터페이스.
/// 기본 구현은 UserDefaults(suiteName: "matchamap.guest"). 테스트는 인메모리 스텁 주입.
public protocol GuestWishlistStore: Sendable {
    func load() -> [WishlistItem]
    func save(_ items: [WishlistItem])
    func clear()
}

public struct UserDefaultsGuestWishlistStore: GuestWishlistStore {
    public static let suiteName = "matchamap.guest"
    public static let key = "wishlist.items"

    /// UserDefaults는 Foundation에서 non-Sendable이라 nonisolated(unsafe) 보관.
    /// UserDefaults 자체는 thread-safe이며 본 wrapper는 단순 read/write만.
    nonisolated(unsafe) private let defaults: UserDefaults

    public init(defaults: UserDefaults? = nil) {
        self.defaults = defaults
            ?? UserDefaults(suiteName: Self.suiteName)
            ?? .standard
    }

    public func load() -> [WishlistItem] {
        guard let data = defaults.data(forKey: Self.key) else { return [] }
        return (try? JSONDecoder().decode([WishlistItem].self, from: data)) ?? []
    }

    public func save(_ items: [WishlistItem]) {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: Self.key)
        }
    }

    public func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}

/// ADR-304 — UI에 어떤 게이트로 로그인이 요구됐는지 알리는 의미 라벨.
/// FeatureAuth의 LoginView 카피를 분기.
public enum LoginIntent: String, Identifiable, Sendable, Hashable, CaseIterable {
    case review
    case collectionUnlock
    case wishlistCap
    case friend
    case profile
    case push
    case rewarded

    public var id: String { rawValue }
}
