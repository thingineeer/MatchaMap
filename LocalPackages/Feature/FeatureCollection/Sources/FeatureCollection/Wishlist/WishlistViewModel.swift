import Foundation
import Domain
import DesignSystem
import Observation

@MainActor
@Observable
public final class WishlistViewModel {
    public private(set) var items: [WishlistItem] = []
    public private(set) var isLoading: Bool = false
    public private(set) var error: String?

    /// 옵티미스틱 토글: tap 즉시 UI 반영, 서버 응답으로 확정.
    /// 실패 시 rollback + error 토스트 (UI 측에서 관찰).
    public private(set) var optimisticPlaceIds: Set<String> = []

    private let uid: String
    private let listUseCase: any ListWishlistItemsUseCase
    private let toggleUseCase: any ToggleWishlistUseCase

    public init(
        uid: String,
        listUseCase: any ListWishlistItemsUseCase,
        toggleUseCase: any ToggleWishlistUseCase
    ) {
        self.uid = uid
        self.listUseCase = listUseCase
        self.toggleUseCase = toggleUseCase
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
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
    public func toggle(store: StoreSnapshot, note: String?) async {
        let pid = store.placeId
        let wasIn = items.contains(where: { $0.storeId == pid })
        optimisticPlaceIds.insert(pid)
        let snapshot = items
        if wasIn {
            items.removeAll { $0.storeId == pid }
        } else {
            items.insert(
                WishlistItem(
                    storeId: pid,
                    uid: uid,
                    countryCode: store.countryCode,
                    store: store,
                    note: note,
                    addedAt: Date()
                ),
                at: 0
            )
        }
        do {
            _ = try await toggleUseCase(uid: uid, store: store, note: note)
        } catch {
            items = snapshot
            self.error = String(describing: error)
        }
        optimisticPlaceIds.remove(pid)
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
}
