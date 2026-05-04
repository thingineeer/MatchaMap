import Foundation

/// 위시리스트 항목. schema.md §4 wishlists/{uid}/items/{storeId}.
/// doc.id == storeId → idempotent toggle.
public struct WishlistItem: Sendable, Hashable, Identifiable, Codable {
    public var id: String { storeId }
    public let storeId: String
    public let uid: String
    public let countryCode: String
    public let store: StoreSnapshot
    public let note: String?
    public let addedAt: Date

    public init(
        storeId: String,
        uid: String,
        countryCode: String,
        store: StoreSnapshot,
        note: String? = nil,
        addedAt: Date
    ) {
        self.storeId = storeId
        self.uid = uid
        self.countryCode = countryCode
        self.store = store
        self.note = note
        self.addedAt = addedAt
    }
}
