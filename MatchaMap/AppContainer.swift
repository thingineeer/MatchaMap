//
//  AppContainer.swift
//  MatchaMap
//
//  Composition Root의 의존성 컨테이너 — ADR-002 DI.
//  Repository factory closure + Firebase clients + 글로벌 AuthState (ADR-304) 보유.
//  Phase 4 통합 빌드에서 Feature ViewModel들이 본 컨테이너로부터 의존을 주입받음.

import Foundation
import Domain
import Observation

@MainActor
@Observable
final class AppContainer {

    /// ADR-304 — 앱 전역 인증 상태. RootView/Feature VM이 본 값을 관찰.
    var authState: AuthState = .loading

    /// 인증된 사용자 Repository — Firebase Auth + Apple/Passkey 어댑터.
    let authRepository: any AuthRepository

    /// 매장 Repository — Firestore 어댑터.
    let storeRepository: any StoreRepository

    /// 푸시 토큰 Repository — FCM + Firestore subcollection.
    let pushTokenRepository: any PushTokenRepository

    init(
        authRepository: any AuthRepository,
        storeRepository: any StoreRepository,
        pushTokenRepository: any PushTokenRepository
    ) {
        self.authRepository = authRepository
        self.storeRepository = storeRepository
        self.pushTokenRepository = pushTokenRepository
    }

    /// 부팅 — 현재 AuthState 동기화 + 익명 사용자 자동 발급.
    /// ADR-304: Firebase Console → Authentication → Anonymous 활성화 전제.
    func bootstrap() async {
        let initial = await authRepository.currentAuthState()
        authState = initial
        if case .guest(.none) = initial {
            // 첫 부팅 — 익명 UID 발급 시도. 실패해도 게스트(uid:nil)로 진행.
            do {
                let uid = try await authRepository.signInAnonymously()
                authState = .guest(anonymousUid: uid)
            } catch {
                authState = .guest(anonymousUid: nil)
            }
        }
    }

    /// Apple 로그인 성공 콜백 — 익명 UID이면 link, 아니면 일반 signIn.
    func signInWithApple(identityToken: Data, nonce: String, fullName: PersonName?) async throws {
        let user: AppUser
        if authState.isGuest {
            user = try await authRepository.linkAnonymousToApple(
                identityToken: identityToken,
                nonce: nonce,
                fullName: fullName
            )
        } else {
            user = try await authRepository.signInWithApple(
                identityToken: identityToken,
                nonce: nonce,
                fullName: fullName
            )
        }
        authState = .authenticated(user)
    }

    func signOut() async throws {
        try await authRepository.signOut()
        // 로그아웃 후 익명 사용자로 다시 발급.
        do {
            let uid = try await authRepository.signInAnonymously()
            authState = .guest(anonymousUid: uid)
        } catch {
            authState = .guest(anonymousUid: nil)
        }
    }
}
