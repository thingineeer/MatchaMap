//
//  AppCheckProviderFactoryImpl.swift
//  MatchaMap
//
//  ADR-303 v1.2 정합 — 운영 빌드는 App Attest, 시뮬레이터/Debug는 DeviceCheck fallback.
//  FirebaseApp.configure() 호출 *전*에 AppCheck.setAppCheckProviderFactory() 등록 필요.

import Foundation
import FirebaseCore
import FirebaseAppCheck

final class MatchaMapAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if targetEnvironment(simulator)
        // 시뮬레이터: Debug provider (Firebase Console에서 token 등록 후 사용).
        return AppCheckDebugProvider(app: app)
        #else
        if #available(iOS 14.0, *) {
            return AppAttestProvider(app: app)
        } else {
            return DeviceCheckProvider(app: app)
        }
        #endif
    }
}
