import Testing
import Foundation
@testable import Domain

@Suite("AddCollectionItem UseCase — validation + fanout response")
struct AddCollectionItemTests {

    @Test("storeId 빈 값 → invalidInput")
    func emptyStoreIdRejected() async throws {
        let repo = MockCollectionRepository()
        let usecase = AddCollectionItemUseCaseImpl(repository: repo)
        let draft = CollectionItemDraft(storeId: "", drink: .usucha)

        await #expect(throws: MMDomainError.self) {
            _ = try await usecase(draft)
        }
    }

    @Test("viaReview true인데 linkedReviewId 비어있으면 invalidInput")
    func viaReviewRequiresLinkedReviewId() async throws {
        let repo = MockCollectionRepository()
        let usecase = AddCollectionItemUseCaseImpl(repository: repo)
        let draft = CollectionItemDraft(
            storeId: "ChIJ_X",
            drink: .usucha,
            viaReview: true,
            linkedReviewId: nil
        )
        await #expect(throws: MMDomainError.self) {
            _ = try await usecase(draft)
        }
    }

    @Test("photo 4장 이상 → invalidInput")
    func tooManyPhotosRejected() async throws {
        let repo = MockCollectionRepository()
        let usecase = AddCollectionItemUseCaseImpl(repository: repo)
        let urls = (0..<4).compactMap { URL(string: "gs://bucket/\($0).jpg") }
        let draft = CollectionItemDraft(storeId: "ChIJ_X", drink: .usucha, photoURLs: urls)

        await #expect(throws: MMDomainError.self) {
            _ = try await usecase(draft)
        }
    }

    @Test("정상 추가 → itemId + collectionCount 반환")
    func successReturnsIdAndCount() async throws {
        let repo = MockCollectionRepository()
        let usecase = AddCollectionItemUseCaseImpl(repository: repo)
        let draft = CollectionItemDraft(
            storeId: "ChIJ_OK",
            drink: .koicha,
            grade: .ceremonial,
            originRegion: .jeju,
            colorTier: .deepMatcha
        )
        let result = try await usecase(draft)
        #expect(result.itemId.hasPrefix("ITEM_"))
        #expect(result.collectionCount == 1)
    }
}
