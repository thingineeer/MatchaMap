import Foundation

/// ADR-304 — 앱 전역 인증 상태.
/// `loading`: 부팅 직후 Firebase Auth 상태 확인 중.
/// `guest(anonymousUid:)`: Firebase Anonymous Auth로 발급된 UID. nil이면 익명 미발급(오프라인/실패).
/// `authenticated(AppUser)`: Apple/Passkey로 정식 인증된 사용자.
public enum AuthState: Sendable, Equatable {
    case loading
    case guest(anonymousUid: String?)
    case authenticated(AppUser)

    /// 게스트 익명 UID 또는 정식 사용자 UID.
    public var uid: String? {
        switch self {
        case .loading: return nil
        case .guest(let uid): return uid
        case .authenticated(let user): return user.uid
        }
    }

    /// Apple/Passkey로 정식 인증된 상태.
    public var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }

    /// 게스트(익명 또는 미인증) 상태.
    public var isGuest: Bool {
        if case .guest = self { return true }
        return false
    }

    /// 부팅 중.
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var authenticatedUser: AppUser? {
        if case .authenticated(let user) = self { return user }
        return nil
    }
}
