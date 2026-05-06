import Testing
import Foundation
import Domain
@testable import FeatureCollection

@Suite("WishlistViewModel — ADR-304 게스트 모드")
struct WishlistGuestModeTests {

    /// 인메모리 게스트 store (UserDefaults 격리).
    final class InMemoryGuestStore: GuestWishlistStore, @unchecked Sendable {
        var items: [WishlistItem] = []
        func load() -> [WishlistItem] { items }
        func save(_ items: [WishlistItem]) { self.items = items }
        func clear() { items = [] }
    }

    @MainActor
    private func makeVM(
        authState: AuthState,
        guestStore: InMemoryGuestStore = InMemoryGuestStore()
    ) -> (WishlistViewModel, MockWishlistRepository, InMemoryGuestStore) {
        let repo = MockWishlistRepository()
        let vm = WishlistViewModel(
            uid: authState.uid ?? "anon",
            authState: authState,
            listUseCase: ListWishlistItemsUseCaseImpl(repository: repo),
            toggleUseCase: ToggleWishlistUseCaseImpl(repository: repo),
            guestStore: guestStore
        )
        return (vm, repo, guestStore)
    }

    @Test("게스트 — 5개까지 추가 OK")
    @MainActor
    func guestUpToCap() async {
        let (vm, _, store) = makeVM(authState: .guest(anonymousUid: "anon-1"))
        for i in 0..<WishlistViewModel.guestCap {
            await vm.toggle(store: .fixture(placeId: "p\(i)", countryCode: "JP"), note: nil)
        }
        #expect(vm.items.count == 5)
        #expect(store.items.count == 5)
    }

    @Test("게스트 — 6번째 추가는 onRequireLogin(.wishlistCap) 발화 + items 미증가")
    @MainActor
    func guestSixthTriggersLoginIntent() async {
        let (vm, _, _) = makeVM(authState: .guest(anonymousUid: "anon-2"))
        var captured: LoginIntent?
        vm.onRequireLogin = { captured = $0 }

        for i in 0..<WishlistViewModel.guestCap {
            await vm.toggle(store: .fixture(placeId: "p\(i)", countryCode: "KR"), note: nil)
        }
        await vm.toggle(store: .fixture(placeId: "px-6", countryCode: "KR"), note: nil)

        #expect(vm.items.count == 5)
        #expect(captured == .wishlistCap)
    }

    @Test("게스트 — toggle 결과가 UserDefaultsGuestStore에 영속")
    @MainActor
    func guestSavesToLocalStore() async {
        let store = InMemoryGuestStore()
        let (vm, _, _) = makeVM(authState: .guest(anonymousUid: "anon-3"), guestStore: store)
        await vm.toggle(store: .fixture(placeId: "p-saved", countryCode: "JP"), note: "재방문")
        #expect(store.items.first?.storeId == "p-saved")
        #expect(store.items.first?.note == "재방문")
    }

    @Test("게스트 — load() 시 로컬 store에서 복원")
    @MainActor
    func guestLoadFromLocalStore() async {
        let store = InMemoryGuestStore()
        store.items = [
            WishlistItem(
                storeId: "restored-1",
                uid: "anon-4",
                countryCode: "KR",
                store: .fixture(placeId: "restored-1", countryCode: "KR"),
                note: nil,
                addedAt: Date()
            )
        ]
        let (vm, _, _) = makeVM(authState: .guest(anonymousUid: "anon-4"), guestStore: store)
        await vm.load()
        #expect(vm.items.count == 1)
        #expect(vm.items.first?.storeId == "restored-1")
    }

    @Test("게스트 → 정식 마이그레이션 — 로컬 비우고 서버 호출 N회")
    @MainActor
    func migrateLocalToFirestoreClearsLocal() async {
        let store = InMemoryGuestStore()
        store.items = [
            .init(storeId: "m-1", uid: "u", countryCode: "JP",
                  store: .fixture(placeId: "m-1", countryCode: "JP"), note: nil, addedAt: Date()),
            .init(storeId: "m-2", uid: "u", countryCode: "JP",
                  store: .fixture(placeId: "m-2", countryCode: "JP"), note: nil, addedAt: Date())
        ]
        let (vm, repo, _) = makeVM(authState: .authenticated(.fixture(uid: "u")), guestStore: store)
        let migrated = await vm.migrateLocalToFirestore()
        #expect(migrated == 2)
        #expect(store.items.isEmpty, "전부 성공 시 로컬 비움")
        let saved = try? await repo.items(uid: "u", cursor: nil, limit: 50)
        #expect(saved?.items.count == 2)
    }

    @Test("정식 사용자 — toggle은 서버 호출 (cap 무시)")
    @MainActor
    func authenticatedSkipsCap() async {
        let (vm, repo, _) = makeVM(authState: .authenticated(.fixture(uid: "u")))
        for i in 0..<10 {
            await vm.toggle(store: .fixture(placeId: "auth-\(i)", countryCode: "JP"), note: nil)
        }
        #expect(vm.items.count == 10)
        let saved = try? await repo.items(uid: "u", cursor: nil, limit: 50)
        #expect(saved?.items.count == 10)
    }
}
