import Foundation

/// 매장 메뉴 카테고리. v1.0.0은 client-side enum. v1.x.x에서 stores.menu 서브컬렉션 시 free string 허용.
public enum MenuCategory: String, Sendable, Codable, CaseIterable {
    case usucha       // 우스차
    case koicha       // 코이차
    case latte        // 라떼
    case iced         // 아이스
    case dessert      // 디저트
    case other
}

/// 메뉴 아이템 — schema.md 미정의 (v1.0.0 비범위). 클라이언트 placeholder + 향후 stores.menu 서브컬렉션으로 확장.
/// 시안 화면 7 메뉴 탭 필요 — Phase 3는 매장 상세에 hardcoded sample 또는 Cloud Functions endpoint.
public struct MenuItem: Sendable, Hashable, Identifiable, Codable {
    public let id: String
    public let category: MenuCategory
    public let name: String
    public let priceCents: Int           // 통화 단위 cents/원/엔. UI에서 currencyCode + locale로 포매팅.
    public let currencyCode: String      // ISO-4217 e.g. "KRW", "JPY"
    public let photoURL: URL?
    public let description: String?

    public init(
        id: String,
        category: MenuCategory,
        name: String,
        priceCents: Int,
        currencyCode: String,
        photoURL: URL? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.priceCents = priceCents
        self.currencyCode = currencyCode
        self.photoURL = photoURL
        self.description = description
    }
}
