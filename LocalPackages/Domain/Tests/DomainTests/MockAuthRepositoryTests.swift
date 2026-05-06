import Testing
import Foundation
@testable import Domain

@Suite("MockAuthRepository — 익명 발급/링크 흐름")
struct MockAuthRepositoryTests {

    @Test("signInAnonymously → state == guest(anonymousUid:)")
    func signInAnonymouslyTransitions() async throws {
        let repo = MockAuthRepository(initialState: .loading)
        let uid = try await repo.signInAnonymously()
        let state = await repo.currentAuthState()
        #expect(uid == "anon-uid-mock")
        #expect(state.isGuest)
        #expect(state.uid == "anon-uid-mock")
    }

    @Test("linkAnonymousToApple → state == authenticated, linkCallCount == 1")
    func linkAnonymousToAppleTransitions() async throws {
        let repo = MockAuthRepository(initialState: .guest(anonymousUid: "anon-1"))
        _ = try await repo.linkAnonymousToApple(
            identityToken: Data(),
            nonce: "n",
            fullName: nil
        )
        let state = await repo.currentAuthState()
        let count = await repo.linkCallCount
        #expect(state.isAuthenticated)
        #expect(count == 1)
    }

    @Test("setStubbedError → 다음 호출에서 throw")
    func stubbedErrorThrows() async {
        let repo = MockAuthRepository()
        await repo.setStubbedError(.network("offline"))
        await #expect(throws: MMDomainError.self) {
            _ = try await repo.signInAnonymously()
        }
    }
}
