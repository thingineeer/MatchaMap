import Foundation

// MARK: - Fixtures

public extension StoreSnapshot {
    static func fixture(
        placeId: String = "ChIJ_FIX_1",
        name: String = "마차하우스",
        city: String = "Seoul",
        countryCode: String = "KR"
    ) -> StoreSnapshot {
        StoreSnapshot(
            placeId: placeId,
            name: name,
            city: city,
            countryCode: countryCode,
            primaryPhotoURL: nil
        )
    }
}

public extension CollectionItem {
    static func fixture(
        id: String = "01J_ITEM_1",
        uid: String = "uid_self",
        storeId: String = "ChIJ_FIX_1",
        drink: Drink = .usucha,
        grade: Grade? = .ceremonial,
        originRegion: OriginRegion? = .uji,
        colorTier: ColorTier? = .deepMatcha,
        countryCode: String = "KR",
        viaReview: Bool = false,
        visitedAt: Date = Date(timeIntervalSince1970: 1_730_000_000),
        createdAt: Date = Date(timeIntervalSince1970: 1_730_000_000)
    ) -> CollectionItem {
        CollectionItem(
            id: id,
            uid: uid,
            storeId: storeId,
            drink: drink,
            grade: grade,
            originRegion: originRegion,
            colorTier: colorTier,
            colorHex: nil,
            note: nil,
            photoURLs: [],
            countryCode: countryCode,
            store: .fixture(placeId: storeId, countryCode: countryCode),
            viaReview: viaReview,
            visitedAt: visitedAt,
            createdAt: createdAt
        )
    }
}

public extension WishlistItem {
    static func fixture(
        storeId: String = "ChIJ_FIX_1",
        uid: String = "uid_self",
        countryCode: String = "JP",
        addedAt: Date = Date(timeIntervalSince1970: 1_730_000_000)
    ) -> WishlistItem {
        WishlistItem(
            storeId: storeId,
            uid: uid,
            countryCode: countryCode,
            store: .fixture(placeId: storeId, countryCode: countryCode),
            note: nil,
            addedAt: addedAt
        )
    }
}

public extension Friendship {
    static func fixture(
        uid: String = "uid_self",
        friendUid: String = "uid_friend_1",
        status: Status = .accepted,
        addMethod: AddMethod = .qr,
        requestedAt: Date = Date(timeIntervalSince1970: 1_730_000_000)
    ) -> Friendship {
        Friendship(
            uid: uid,
            friendUid: friendUid,
            status: status,
            friend: FriendUser(uid: friendUid, displayName: "Matcha Friend"),
            addMethod: addMethod,
            requestedAt: requestedAt,
            acceptedAt: status == .accepted ? requestedAt : nil
        )
    }
}

public extension FeedEvent {
    static func fixture(
        id: String = "01J_FE_1",
        actorUid: String = "uid_friend_1",
        type: EventType = .collection,
        createdAt: Date = Date(timeIntervalSince1970: 1_730_000_000)
    ) -> FeedEvent {
        FeedEvent(
            id: id,
            actorUid: actorUid,
            actor: FriendUser(uid: actorUid, displayName: "Matcha Friend"),
            type: type,
            target: .collectionItem(itemId: "01J_ITEM_X", store: .fixture()),
            payload: .collection(drink: .usucha, grade: .ceremonial, colorHex: "#7A9560"),
            countryCode: "KR",
            visibility: .friends,
            audienceUidsCount: 12,
            createdAt: createdAt
        )
    }
}

public extension UserProfile {
    static func fixture(
        uid: String = "uid_self",
        stats: UserStats = UserStats(collectionCount: 24, reviewCount: 8, wishlistCount: 12, friendCount: 5)
    ) -> UserProfile {
        UserProfile(
            uid: uid,
            displayName: "MatchaLover",
            photoURL: nil,
            countryCode: "KR",
            homeCountryCode: "KR",
            stats: stats,
            cohortD0: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}

// MARK: - In-memory mocks (옵티미스틱 검증, race-condition 시뮬용)

/// 인메모리 컬렉션 저장소 — 테스트/Preview용. add/remove/update 모두 actor 격리.
public actor MockCollectionRepository: CollectionRepository {
    public private(set) var items: [String: [CollectionItem]] = [:]   // uid → list
    public var stubError: Error?
    public var addDelay: Duration = .milliseconds(0)
    public private(set) var addCallCount: Int = 0

    public init(initial: [String: [CollectionItem]] = [:]) {
        self.items = initial
    }

    public func setStubError(_ error: Error?) { self.stubError = error }
    public func setAddDelay(_ duration: Duration) { self.addDelay = duration }

    public func items(uid: String, cursor: PaginationCursor?, limit: Int) async throws -> Page<CollectionItem> {
        if let stubError { throw stubError }
        let all = items[uid] ?? []
        return Page(items: Array(all.prefix(limit)), nextCursor: nil)
    }

    public func item(uid: String, itemId: String) async throws -> CollectionItem {
        if let stubError { throw stubError }
        guard let found = items[uid]?.first(where: { $0.id == itemId }) else {
            throw MMDomainError.notFound
        }
        return found
    }

    public func add(_ draft: CollectionItemDraft) async throws -> AddCollectionItemResult {
        if addDelay > .zero { try? await Task.sleep(for: addDelay) }
        if let stubError { throw stubError }
        addCallCount += 1
        let uid = "uid_self"
        let id = "ITEM_\(addCallCount)"
        let now = Date()
        let store = StoreSnapshot.fixture(placeId: draft.storeId)
        let item = CollectionItem(
            id: id,
            uid: uid,
            storeId: draft.storeId,
            drink: draft.drink,
            grade: draft.grade,
            originRegion: draft.originRegion,
            colorTier: draft.colorTier,
            colorHex: nil,
            note: draft.note,
            photoURLs: draft.photoURLs,
            countryCode: store.countryCode,
            store: store,
            viaReview: draft.viaReview,
            linkedReviewId: draft.linkedReviewId,
            visitedAt: draft.visitedAt ?? now,
            createdAt: now
        )
        items[uid, default: []].insert(item, at: 0)
        return AddCollectionItemResult(itemId: id, collectionCount: items[uid]?.count ?? 1)
    }

    public func update(uid: String, itemId: String, patch: CollectionItemPatch) async throws {
        if let stubError { throw stubError }
        guard var list = items[uid], let idx = list.firstIndex(where: { $0.id == itemId }) else {
            throw MMDomainError.notFound
        }
        let original = list[idx]
        let updated = CollectionItem(
            id: original.id,
            uid: original.uid,
            storeId: original.storeId,
            drink: original.drink,
            grade: patch.grade ?? original.grade,
            originRegion: patch.originRegion ?? original.originRegion,
            colorTier: patch.colorTier ?? original.colorTier,
            colorHex: original.colorHex,
            note: patch.note ?? original.note,
            photoURLs: patch.photoURLs ?? original.photoURLs,
            countryCode: original.countryCode,
            store: original.store,
            viaReview: original.viaReview,
            linkedReviewId: original.linkedReviewId,
            visitedAt: original.visitedAt,
            createdAt: original.createdAt
        )
        list[idx] = updated
        items[uid] = list
    }

    public func remove(uid: String, itemId: String) async throws {
        if let stubError { throw stubError }
        items[uid]?.removeAll { $0.id == itemId }
    }
}

/// 인메모리 위시리스트 — toggle idempotent 검증용.
public actor MockWishlistRepository: WishlistRepository {
    public private(set) var stored: [String: [String: WishlistItem]] = [:]   // uid → storeId → item
    public var stubError: Error?
    public var toggleDelay: Duration = .milliseconds(0)
    public private(set) var toggleCallCount: Int = 0

    public init() {}

    public func setStubError(_ error: Error?) { self.stubError = error }
    public func setToggleDelay(_ duration: Duration) { self.toggleDelay = duration }

    public func items(uid: String, cursor: PaginationCursor?, limit: Int) async throws -> Page<WishlistItem> {
        if let stubError { throw stubError }
        let list = Array((stored[uid] ?? [:]).values).sorted { $0.addedAt > $1.addedAt }
        return Page(items: Array(list.prefix(limit)), nextCursor: nil)
    }

    public func contains(uid: String, storeId: String) async throws -> Bool {
        stored[uid]?[storeId] != nil
    }

    @discardableResult
    public func toggle(uid: String, store: StoreSnapshot, note: String?) async throws -> Bool {
        if toggleDelay > .zero { try? await Task.sleep(for: toggleDelay) }
        if let stubError { throw stubError }
        toggleCallCount += 1
        var byStore = stored[uid] ?? [:]
        if byStore[store.placeId] != nil {
            byStore.removeValue(forKey: store.placeId)
            stored[uid] = byStore
            return false
        } else {
            let item = WishlistItem(
                storeId: store.placeId,
                uid: uid,
                countryCode: store.countryCode,
                store: store,
                note: note,
                addedAt: Date()
            )
            byStore[store.placeId] = item
            stored[uid] = byStore
            return true
        }
    }

    public func updateNote(uid: String, storeId: String, note: String?) async throws {
        if let stubError { throw stubError }
        guard let existing = stored[uid]?[storeId] else { throw MMDomainError.notFound }
        let next = WishlistItem(
            storeId: existing.storeId,
            uid: existing.uid,
            countryCode: existing.countryCode,
            store: existing.store,
            note: note,
            addedAt: existing.addedAt
        )
        stored[uid]?[storeId] = next
    }
}

/// 인메모리 피드 + 좋아요 토글 — 옵티미스틱 race condition 검증용.
public actor MockFeedRepository: FeedRepository {
    public private(set) var feed: [FeedEvent] = []
    public private(set) var likes: [String: Set<String>] = [:]   // targetId → likedBy uids
    public private(set) var comments: [String: [Comment]] = [:]  // targetId → list
    public var likeDelay: Duration = .milliseconds(0)
    public var stubError: Error?
    public private(set) var toggleLikeCallCount: Int = 0

    public init(seed: [FeedEvent] = []) { self.feed = seed }

    public func setStubError(_ error: Error?) { self.stubError = error }
    public func setLikeDelay(_ duration: Duration) { self.likeDelay = duration }

    public func myFeed(uid: String, cursor: PaginationCursor?, limit: Int) async throws -> Page<FeedEvent> {
        if let stubError { throw stubError }
        return Page(items: Array(feed.prefix(limit)), nextCursor: nil)
    }

    @discardableResult
    public func toggleLike(targetType: FeedEvent.EventType, targetId: String, uid: String) async throws -> Bool {
        if likeDelay > .zero { try? await Task.sleep(for: likeDelay) }
        if let stubError { throw stubError }
        toggleLikeCallCount += 1
        var set = likes[targetId] ?? []
        if set.contains(uid) {
            set.remove(uid)
            likes[targetId] = set
            return false
        } else {
            set.insert(uid)
            likes[targetId] = set
            return true
        }
    }

    public func addComment(targetType: FeedEvent.EventType, targetId: String, uid: String, body: String) async throws -> Comment {
        if let stubError { throw stubError }
        let comment = Comment(
            id: "C_\((comments[targetId]?.count ?? 0) + 1)",
            uid: uid,
            author: FriendUser(uid: uid, displayName: "Me"),
            body: body,
            createdAt: Date()
        )
        comments[targetId, default: []].append(comment)
        return comment
    }

    public func comments(targetType: FeedEvent.EventType, targetId: String, cursor: PaginationCursor?, limit: Int) async throws -> Page<Comment> {
        let list = comments[targetId] ?? []
        return Page(items: Array(list.prefix(limit)), nextCursor: nil)
    }

    public func likedBy(targetId: String) -> Set<String> { likes[targetId] ?? [] }
}

/// 인메모리 사용자 프로필 저장소 — MVP/Preview용.
public actor MockUserRepository: UserRepository {
    public private(set) var profiles: [String: UserProfile] = [:]
    public var stubError: Error?

    public init(initial: [String: UserProfile] = [:]) {
        self.profiles = initial
    }

    public func setStubError(_ error: Error?) { self.stubError = error }
    public func upsert(_ profile: UserProfile) { profiles[profile.uid] = profile }

    public func profile(uid: String) async throws -> UserProfile {
        if let stubError { throw stubError }
        if let p = profiles[uid] { return p }
        return UserProfile.fixture(uid: uid)
    }
}

/// 인메모리 친구 그래프 — 양방향 정합 검증용.
public actor MockFriendshipRepository: FriendshipRepository {
    public private(set) var edges: [String: [String: Friendship]] = [:]  // uid → friendUid → edge
    public var stubError: Error?
    public private(set) var requestCallCount: Int = 0

    public init() {}

    public func setStubError(_ error: Error?) { self.stubError = error }

    public func acceptedFriends(uid: String, cursor: PaginationCursor?, limit: Int) async throws -> Page<Friendship> {
        if let stubError { throw stubError }
        let list = (edges[uid] ?? [:]).values.filter { $0.status == .accepted }
            .sorted { ($0.acceptedAt ?? $0.requestedAt) > ($1.acceptedAt ?? $1.requestedAt) }
        return Page(items: Array(list.prefix(limit)), nextCursor: nil)
    }

    public func incomingRequests(uid: String) async throws -> [Friendship] {
        let list = (edges[uid] ?? [:]).values.filter { $0.status == .pendingIncoming }
            .sorted { $0.requestedAt > $1.requestedAt }
        return Array(list)
    }

    public func request(targetUid: String, addMethod: Friendship.AddMethod) async throws {
        if let stubError { throw stubError }
        requestCallCount += 1
        let me = "uid_self"
        let now = Date()
        // 양방향 두 doc 정합 (Functions 시뮬)
        let outgoing = Friendship(
            uid: me, friendUid: targetUid, status: .pendingOutgoing,
            friend: FriendUser(uid: targetUid, displayName: "u_\(targetUid.suffix(4))"),
            addMethod: addMethod, requestedAt: now
        )
        let incoming = Friendship(
            uid: targetUid, friendUid: me, status: .pendingIncoming,
            friend: FriendUser(uid: me, displayName: "Me"),
            addMethod: addMethod, requestedAt: now
        )
        edges[me, default: [:]][targetUid] = outgoing
        edges[targetUid, default: [:]][me] = incoming
    }

    public func accept(requesterUid: String) async throws {
        if let stubError { throw stubError }
        let me = "uid_self"
        let now = Date()
        guard var mySide = edges[me]?[requesterUid], var otherSide = edges[requesterUid]?[me] else {
            throw MMDomainError.notFound
        }
        guard mySide.status == .pendingIncoming, otherSide.status == .pendingOutgoing else {
            throw MMDomainError.permissionDenied
        }
        mySide = Friendship(
            uid: mySide.uid, friendUid: mySide.friendUid, status: .accepted,
            friend: mySide.friend, addMethod: mySide.addMethod,
            requestedAt: mySide.requestedAt, acceptedAt: now
        )
        otherSide = Friendship(
            uid: otherSide.uid, friendUid: otherSide.friendUid, status: .accepted,
            friend: otherSide.friend, addMethod: otherSide.addMethod,
            requestedAt: otherSide.requestedAt, acceptedAt: now
        )
        edges[me]?[requesterUid] = mySide
        edges[requesterUid]?[me] = otherSide
    }

    public func remove(otherUid: String) async throws {
        if let stubError { throw stubError }
        let me = "uid_self"
        edges[me]?.removeValue(forKey: otherUid)
        edges[otherUid]?.removeValue(forKey: me)
    }

    /// 테스트 검증용 — 양방향 doc 일관성.
    public func bothSidesAccepted(_ a: String, _ b: String) -> Bool {
        edges[a]?[b]?.status == .accepted && edges[b]?[a]?.status == .accepted
    }

    public func edge(from uid: String, to friendUid: String) -> Friendship? {
        edges[uid]?[friendUid]
    }
}
