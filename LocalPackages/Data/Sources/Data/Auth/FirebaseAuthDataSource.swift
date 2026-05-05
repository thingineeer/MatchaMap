import Foundation
import FirebaseAuth
import FirebaseFirestore
import Domain

/// Firebase Auth 기반 AuthRepository 구현.
/// Apple OAuthCredential 교환 + Passkey assertion 처리.
/// schema.md §1 users doc 생성/업데이트는 Functions onCreate 트리거 책임 (클라 직접 write 안 함).
public final class FirebaseAuthDataSource: AuthRepository, @unchecked Sendable {

    private let auth: Auth
    private let firestore: FirestoreClient

    public init(auth: Auth = Auth.auth(), firestore: FirestoreClient) {
        self.auth = auth
        self.firestore = firestore
    }

    public func currentUser() async -> AppUser? {
        guard let user = auth.currentUser else { return nil }
        return try? await fetchAppUser(uid: user.uid)
    }

    public func authStateUpdates() -> AsyncStream<AppUser?> {
        AsyncStream { continuation in
            Task { @MainActor [weak self] in
                guard let self else { return }
                nonisolated(unsafe) let handle = self.auth.addStateDidChangeListener { _, user in
                    if let user {
                        Task {
                            let mapped = try? await self.fetchAppUser(uid: user.uid)
                            continuation.yield(mapped)
                        }
                    } else {
                        continuation.yield(nil)
                    }
                }
                continuation.onTermination = { @Sendable [auth = self.auth] _ in
                    auth.removeStateDidChangeListener(handle)
                }
            }
        }
    }

    public func signInWithApple(
        identityToken: Foundation.Data,
        nonce: String,
        fullName: PersonName?
    ) async throws -> AppUser {
        guard let idTokenString = String(data: identityToken, encoding: .utf8) else {
            throw MMDomainError.invalidInput("Apple identityToken decode 실패")
        }
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: nil  // PersonNameComponents는 server-functions onCreate가 displayName 합성.
        )
        let result = try await auth.signIn(with: credential)
        return try await fetchAppUser(uid: result.user.uid)
    }

    public func signInWithPasskey(_ assertion: PasskeyAssertion) async throws -> AppUser {
        // Phase 4 — Functions의 customToken exchange 콜러블 통해 처리.
        throw MMDomainError.unknown("signInWithPasskey: Phase 4 customToken flow 미구현")
    }

    public func registerPasskey(_ registration: PasskeyRegistration) async throws -> AppUser {
        throw MMDomainError.unknown("registerPasskey: Phase 4 customToken flow 미구현")
    }

    public func signOut() async throws {
        try auth.signOut()
    }

    public func deleteAccount() async throws {
        guard let user = auth.currentUser else { throw MMDomainError.unauthorized }
        // Functions의 deleteAccount 콜러블이 Firestore soft-delete + 30일 후 hard delete 트리거.
        try await user.delete()
    }

    // MARK: - Private

    /// Firestore users/{uid} 문서를 AppUser로 매핑.
    private func fetchAppUser(uid: String) async throws -> AppUser {
        let doc = try await firestore.firestore.collection("users").document(uid).getDocument()
        guard doc.exists, let data = doc.data() else {
            throw MMDomainError.notFound
        }
        return try AppUserMapper.map(uid: uid, data: data)
    }
}

/// schema.md §1 users 디코더.
enum AppUserMapper {
    static func map(uid: String, data: [String: Any]) throws -> AppUser {
        guard
            let displayName = data["displayName"] as? String,
            let locale = data["locale"] as? String,
            let homeRaw = data["homeCountry"] as? String,
            let homeCountry = Country(rawValue: homeRaw),
            let authMethodRaw = data["authMethod"] as? String,
            let authMethod = AuthMethod(rawValue: authMethodRaw),
            let cohortTimestamp = data["cohortD0"] as? Timestamp,
            let createdTimestamp = data["createdAt"] as? Timestamp,
            let updatedTimestamp = data["updatedAt"] as? Timestamp
        else {
            throw MMDomainError.unknown("users/{uid} 필드 누락 또는 타입 불일치")
        }
        let country = (data["country"] as? String).flatMap { Country(rawValue: $0) }
        let photoURL = (data["photoURL"] as? String).flatMap(URL.init(string:))
        let stats = (data["stats"] as? [String: Any]).map(UserStatsMapper.map(data:)) ?? .zero

        return AppUser(
            uid: uid,
            displayName: displayName,
            photoURL: photoURL,
            locale: locale,
            homeCountry: homeCountry,
            country: country,
            cohortD0: cohortTimestamp.dateValue(),
            authMethod: authMethod,
            stats: stats,
            createdAt: createdTimestamp.dateValue(),
            updatedAt: updatedTimestamp.dateValue()
        )
    }
}

enum UserStatsMapper {
    static func map(data: [String: Any]) -> UserStats {
        UserStats(
            collectionCount: (data["collectionCount"] as? Int) ?? 0,
            reviewCount: (data["reviewCount"] as? Int) ?? 0,
            wishlistCount: (data["wishlistCount"] as? Int) ?? 0,
            friendCount: (data["friendCount"] as? Int) ?? 0
        )
    }
}
