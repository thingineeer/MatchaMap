import Testing
import Foundation
@testable import Domain

@Suite("Feed optimistic like — race condition / rollback")
struct FeedLikeRaceTests {

    @Test("toggleLike 두 번 호출 시 false (cancel) — 옵티미스틱 일관성")
    func toggleTwiceCancels() async throws {
        let repo = MockFeedRepository()
        let usecase = ToggleLikeUseCaseImpl(repository: repo)

        let after1 = try await usecase(uid: "uid_self", targetType: .review, targetId: "rev_1")
        #expect(after1 == true)
        let after2 = try await usecase(uid: "uid_self", targetType: .review, targetId: "rev_1")
        #expect(after2 == false)
    }

    @Test("동시 좋아요 토글 — actor 직렬화로 호출 횟수 4 / 최종 상태 짝수 → unliked")
    func concurrentToggleSerializes() async throws {
        let repo = MockFeedRepository()
        await repo.setLikeDelay(.milliseconds(5))

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<4 {
                group.addTask {
                    _ = try? await repo.toggleLike(targetType: .review, targetId: "rev_2", uid: "uid_self")
                }
            }
        }
        let calls = await repo.toggleLikeCallCount
        #expect(calls == 4)
        let likedBy = await repo.likedBy(targetId: "rev_2")
        #expect(likedBy.contains("uid_self") == false, "짝수 토글 → 최종 unliked")
    }

    @Test("addComment — 빈 본문 invalidInput / 500자 초과 invalidInput")
    func addCommentValidation() async throws {
        let repo = MockFeedRepository()
        let usecase = AddCommentUseCaseImpl(repository: repo)

        await #expect(throws: MMDomainError.self) {
            _ = try await usecase(uid: "uid_self", targetType: .review, targetId: "rev_3", body: "   ")
        }
        let long = String(repeating: "x", count: 501)
        await #expect(throws: MMDomainError.self) {
            _ = try await usecase(uid: "uid_self", targetType: .review, targetId: "rev_3", body: long)
        }
    }

    @Test("addComment — 정상 케이스 trimming + 응답에 작성자 매핑")
    func addCommentSuccess() async throws {
        let repo = MockFeedRepository()
        let usecase = AddCommentUseCaseImpl(repository: repo)
        let comment = try await usecase(
            uid: "uid_self",
            targetType: .review,
            targetId: "rev_4",
            body: "  잘 다녀왔어요!  "
        )
        #expect(comment.body == "잘 다녀왔어요!")
        #expect(comment.uid == "uid_self")
    }
}
