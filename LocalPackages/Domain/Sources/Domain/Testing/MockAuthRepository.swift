import Foundation

/// ADR-304 — Preview/Test용 인메모리 AuthRepository.
/// 게스트/정식/링크 흐름을 시뮬레이션. Sendable 유지를 위해 actor.
public actor MockAuthRepository: AuthRepository {

    public private(set) var state: AuthState
    public private(set) var anonymousCallCount: Int = 0
    public private(set) var linkCallCount: Int = 0
    public var stubbedAnonymousUid: String
    public var stubbedAppUser: AppUser
    public var stubbedError: MMDomainError?

    public init(
        initialState: AuthState = .guest(anonymousUid: nil),
        stubbedAnonymousUid: String = "anon-uid-mock",
        stubbedAppUser: AppUser = .fixture()
    ) {
        self.state = initialState
        self.stubbedAnonymousUid = stubbedAnonymousUid
        self.stubbedAppUser = stubbedAppUser
    }

    public func setState(_ state: AuthState) {
        self.state = state
    }

    public func setStubbedError(_ error: MMDomainError?) {
        self.stubbedError = error
    }

    // MARK: - AuthRepository

    public func currentUser() async -> AppUser? {
        if case .authenticated(let user) = state { return user }
        return nil
    }

    public func currentAuthState() async -> AuthState {
        state
    }

    nonisolated public func authStateUpdates() -> AsyncStream<AppUser?> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    public func signInWithApple(
        identityToken: Data,
        nonce: String,
        fullName: PersonName?
    ) async throws -> AppUser {
        if let stubbedError { throw stubbedError }
        state = .authenticated(stubbedAppUser)
        return stubbedAppUser
    }

    public func signInWithPasskey(_ assertion: PasskeyAssertion) async throws -> AppUser {
        if let stubbedError { throw stubbedError }
        state = .authenticated(stubbedAppUser)
        return stubbedAppUser
    }

    public func registerPasskey(_ registration: PasskeyRegistration) async throws -> AppUser {
        if let stubbedError { throw stubbedError }
        state = .authenticated(stubbedAppUser)
        return stubbedAppUser
    }

    public func signInAnonymously() async throws -> String {
        if let stubbedError { throw stubbedError }
        anonymousCallCount += 1
        state = .guest(anonymousUid: stubbedAnonymousUid)
        return stubbedAnonymousUid
    }

    public func linkAnonymousToApple(
        identityToken: Data,
        nonce: String,
        fullName: PersonName?
    ) async throws -> AppUser {
        if let stubbedError { throw stubbedError }
        linkCallCount += 1
        state = .authenticated(stubbedAppUser)
        return stubbedAppUser
    }

    public func signOut() async throws {
        if let stubbedError { throw stubbedError }
        state = .guest(anonymousUid: nil)
    }

    public func deleteAccount() async throws {
        if let stubbedError { throw stubbedError }
        state = .guest(anonymousUid: nil)
    }
}
