//
//  RootView.swift
//  MatchaMap
//
//  앱 진입 컨테이너. ADR-304 — Splash → Main 직행 (login 단계 제거).
//  로그인은 게이트별 시트(LoginIntent)로 띄움.
//

import SwiftUI
import Domain
import DesignSystem
import FeatureAuth
import FeatureMap
import FeatureSocial
import FeatureCollection
import FeatureStore

struct RootView: View {
    @State private var phase: Phase = .splash
    @State private var loginSheet: LoginIntent?

    var body: some View {
        Group {
            switch phase {
            case .splash:
                SplashView()
                    .transition(.opacity)
                    .task {
                        try? await Task.sleep(for: .milliseconds(1400))
                        withAnimation(.easeOut(duration: 0.4)) { phase = .main }
                    }
            case .main:
                MainTabView(loginSheet: $loginSheet)
                    .transition(.opacity)
                    .sheet(item: $loginSheet) { intent in
                        LoginView(
                            intent: intent.toAuthIntent(),
                            onSignIn: { loginSheet = nil },
                            onSkip: { loginSheet = nil }
                        )
                        .presentationDetents([.medium, .large])
                    }
            }
        }
    }

    enum Phase { case splash, main }
}

private extension LoginIntent {
    func toAuthIntent() -> LoginView.Intent {
        switch self {
        case .review:           return .review
        case .collectionUnlock: return .collectionUnlock
        case .wishlistCap:      return .wishlistCap
        case .friend:           return .friend
        case .profile:          return .profile
        case .push:             return .push
        case .rewarded:         return .rewarded
        }
    }
}

/// 4탭: 지도 / 피드 / 위시리스트 / 내정보.
/// Phase 3 mock: in-process Mock repositories로 4 화면 모두 렌더링 가능.
/// ADR-304: 4번째 탭 진입 시 게스트면 LoginIntent.profile 시트 트리거 (탭 자체는 ProfileView가 게스트 빈상태 카드).
struct MainTabView: View {
    @Binding var loginSheet: LoginIntent?

    @State private var mockUid: String = "uid_self"
    /// ADR-304 — 통합 빌드용 게스트 시뮬: AppContainer 미주입 시 .guest로 시작.
    @State private var authState: AuthState = .guest(anonymousUid: "anon-mock")

    // Mock repos — Phase 4에서 AppContainer.shared로 교체.
    private let mockCollection = MockCollectionRepository()
    private let mockWishlist = MockWishlistRepository()
    private let mockFeed = MockFeedRepository(seed: [
        FeedEvent.fixture(id: "fe-1"),
        FeedEvent.fixture(id: "fe-2", actorUid: "uid_friend_2", type: .review)
    ])
    private let mockUser = MockUserRepository()

    @State private var pushedStore: Store?

    var body: some View {
        TabView {
            mapTab
                .tabItem { Label("지도", systemImage: "map") }
            feedTab
                .tabItem { Label("피드", systemImage: "person.2") }
            wishlistTab
                .tabItem { Label("위시리스트", systemImage: "bookmark") }
            profileTab
                .tabItem { Label("내정보", systemImage: "person.crop.circle") }
        }
        .tint(Color.MM.deep)
    }

    @ViewBuilder
    private var mapTab: some View {
        NavigationStack {
            MapView(
                onTapStore: { _ in },
                onTapSearch: {}
            )
            .navigationBarHidden(true)
        }
    }

    @ViewBuilder
    private var feedTab: some View {
        // 게스트 → 친구 피드 차단 (ADR-304). 시트 트리거 + 빈 상태.
        if authState.isGuest {
            guestEmpty(
                title: "친구 피드는 로그인 후",
                body: "친구의 활동을 보려면 로그인이 필요해요.",
                cta: "로그인 / 가입",
                intent: .friend
            )
        } else {
            let vm = FeedViewModel(
                uid: mockUid,
                loadFeed: LoadFeedUseCaseImpl(repository: mockFeed),
                toggleLike: ToggleLikeUseCaseImpl(repository: mockFeed),
                addComment: AddCommentUseCaseImpl(repository: mockFeed)
            )
            NavigationStack {
                FeedView(viewModel: vm)
                    .navigationTitle("피드")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    @ViewBuilder
    private var wishlistTab: some View {
        let vm: WishlistViewModel = {
            let viewModel = WishlistViewModel(
                uid: mockUid,
                authState: authState,
                listUseCase: ListWishlistItemsUseCaseImpl(repository: mockWishlist),
                toggleUseCase: ToggleWishlistUseCaseImpl(repository: mockWishlist)
            )
            viewModel.onRequireLogin = { [$loginSheet] intent in
                $loginSheet.wrappedValue = intent
            }
            return viewModel
        }()
        NavigationStack {
            WishlistView(viewModel: vm)
                .navigationTitle("위시리스트")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var profileTab: some View {
        let vm: ProfileViewModel = {
            let viewModel = ProfileViewModel(
                uid: mockUid,
                authState: authState,
                userRepository: mockUser,
                listCollections: ListCollectionItemsUseCaseImpl(repository: mockCollection)
            )
            viewModel.onRequireLogin = { [$loginSheet] intent in
                $loginSheet.wrappedValue = intent
            }
            return viewModel
        }()
        NavigationStack {
            ProfileView(viewModel: vm)
                .navigationTitle("내정보")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func guestEmpty(title: String, body: String, cta: String, intent: LoginIntent) -> some View {
        ZStack {
            Color.MM.bg.ignoresSafeArea()
            VStack(spacing: MMSpacing.md) {
                Image(systemName: "person.2.circle")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.MM.matchaSoft)
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color.MM.deep)
                Text(body)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.MM.muted)
                    .multilineTextAlignment(.center)
                Button(action: { loginSheet = intent }) {
                    Text(cta)
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: 280, minHeight: 48)
                        .foregroundStyle(.white)
                        .background(Color.MM.deep, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, MMSpacing.sm)
            }
            .padding(MMSpacing.lg)
        }
    }
}

#Preview {
    RootView()
}
