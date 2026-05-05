import Foundation

/// `stores.origin.region` enum 8종 + extra lookup → {lat, lng} 매핑.
/// ADR-302 v1.1 designer-lead Q1 합의: server.coords 신설 ❌ → 디자인 시스템 hardcoded.
/// designer-lead 책임으로 정전 픽셀 검증된 좌표(우지/니시오/시즈오카/카고시마/보성/하동/제주). other/unknown은 nil.
public struct GeoCoord: Sendable, Hashable, Codable {
    public let latitude: Double
    public let longitude: Double
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public enum MatchaOriginCoords {
    /// region rawValue (`uji`/`nishio`/`shizuoka`/`kagoshima`/`boseong`/`hadong`/`jeju`/`other`/`unknown`) → 좌표.
    /// other/unknown은 nil → 미니 세계지도에서 표시 안 함 (designer-lead C2 §6.3 정합).
    public static func coord(for region: String?) -> GeoCoord? {
        guard let region = region?.lowercased() else { return nil }
        return table[region]
    }

    private static let table: [String: GeoCoord] = [
        "uji":       GeoCoord(latitude: 34.8844, longitude: 135.7997),  // 京都府 宇治市
        "nishio":    GeoCoord(latitude: 34.8616, longitude: 137.0590),  // 愛知県 西尾市
        "shizuoka":  GeoCoord(latitude: 34.9756, longitude: 138.3828),  // 静岡県
        "kagoshima": GeoCoord(latitude: 31.5969, longitude: 130.5571),  // 鹿児島県
        "boseong":   GeoCoord(latitude: 34.7714, longitude: 127.0800),  // 보성군
        "hadong":    GeoCoord(latitude: 35.0672, longitude: 127.7510),  // 하동군
        "jeju":      GeoCoord(latitude: 33.4996, longitude: 126.5312)   // 제주
    ]

    /// 미니 세계지도(390pt × 약 200pt) 안에서 정규화된 (x, y) 위치.
    /// 등거리 원통(equirectangular) 투영: lng [-180, 180] → x [0, 1], lat [85, -85] → y [0, 1].
    public static func normalizedPosition(for coord: GeoCoord) -> CGPoint {
        let x = (coord.longitude + 180) / 360
        let yLatClamped = max(-85, min(85, coord.latitude))
        let y = (85 - yLatClamped) / 170
        return CGPoint(x: x, y: y)
    }
}
