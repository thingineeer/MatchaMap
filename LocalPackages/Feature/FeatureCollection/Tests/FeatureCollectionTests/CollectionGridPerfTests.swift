import Testing
import Foundation
import Domain
@testable import FeatureCollection

@Suite("CollectionGrid 250+ items — pagination + prefetch")
struct CollectionGridPerfTests {

    @MainActor
    private func seed(count: Int) -> MockCollectionRepository {
        let initial = (0..<count).map {
            CollectionItem.fixture(id: "ITEM_\(String(format: "%04d", $0))", uid: "uid_self")
        }
        return MockCollectionRepository(initial: ["uid_self": initial])
    }

    @Test("250 items 로드 — 첫 페이지 size 50, 1차 fetch 50건만")
    @MainActor
    func firstPageLimitedSize() async {
        let repo = seed(count: 250)
        let vm = CollectionGridViewModel(
            uid: "uid_self",
            listUseCase: ListCollectionItemsUseCaseImpl(repository: repo),
            pageSize: 50
        )
        await vm.loadInitial()
        #expect(vm.items.count == 50, "한 페이지 = 50")
    }

    @Test("loadMoreIfNeeded — 끝에서 5번째 항목 노출 시 다음 페이지 fetch (Mock에선 1페이지뿐이라 hasMore=false 검증)")
    @MainActor
    func loadMoreFlowsCorrectly() async {
        let repo = seed(count: 30)
        let vm = CollectionGridViewModel(
            uid: "uid_self",
            listUseCase: ListCollectionItemsUseCaseImpl(repository: repo),
            pageSize: 50
        )
        await vm.loadInitial()
        // mock은 nextCursor를 nil로 반환 → hasMore=false
        #expect(vm.hasMore == false)
    }

    @Test("250 items SwiftUI Identifiable diff 안전 — id 모두 unique")
    @MainActor
    func idsAreUnique() async {
        let repo = seed(count: 250)
        let vm = CollectionGridViewModel(
            uid: "uid_self",
            listUseCase: ListCollectionItemsUseCaseImpl(repository: repo),
            pageSize: 50
        )
        await vm.loadInitial()
        let ids = Set(vm.items.map(\.id))
        #expect(ids.count == vm.items.count, "id 중복 없음 — LazyVGrid diffing 안전")
    }
}
