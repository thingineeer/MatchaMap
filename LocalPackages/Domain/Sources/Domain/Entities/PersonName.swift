import Foundation

/// Apple `ASAuthorizationAppleIDCredential.fullName`(`PersonNameComponents`)에서 매핑되는 사용자 이름.
/// 셋 다 nil 가능 (Apple privateRelay/익명 가입 + 첫 가입이 아닌 재로그인 케이스).
public struct PersonName: Sendable, Hashable, Codable {
    public let givenName: String?
    public let familyName: String?
    public let nickname: String?

    public init(givenName: String? = nil, familyName: String? = nil, nickname: String? = nil) {
        self.givenName = givenName?.trimmedOrNil
        self.familyName = familyName?.trimmedOrNil
        self.nickname = nickname?.trimmedOrNil
    }

    /// 표시용 이름. nickname > "given family" > given > family > nil 순.
    public var displayName: String? {
        if let nickname { return nickname }
        switch (givenName, familyName) {
        case let (g?, f?): return "\(g) \(f)"
        case let (g?, nil): return g
        case let (nil, f?): return f
        case (nil, nil): return nil
        }
    }

    public var isEmpty: Bool {
        givenName == nil && familyName == nil && nickname == nil
    }
}

private extension String {
    var trimmedOrNil: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
