import Foundation

public enum StoreGrade: String, Sendable, Codable, CaseIterable {
    case basic
    case premium
    case iconic

    /// 매장 매차스코어(0.0~5.0)에서 등급으로 매핑.
    /// 기준은 handoff-phase3-ios-map.md §4 합의 의제 — Phase 3에서 server-data와 최종 동기화.
    public static func from(matchaScore: Double) -> StoreGrade {
        switch matchaScore {
        case ..<3.5:        return .basic
        case 3.5..<4.5:     return .premium
        default:            return .iconic
        }
    }
}

/// 매장 핀 4등급 — schema.md §2.1 stores.pinTier (Functions derive). designer-icon MatchaPin S/A/B/C 정합.
public enum StorePinTier: String, Sendable, Codable, CaseIterable {
    case S
    case A
    case B
    case C
}

/// 말차 원산지 메타 — schema.md §2.1 stores.origin (po-lead 요청, designer-lead 정합).
public struct StoreOrigin: Sendable, Hashable, Codable {
    /// enum 권장 + free string 허용. mini-map 좌표는 DesignSystem hardcoded 매핑(ADR-302 v1.1 Q1).
    public let region: String?
    /// ISO-3166 alpha-2. 매장 country와 다를 수 있음.
    public let country: String?
    /// `ceremonial`, `premium`, `standard`, `culinary`.
    public let grade: String?
    /// 0–200 chars. 사용자 표시용 짧은 설명.
    public let notes: String?

    public init(region: String? = nil, country: String? = nil, grade: String? = nil, notes: String? = nil) {
        self.region = region
        self.country = country
        self.grade = grade
        self.notes = notes
    }
}

/// 영업시간 — schema.md §2.1 stores.openingHours.
public struct OpeningHours: Sendable, Hashable, Codable {
    public enum Weekday: String, Sendable, Codable, CaseIterable {
        case mon, tue, wed, thu, fri, sat, sun
    }

    public struct Slot: Sendable, Hashable, Codable {
        public let open: String   // "HH:mm"
        public let close: String  // "HH:mm"
        public init(open: String, close: String) {
            self.open = open
            self.close = close
        }
    }

    public let slots: [Weekday: [Slot]]

    public init(slots: [Weekday: [Slot]]) {
        self.slots = slots
    }

    /// 주어진 요일이 휴무인가? slots 배열이 비어 있으면 휴무 (schema §2.1).
    public func isClosed(on day: Weekday) -> Bool {
        (slots[day] ?? []).isEmpty
    }
}

public struct Store: Sendable, Hashable, Identifiable, Codable {
    public let id: String
    public let name: String
    public let location: Coordinate
    public let grade: StoreGrade
    public let matchaScore: Double
    public let countryCode: String      // ISO-3166 alpha-2
    public let city: String?
    public let address: String?
    public let photoURLs: [URL]
    public let primaryPhotoURL: URL?
    public let coverPhotoURL: URL?
    public let priceLevel: Int?         // 1~4 (Google Places 호환)
    public let openingHours: OpeningHours?
    public let pinTier: StorePinTier?
    public let origin: StoreOrigin?
    public let reviewCount: Int
    public let ratingAvg: Double
    public let ratingHistogram: [Int: Int] // key 1~5 → count
    public let tagsTop: [String]
    public let verified: Bool

    public init(
        id: String,
        name: String,
        location: Coordinate,
        grade: StoreGrade,
        matchaScore: Double,
        countryCode: String,
        city: String? = nil,
        address: String? = nil,
        photoURLs: [URL] = [],
        primaryPhotoURL: URL? = nil,
        coverPhotoURL: URL? = nil,
        priceLevel: Int? = nil,
        openingHours: OpeningHours? = nil,
        pinTier: StorePinTier? = nil,
        origin: StoreOrigin? = nil,
        reviewCount: Int = 0,
        ratingAvg: Double = 0.0,
        ratingHistogram: [Int: Int] = [:],
        tagsTop: [String] = [],
        verified: Bool = false
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.grade = grade
        self.matchaScore = matchaScore
        self.countryCode = countryCode
        self.city = city
        self.address = address
        self.photoURLs = photoURLs
        self.primaryPhotoURL = primaryPhotoURL
        self.coverPhotoURL = coverPhotoURL
        self.priceLevel = priceLevel
        self.openingHours = openingHours
        self.pinTier = pinTier
        self.origin = origin
        self.reviewCount = reviewCount
        self.ratingAvg = ratingAvg
        self.ratingHistogram = ratingHistogram
        self.tagsTop = tagsTop
        self.verified = verified
    }
}
