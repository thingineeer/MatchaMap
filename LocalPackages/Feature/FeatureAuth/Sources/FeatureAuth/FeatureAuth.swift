// FeatureAuth — Apple Sign In + Passkey UI.
// 의존: Domain, DesignSystem, AuthenticationServices(시스템 프레임워크).
//
// Phase 3에서 채울 항목:
// - AuthEntryScreen.swift
// - AuthViewModel.swift
// - AppleSignInButton.swift          (ASAuthorizationAppleIDButton 래퍼)
// - PasskeyRegistrationFlow.swift
//
// 가설 H5(가입 전환율) 측정 이벤트는 docs/server/observability.md § auth_signup 참조.

import Domain
import DesignSystem

public enum FeatureAuth {
    public static let version: String = "0.1.0"
}
