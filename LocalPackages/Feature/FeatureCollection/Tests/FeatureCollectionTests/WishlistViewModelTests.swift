import Testing
import Foundation
import Domain
@testable import FeatureCollection

@Suite("WishlistViewModel — optimistic toggle + group by country")
struct WishlistViewModelTests {

    @MainActor
    private func makeVM(initial: [WishlistItem] = []) -> (WishlistViewModel, MockWishlistRepository) {
        let repo = MockWishlistRepository()
        let vm = WishlistViewModel(
            uid: "uid_self",
            listUseCase: ListWishlistItemsUseCaseImpl(repository: repo),
            toggleUseCase: ToggleWishlistUseCaseImpl(repository: repo)
        )
        return (vm, repo)
    }

    @Test("toggle add → 즉시 items에 반영")
    @MainActor
    func toggleAddImmediate() async {
        let (vm, _) = makeVM()
        let store = StoreSnapshot.fixture(placeId: "ChIJ_TOKYO", countryCode: "JP")
        await vm.toggle(store: store, note: nil)
        #expect(vm.items.count == 1)
        #expect(vm.items.first?.storeId == "ChIJ_TOKYO")
    }

    @Test("같은 매장 toggle 두 번 → 최종 items 비어있음")
    @MainActor
    func toggleAddRemove() async {
        let (vm, _) = makeVM()
        let store = StoreSnapshot.fixture(placeId: "ChIJ_TOKYO_2", countryCode: "JP")
        await vm.toggle(store: store, note: "다음 도쿄 갈때")
        await vm.toggle(store: store, note: nil)
        #expect(vm.items.isEmpty)
    }

    @Test("groupedByCountry — KR/JP 두 그룹 정렬")
    @MainActor
    func groupedByCountrySorts() async {
        let (vm, _) = makeVM()
        await vm.toggle(store: .fixture(placeId: "JP_1", countryCode: "JP"), note: nil)
        await vm.toggle(store: .fixture(placeId: "KR_1", countryCode: "KR"), note: nil)
        await vm.toggle(store: .fixture(placeId: "JP_2", countryCode: "JP"), note: nil)

        let groups = vm.groupedByCountry
        #expect(groups.count == 2)
        let countries = groups.map(\.country)
        #expect(countries == ["JP", "KR"])
        let jpGroup = groups.first { $0.country == "JP" }!
        #expect(jpGroup.items.count == 2)
    }

    @Test("worldMapHighlights — 추가된 country 좌표만 노출")
    @MainActor
    func worldMapHighlightsForKnownCountries() async {
        let (vm, _) = makeVM()
        await vm.toggle(store: .fixture(placeId: "KR_X", countryCode: "KR"), note: nil)
        await vm.toggle(store: .fixture(placeId: "ZZ_X", countryCode: "ZZ"), note: nil)
        // ZZ는 미지원 → countryCenter nil → highlights에 미포함.
        #expect(vm.worldMapHighlights.count == 1)
    }

    @Test("서버 실패 → optimistic 제거 (rollback)")
    @MainActor
    func failureRollsBack() async {
        let (vm, repo) = makeVM()
        await repo.setStubError(MMDomainError.network("x"))
        await vm.toggle(store: .fixture(placeId: "FAIL_1", countryCode: "JP"), note: nil)
        // 실패 시 items rollback (빈 상태로)
        #expect(vm.items.isEmpty)
        #expect(vm.error != nil)
    }
}
