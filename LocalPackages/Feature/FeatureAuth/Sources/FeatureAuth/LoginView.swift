import SwiftUI
import AuthenticationServices
import DesignSystem

/// 로그인 시트 — handoff-mapping §1 + RootView 게스트 모드 게이트.
/// ADR-304: 다양한 게이트(intent)로부터 시트로 띄워지므로 헤더 카피를 분기.
/// Phase 5에서 AuthRepository 주입 + identityToken/nonce 교환 + Passkey ASAuthorizationController 연결.
public struct LoginView: View {
    public enum Intent: String, Sendable, Hashable, CaseIterable {
        case onboarding
        case review
        case collectionUnlock
        case wishlistCap
        case friend
        case profile
        case push
        case rewarded
    }

    private let intent: Intent
    private let onSignIn: () -> Void
    private let onSkip: (() -> Void)?

    public init(
        intent: Intent = .onboarding,
        onSignIn: @escaping () -> Void,
        onSkip: (() -> Void)? = nil
    ) {
        self.intent = intent
        self.onSignIn = onSignIn
        self.onSkip = onSkip
    }

    public var body: some View {
        ZStack {
            Color.MM.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: MMSpacing.md) {
                Text(headline)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Color.MM.deep)
                    .lineSpacing(6)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.MM.muted)
                    .lineSpacing(5)
                Spacer()

                SignInWithAppleButton(.signIn) { _ in
                    // Phase 5: nonce 생성 + ASAuthorizationAppleIDRequest 구성.
                } onCompletion: { _ in
                    // Phase 5: identityToken / nonce / fullName 추출 → AuthRepository.signInWithApple
                    //          또는 익명 사용자라면 linkAnonymousToApple.
                    onSignIn()
                }
                #if os(iOS)
                .signInWithAppleButtonStyle(.black)
                #endif
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button(action: onSignIn) {
                    HStack {
                        Image(systemName: "key.fill")
                        Text("Passkey로 시작하기").bold()
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(Color.MM.deep)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.MM.line, lineWidth: 1))
                }

                if let onSkip {
                    Button(action: onSkip) {
                        Text("나중에")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.MM.muted)
                            .frame(maxWidth: .infinity, minHeight: 40)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 60)
            .padding(.bottom, 24)
        }
    }

    private var headline: String {
        switch intent {
        case .onboarding:        return "말차맵에\n오신 걸 환영해요"
        case .review:            return "리뷰를 남기려면\n로그인하세요"
        case .collectionUnlock:  return "도감을\n시작해볼까요?"
        case .wishlistCap:       return "위시리스트는\n로그인부터 무제한"
        case .friend:            return "친구와\n함께 마셔요"
        case .profile:           return "내정보는\n로그인 후에"
        case .push:              return "알림 받으려면\n로그인하세요"
        case .rewarded:          return "보상 받으려면\n로그인하세요"
        }
    }

    private var subtitle: String {
        switch intent {
        case .onboarding:        return "로그인하면 마신 말차와 위시리스트를\n모든 기기에서 동기화할 수 있어요."
        case .review:            return "본문 입력은 미리 저장돼요.\n로그인 후 등록 버튼을 다시 눌러주세요."
        case .collectionUnlock:  return "마신 말차를 카드로 모아\n전 세계 도감을 채울 수 있어요."
        case .wishlistCap:       return "게스트는 5곳까지 저장 가능.\n로그인하면 전부 동기화돼요."
        case .friend:            return "친구의 도감과 리뷰를 보고\n매장을 함께 탐험해요."
        case .profile:           return "프로필·도감·친구는\n로그인 사용자만 이용해요."
        case .push:              return "친구 활동 / 새 매장 알림은\n로그인 후 받을 수 있어요."
        case .rewarded:          return "보상형 광고로 도감 슬롯을\n무료 해제하려면 로그인이 필요해요."
        }
    }
}

#Preview {
    LoginView(intent: .onboarding, onSignIn: {})
}
