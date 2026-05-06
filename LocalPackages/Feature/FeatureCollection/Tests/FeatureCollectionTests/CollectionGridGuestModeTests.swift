import Testing
import Foundation
import Domain
@testable import FeatureCollection

@Suite("CollectionGridViewModel — ADR-304 게스트 차단")
struct CollectionGridGuestModeTests {

    @Test("게스트 — init 시 state == .guestRequired")
    @MainActor
    func guestInitState() {
        let vm = CollectionGridViewModel(
            uid: "anon",
            authState: .guest(anonymousUid: "anon-1"),
            listUseCase: ListCollectionItemsUseCaseImpl(repository: MockCollectionRepository())
        )
        #expect(vm.state == .guestRequired)
    }

    @Test("게스트 — loadInitial은 네트워크 호출 없이 .guestRequired 유지")
    @MainActor
    func guestLoadInitialNoFetch() async {
        let repo = MockCollectionRepository()
        let vm = CollectionGridViewModel(
            uid: "anon",
            authState: .guest(anonymousUid: "anon-1"),
            listUseCase: ListCollectionItemsUseCaseImpl(repository: repo)
        )
        await vm.loadInitial()
        #expect(vm.state == .guestRequired)
        #expect(vm.items.isEmpty)
    }

    @Test("게스트 — requestUnlock(slotIndex:)는 onRequireLogin(.collectionUnlock) 호출")
    @MainActor
    func guestRequestUnlockTriggersLogin() {
        let vm = CollectionGridViewModel(
            uid: "anon",
            authState: .guest(anonymousUid: "anon-1"),
            listUseCase: ListCollectionItemsUseCaseImpl(repository: MockCollectionRepository())
        )
        var captured: LoginIntent?
        vm.onRequireLogin = { captured = $0 }
        vm.requestUnlock(slotIndex: 3)
        #expect(captured == .collectionUnlock)
    }

    @Test("정식 사용자 — state == .ready, loadInitial 동작")
    @MainActor
    func authenticatedReady() async {
        let repo = MockCollectionRepository(initial: ["uid_self": [.fixture(id: "i1")]])
        let vm = CollectionGridViewModel(
            uid: "uid_self",
            authState: .authenticated(.fixture(uid: "uid_self")),
            listUseCase: ListCollectionItemsUseCaseImpl(repository: repo)
        )
        #expect(vm.state == .ready)
        await vm.loadInitial()
        #expect(vm.items.count == 1)
    }

    @Test("updateAuthState — 익명→정식 전환 시 state .ready")
    @MainActor
    func updateAuthStateFlipsToReady() {
        let vm = CollectionGridViewModel(
            uid: "u",
            authState: .guest(anonymousUid: "anon-1"),
            listUseCase: ListCollectionItemsUseCaseImpl(repository: MockCollectionRepository())
        )
        #expect(vm.state == .guestRequired)
        vm.updateAuthState(.authenticated(.fixture(uid: "u")))
        #expect(vm.state == .ready)
    }
}
