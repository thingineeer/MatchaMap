import Foundation

/// FCM 토큰 등록 + 푸시 권한 상태 조회.
/// schema.md §1A `users/{uid}/fcmTokens` 셀프 register 정합.
public protocol PushTokenRepository: Sendable {
    /// 현재 푸시 권한 상태(시스템 + 사용자 토글).
    func currentPermission() async -> PushPermission

    /// FCM 토큰을 schema.md §1A에 따라 upsert.
    /// - Parameters:
    ///   - token: FCM token string.
    ///   - permission: 호출 시점 권한 상태(`granted` 또는 `provisional`만 통과시켜야 함).
    func registerToken(_ token: String, permission: PushPermission) async throws

    /// 로그아웃/디바이스 분리 시 본인 토큰 doc 삭제.
    func unregisterCurrentDevice() async throws
}
