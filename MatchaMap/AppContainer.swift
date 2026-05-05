//
//  AppContainer.swift
//  MatchaMap
//
//  Composition Root의 의존성 컨테이너 — ADR-002 DI.
//  Repository factory closure + Firebase clients를 보유.
//  Phase 4 통합 빌드에서 Feature ViewModel들이 본 컨테이너로부터 의존을 주입받음.

import Foundation
import Domain

@MainActor
struct AppContainer {

    /// 인증된 사용자 Repository — Firebase Auth + Apple/Passkey 어댑터.
    let authRepository: any AuthRepository

    /// 매장 Repository — Firestore 어댑터.
    let storeRepository: any StoreRepository

    /// 푸시 토큰 Repository — FCM + Firestore subcollection.
    let pushTokenRepository: any PushTokenRepository
}
