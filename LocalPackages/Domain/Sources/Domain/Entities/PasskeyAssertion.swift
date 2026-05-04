import Foundation

/// `ASAuthorizationPlatformPublicKeyCredentialAssertion`의 Domain 매핑.
/// Firebase Auth Passkey 교환에 필요한 4가지 raw 데이터.
public struct PasskeyAssertion: Sendable, Hashable {
    public let credentialID: Data
    public let rawAuthenticatorData: Data
    public let rawClientDataJSON: Data
    public let signature: Data

    public init(
        credentialID: Data,
        rawAuthenticatorData: Data,
        rawClientDataJSON: Data,
        signature: Data
    ) {
        self.credentialID = credentialID
        self.rawAuthenticatorData = rawAuthenticatorData
        self.rawClientDataJSON = rawClientDataJSON
        self.signature = signature
    }
}

/// Passkey 신규 등록(register) 결과 — assertion과 attestation 분리.
public struct PasskeyRegistration: Sendable, Hashable {
    public let credentialID: Data
    public let rawAttestationObject: Data
    public let rawClientDataJSON: Data

    public init(
        credentialID: Data,
        rawAttestationObject: Data,
        rawClientDataJSON: Data
    ) {
        self.credentialID = credentialID
        self.rawAttestationObject = rawAttestationObject
        self.rawClientDataJSON = rawClientDataJSON
    }
}
