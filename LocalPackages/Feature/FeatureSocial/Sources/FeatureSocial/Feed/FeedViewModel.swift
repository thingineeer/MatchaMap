import Foundation
import Domain
import Observation

/// Feed ViewModel — handoff-mapping §11.
/// 옵티미스틱 좋아요/댓글: tap 즉시 UI 반영, 서버 응답으로 확정.
/// 실패 시 rollback + error 토스트.
@MainActor
@Observable
public final class FeedViewModel {
    public private(set) var events: [FeedEvent] = []
    public private(set) var isLoading: Bool = false
    public private(set) var hasMore: Bool = true
    public private(set) var error: String?

    /// 좋아요 옵티미스틱 상태 — targetId → liked / count.
    /// 서버 fetch가 부재한 MVP: 클라가 이 dictionary를 SSOT로 사용.
    public private(set) var likedTargets: Set<String> = []
    public private(set) var likeCounts: [String: Int] = [:]

    /// 옵티미스틱 댓글 — 미확정(서버 응답 대기) 댓글 목록. 실패 시 제거.
    public private(set) var pendingComments: [String: [Comment]] = [:]   // targetId → [comment]
    public private(set) var confirmedComments: [String: [Comment]] = [:]

    private var cursor: PaginationCursor?
    private let uid: String
    private let loadFeed: any LoadFeedUseCase
    private let toggleLike: any ToggleLikeUseCase
    private let addComment: any AddCommentUseCase

    public init(
        uid: String,
        loadFeed: any LoadFeedUseCase,
        toggleLike: any ToggleLikeUseCase,
        addComment: any AddCommentUseCase
    ) {
        self.uid = uid
        self.loadFeed = loadFeed
        self.toggleLike = toggleLike
        self.addComment = addComment
    }

    public func loadInitial() async {
        guard events.isEmpty, !isLoading else { return }
        await fetchPage(reset: true)
    }

    public func refresh() async {
        cursor = nil
        hasMore = true
        await fetchPage(reset: true)
    }

    public func loadMoreIfNeeded(currentEvent: FeedEvent?) async {
        guard let currentEvent else { return }
        guard hasMore, !isLoading else { return }
        let triggerIdx = max(0, events.count - 5)
        guard let idx = events.firstIndex(of: currentEvent), idx >= triggerIdx else { return }
        await fetchPage(reset: false)
    }

    private func fetchPage(reset: Bool) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let page = try await loadFeed(uid: uid, cursor: reset ? nil : cursor, limit: 20)
            if reset { events = page.items }
            else { events.append(contentsOf: page.items) }
            cursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch {
            self.error = String(describing: error)
        }
    }

    // MARK: - Optimistic like

    public func isLiked(targetId: String) -> Bool {
        likedTargets.contains(targetId)
    }

    public func likeCount(targetId: String) -> Int {
        likeCounts[targetId] ?? 0
    }

    /// Optimistic toggle. 즉시 UI 반영 → 서버 호출 → 응답 정합 OR rollback.
    /// 동시에 같은 targetId에 대해 여러 번 tap을 받아도, latest 호출 결과를 적용.
    public func toggleLike(target: FeedEvent) async {
        let targetId = target.target.targetId
        let wasLiked = likedTargets.contains(targetId)
        let oldCount = likeCounts[targetId] ?? 0
        // 즉시 옵티미스틱 적용
        if wasLiked {
            likedTargets.remove(targetId)
            likeCounts[targetId] = max(0, oldCount - 1)
        } else {
            likedTargets.insert(targetId)
            likeCounts[targetId] = oldCount + 1
        }
        do {
            let confirmed = try await toggleLike(uid: uid, targetType: target.type, targetId: targetId)
            // 서버 응답이 옵티미스틱과 다르면 정합 맞춤.
            if confirmed != !wasLiked {
                if confirmed {
                    likedTargets.insert(targetId)
                } else {
                    likedTargets.remove(targetId)
                }
            }
        } catch {
            // rollback
            if wasLiked {
                likedTargets.insert(targetId)
            } else {
                likedTargets.remove(targetId)
            }
            likeCounts[targetId] = oldCount
            self.error = String(describing: error)
        }
    }

    // MARK: - Optimistic comment

    public func comments(targetId: String) -> [Comment] {
        (confirmedComments[targetId] ?? []) + (pendingComments[targetId] ?? [])
    }

    public func addComment(target: FeedEvent, body: String) async {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let targetId = target.target.targetId
        let tempId = "temp_\(UUID().uuidString)"
        let optimistic = Comment(
            id: tempId,
            uid: uid,
            author: FriendUser(uid: uid, displayName: "You"),
            body: trimmed,
            createdAt: Date()
        )
        pendingComments[targetId, default: []].append(optimistic)
        do {
            let confirmed = try await addComment(uid: uid, targetType: target.type, targetId: targetId, body: trimmed)
            // pending에서 temp 제거 + confirmed로 이동.
            pendingComments[targetId]?.removeAll { $0.id == tempId }
            confirmedComments[targetId, default: []].append(confirmed)
        } catch {
            // rollback (pending 제거)
            pendingComments[targetId]?.removeAll { $0.id == tempId }
            self.error = String(describing: error)
        }
    }
}

private extension FeedViewModel {
    func toggleLike(uid: String, targetType: FeedEvent.EventType, targetId: String) async throws -> Bool {
        try await toggleLike.callAsFunction(uid: uid, targetType: targetType, targetId: targetId)
    }

    func addComment(uid: String, targetType: FeedEvent.EventType, targetId: String, body: String) async throws -> Comment {
        try await addComment.callAsFunction(uid: uid, targetType: targetType, targetId: targetId, body: body)
    }
}
