import Foundation

/// Apple Sign In + Passkey 양쪽 흐름을 추상화하는 Auth Repository.
/// `Data` 모듈의 `FirebaseAuthDataSource`가 본 프로토콜을 구현.
public protocol AuthRepository: Sendable {
    /// 현재 인증된 사용자. 미인증이면 nil.
    func currentUser() async -> AppUser?

    /// 인증 상태 변화 스트림. 로그인/로그아웃 시 emit.
    func authStateUpdates() -> AsyncStream<AppUser?>

    /// Apple OAuth credential을 받아 Firebase Auth로 교환.
    /// - Parameters:
    ///   - identityToken: Apple ID provider의 identityToken (Data).
    ///   - nonce: 클라가 생성한 SHA256 raw nonce (Apple 요청 시 hashed로 보낸 원본).
    ///   - fullName: 첫 로그인 시 Apple이 1회 제공. 이후 로그인은 nil.
    func signInWithApple(
        identityToken: Data,
        nonce: String,
        fullName: PersonName?
    ) async throws -> AppUser

    /// Passkey assertion으로 로그인.
    func signInWithPasskey(_ assertion: PasskeyAssertion) async throws -> AppUser

    /// Passkey 신규 등록.
    func registerPasskey(_ registration: PasskeyRegistration) async throws -> AppUser

    /// 현재 세션 종료.
    func signOut() async throws

    /// 계정 삭제 (Firestore soft-delete + Auth 삭제 트리거).
    func deleteAccount() async throws
}
