import Testing
import Foundation
@testable import Domain

@Suite("AuthState — ADR-304 게스트/정식 분기")
struct AuthStateTests {

    @Test("loading — uid nil, isAuthenticated/isGuest 모두 false")
    func loadingState() {
        let s = AuthState.loading
        #expect(s.uid == nil)
        #expect(!s.isAuthenticated)
        #expect(!s.isGuest)
        #expect(s.isLoading)
    }

    @Test("guest with uid — uid 노출, isGuest true")
    func guestWithUid() {
        let s = AuthState.guest(anonymousUid: "anon-xyz")
        #expect(s.uid == "anon-xyz")
        #expect(s.isGuest)
        #expect(!s.isAuthenticated)
    }

    @Test("guest without uid — uid nil, isGuest true")
    func guestNoUid() {
        let s = AuthState.guest(anonymousUid: nil)
        #expect(s.uid == nil)
        #expect(s.isGuest)
    }

    @Test("authenticated — uid는 AppUser.uid, isAuthenticated true")
    func authenticatedState() {
        let user = AppUser.fixture(uid: "user-42")
        let s = AuthState.authenticated(user)
        #expect(s.uid == "user-42")
        #expect(s.isAuthenticated)
        #expect(!s.isGuest)
        #expect(s.authenticatedUser?.uid == "user-42")
    }

    @Test("Equatable — 동일 case는 ==")
    func equatable() {
        #expect(AuthState.loading == .loading)
        #expect(AuthState.guest(anonymousUid: "a") == .guest(anonymousUid: "a"))
        #expect(AuthState.guest(anonymousUid: "a") != .guest(anonymousUid: "b"))
        let user = AppUser.fixture()
        #expect(AuthState.authenticated(user) == .authenticated(user))
    }
}

@Suite("MMDomainError — guestCapExceeded / anonymousForbidden")
struct GuestErrorTests {

    @Test("guestCapExceeded(.wishlist) Hashable")
    func capError() {
        let e = MMDomainError.guestCapExceeded(.wishlist)
        let f = MMDomainError.guestCapExceeded(.wishlist)
        #expect(e == f)
    }

    @Test("anonymousForbidden(.writeReview) Hashable")
    func anonymousError() {
        let e = MMDomainError.anonymousForbidden(.writeReview)
        let f = MMDomainError.anonymousForbidden(.writeReview)
        #expect(e == f)
    }
}
