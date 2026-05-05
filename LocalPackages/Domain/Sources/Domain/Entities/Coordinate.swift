import Foundation

public struct Coordinate: Sendable, Hashable, Codable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct BoundingBox: Sendable, Hashable, Codable {
    public let southWest: Coordinate
    public let northEast: Coordinate

    public init(southWest: Coordinate, northEast: Coordinate) {
        self.southWest = southWest
        self.northEast = northEast
    }

    /// 점이 박스 내부 또는 경계에 있는지 판정.
    /// 본 구현은 antimeridian(±180° 경도 wrap) 케이스를 다루지 않음 — Phase 4 viewport 쿼리에서 별도 검증.
    public func contains(_ point: Coordinate) -> Bool {
        let latOK = (southWest.latitude...northEast.latitude).contains(point.latitude)
        let lonOK = (southWest.longitude...northEast.longitude).contains(point.longitude)
        return latOK && lonOK
    }
}
