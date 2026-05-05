import Foundation

/// FCM 토큰 등록 가능 여부를 결정하는 푸시 권한 스냅샷.
/// schema.md §1A.2 `pushPermission` 필드 ↔ enum 정합.
public struct PushPermission: Sendable, Hashable, Codable {
    public enum Status: String, Sendable, Codable, CaseIterable {
        case granted
        case provisional
        case denied
        case notDetermined = "not_determined"
    }

    public let status: Status
    public let soundEnabled: Bool
    public let alertEnabled: Bool
    public let badgeEnabled: Bool

    public init(status: Status, soundEnabled: Bool, alertEnabled: Bool, badgeEnabled: Bool) {
        self.status = status
        self.soundEnabled = soundEnabled
        self.alertEnabled = alertEnabled
        self.badgeEnabled = badgeEnabled
    }

    /// 사용자에게 알림을 실제로 보낼 수 있는 상태.
    public var canDeliver: Bool {
        status == .granted || status == .provisional
    }

    public static let notDetermined = PushPermission(
        status: .notDetermined,
        soundEnabled: false,
        alertEnabled: false,
        badgeEnabled: false
    )
}
