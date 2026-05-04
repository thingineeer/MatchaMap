import Testing
import Foundation
@testable import Domain

@Suite("Wishlist toggle idempotent + race condition")
struct WishlistToggleTests {

    @Test("같은 매장 toggle 두 번 호출하면 add → remove 순으로 최종 상태 false")
    func toggleAddThenRemove() async throws {
        let repo = MockWishlistRepository()
        let usecase = ToggleWishlistUseCaseImpl(repository: repo)
        let store = StoreSnapshot.fixture(placeId: "ChIJ_TOKYO_1", countryCode: "JP")

        let after1 = try await usecase(uid: "uid_self", store: store, note: "다음 도쿄 갈때")
        #expect(after1 == true)
        let after2 = try await usecase(uid: "uid_self", store: store, note: nil)
        #expect(after2 == false)

        let final = try await repo.contains(uid: "uid_self", storeId: "ChIJ_TOKYO_1")
        #expect(final == false)
    }

    @Test("동시 토글 race condition — 동일 storeId에 N개 동시 toggle 시 actor 격리로 일관성 유지")
    func concurrentToggleRaceCondition() async throws {
        let repo = MockWishlistRepository()
        await repo.setToggleDelay(.milliseconds(5))
        let store = StoreSnapshot.fixture(placeId: "ChIJ_RACE_1", countryCode: "KR")

        // 4번 동시 토글 → 짝수번 → 최종 false (제거 상태) 보장.
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<4 {
                group.addTask {
                    _ = try? await repo.toggle(uid: "uid_self", store: store, note: nil)
                }
            }
        }

        let calls = await repo.toggleCallCount
        #expect(calls == 4)
        let contained = try await repo.contains(uid: "uid_self", storeId: "ChIJ_RACE_1")
        #expect(contained == false, "짝수 토글 → 최종 미포함 상태 보장")
    }

    @Test("note 길이 200자 초과 시 invalidInput")
    func noteLengthValidation() async throws {
        let repo = MockWishlistRepository()
        let usecase = ToggleWishlistUseCaseImpl(repository: repo)
        let longNote = String(repeating: "가", count: 201)

        await #expect(throws: MMDomainError.self) {
            _ = try await usecase(uid: "uid_self", store: .fixture(), note: longNote)
        }
    }
}
