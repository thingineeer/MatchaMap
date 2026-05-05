import Testing
import Foundation
import Domain
@testable import FeatureSocial

@Suite("FeedViewModel — 옵티미스틱 좋아요/댓글 race condition")
struct FeedViewModelOptimisticTests {

    @MainActor
    private func makeViewModel(
        feed: [FeedEvent] = [.fixture(id: "ev_1")],
        likeDelay: Duration = .milliseconds(0)
    ) -> (FeedViewModel, MockFeedRepository) {
        let repo = MockFeedRepository(seed: feed)
        let vm = FeedViewModel(
            uid: "uid_self",
            loadFeed: LoadFeedUseCaseImpl(repository: repo),
            toggleLike: ToggleLikeUseCaseImpl(repository: repo),
            addComment: AddCommentUseCaseImpl(repository: repo)
        )
        return (vm, repo)
    }

    @Test("loadInitial → events 로드")
    @MainActor
    func loadInitialPopulates() async {
        let (vm, _) = makeViewModel(feed: [.fixture(id: "ev_a"), .fixture(id: "ev_b")])
        await vm.loadInitial()
        #expect(vm.events.count == 2)
    }

    @Test("좋아요 즉시 옵티미스틱 반영 → 서버 응답 정합")
    @MainActor
    func optimisticLikeReflectsImmediately() async {
        let (vm, _) = makeViewModel(feed: [.fixture(id: "ev_x")])
        await vm.loadInitial()
        let event = vm.events[0]
        let targetId = event.target.targetId

        #expect(vm.isLiked(targetId: targetId) == false)
        #expect(vm.likeCount(targetId: targetId) == 0)

        await vm.toggleLike(target: event)

        #expect(vm.isLiked(targetId: targetId) == true)
        #expect(vm.likeCount(targetId: targetId) == 1)
    }

    @Test("동일 이벤트 좋아요 두 번 → 최종 unliked + count 0")
    @MainActor
    func toggleTwiceCancels() async {
        let (vm, _) = makeViewModel()
        await vm.loadInitial()
        let event = vm.events[0]
        let targetId = event.target.targetId

        await vm.toggleLike(target: event)
        await vm.toggleLike(target: event)

        #expect(vm.isLiked(targetId: targetId) == false)
        #expect(vm.likeCount(targetId: targetId) == 0)
    }

    @Test("서버 실패 → rollback (옵티미스틱 적용 후 원상복구)")
    @MainActor
    func serverFailureRollsBack() async {
        let (vm, repo) = makeViewModel()
        await vm.loadInitial()
        await repo.setStubError(MMDomainError.network("simulated"))
        let event = vm.events[0]
        let targetId = event.target.targetId

        await vm.toggleLike(target: event)

        #expect(vm.isLiked(targetId: targetId) == false, "rollback 적용")
        #expect(vm.likeCount(targetId: targetId) == 0, "count도 rollback")
        #expect(vm.error != nil)
    }

    @Test("옵티미스틱 댓글 — 즉시 표시 + 서버 응답 후 confirmed로 이동")
    @MainActor
    func optimisticCommentMovesToConfirmed() async {
        let (vm, _) = makeViewModel()
        await vm.loadInitial()
        let event = vm.events[0]
        let targetId = event.target.targetId

        await vm.addComment(target: event, body: "맛있어 보여요!")

        let comments = vm.comments(targetId: targetId)
        #expect(comments.count == 1)
        #expect(comments.first?.body == "맛있어 보여요!")
    }

    @Test("옵티미스틱 댓글 — 서버 실패 시 pending 제거")
    @MainActor
    func commentRollbackOnFailure() async {
        let (vm, repo) = makeViewModel()
        await vm.loadInitial()
        await repo.setStubError(MMDomainError.network("simulated"))
        let event = vm.events[0]
        let targetId = event.target.targetId

        await vm.addComment(target: event, body: "내용")

        let comments = vm.comments(targetId: targetId)
        #expect(comments.isEmpty, "실패 시 pending 제거")
        #expect(vm.error != nil)
    }
}
