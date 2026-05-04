import Foundation

/// schema.md §4 wishlists. doc.id == storeId → idempotent toggle.
public protocol WishlistRepository: Sendable {
    /// 전체 위시리스트 (국가별 그룹은 ViewModel이 처리).
    func items(uid: String, cursor: PaginationCursor?, limit: Int) async throws -> Page<WishlistItem>

    /// 특정 매장이 위시리스트에 있는지 — `wishlists/{uid}/items/{storeId}` 단건 조회.
    func contains(uid: String, storeId: String) async throws -> Bool

    /// 토글 — 추가 시 새 doc create, 제거 시 doc delete. idempotent.
    /// 반환: 토글 후 최종 상태(true=위시 등록됨, false=제거됨).
    @discardableResult
    func toggle(uid: String, store: StoreSnapshot, note: String?) async throws -> Bool

    /// 메모만 갱신.
    func updateNote(uid: String, storeId: String, note: String?) async throws
}
