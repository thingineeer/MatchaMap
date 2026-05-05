import SwiftUI
import AuthenticationServices
import DesignSystem

/// 로그인 화면 — handoff-mapping §1 + RootView Login phase 대체용.
/// Phase 3 MVP: SignInWithAppleButton + Passkey placeholder.
/// TODO(Phase5): AuthRepository 주입 + identityToken/nonce 교환 + Passkey ASAuthorizationController.
public struct LoginView: View {
    private let onSignIn: () -> Void

    public init(onSignIn: @escaping () -> Void) {
        self.onSignIn = onSignIn
    }

    public var body: some View {
        ZStack {
            Color.MM.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: MMSpacing.md) {
                Text("말차맵에\n오신 걸 환영해요")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(Color.MM.deep)
                    .lineSpacing(6)
                Text("로그인하면 마신 말차와 위시리스트를\n모든 기기에서 동기화할 수 있어요.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.MM.muted)
                    .lineSpacing(5)
                Spacer()

                SignInWithAppleButton(.signIn) { _ in
                    // Phase 5: nonce 생성 + ASAuthorizationAppleIDRequest 구성.
                } onCompletion: { _ in
                    // Phase 5: identityToken / nonce / fullName 추출 → AuthRepository.signInWithApple.
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
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 28)
            .padding(.top, 80)
        }
    }
}

#Preview {
    LoginView(onSignIn: {})
}
