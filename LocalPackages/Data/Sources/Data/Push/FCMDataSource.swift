import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import UIKit
import UserNotifications
import Domain

/// FCM 토큰 + Firestore subcollection 등록을 책임지는 PushTokenRepository 구현.
/// schema.md §1A.6 정합 — 디바이스 식별자는 identifierForVendor.
public final class FCMDataSource: PushTokenRepository, @unchecked Sendable {

    private let auth: Auth
    private let firestore: FirestoreClient
    private let messaging: Messaging

    public init(
        auth: Auth = Auth.auth(),
        firestore: FirestoreClient,
        messaging: Messaging = Messaging.messaging()
    ) {
        self.auth = auth
        self.firestore = firestore
        self.messaging = messaging
    }

    public func currentPermission() async -> PushPermission {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let status: PushPermission.Status
        switch settings.authorizationStatus {
        case .authorized: status = .granted
        case .provisional: status = .provisional
        case .denied: status = .denied
        case .notDetermined: status = .notDetermined
        case .ephemeral: status = .granted
        @unknown default: status = .notDetermined
        }
        return PushPermission(
            status: status,
            soundEnabled: settings.soundSetting == .enabled,
            alertEnabled: settings.alertSetting == .enabled,
            badgeEnabled: settings.badgeSetting == .enabled
        )
    }

    public func registerToken(_ token: String, permission: PushPermission) async throws {
        guard permission.canDeliver else {
            throw MMDomainError.permissionDenied
        }
        guard let uid = auth.currentUser?.uid else { throw MMDomainError.unauthorized }
        let deviceId = await MainActor.run { UIDevice.current.identifierForVendor?.uuidString } ?? UUID().uuidString
        let payload: [String: Any] = [
            "tokenId": deviceId,
            "uid": uid,
            "token": token,
            "platform": "ios",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0",
            "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "000000_0000",
            "locale": Locale.current.identifier,
            "pushPermission": permission.status.rawValue,
            "lastSeenAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "createdAt": FieldValue.serverTimestamp()
        ]

        try await firestore.firestore
            .collection("users").document(uid)
            .collection("fcmTokens").document(deviceId)
            .setData(payload, merge: true)
    }

    public func unregisterCurrentDevice() async throws {
        guard let uid = auth.currentUser?.uid else { return }
        let deviceId = await MainActor.run { UIDevice.current.identifierForVendor?.uuidString }
        guard let deviceId else { return }
        try await firestore.firestore
            .collection("users").document(uid)
            .collection("fcmTokens").document(deviceId)
            .delete()
    }
}
