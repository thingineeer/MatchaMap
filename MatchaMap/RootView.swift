//
//  RootView.swift
//  MatchaMap
//
//  앱 진입 컨테이너. Splash → Login(Apple/Passkey) → MainTab 라우팅.
//  Phase 3 통합 — Feature 모듈의 실제 View로 4탭 wire.
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

    var body: some View {
        Group {
            switch phase {
            case .splash:
                SplashView()
                    .transition(.opacity)
                    .task {
                        try? await Task.sleep(for: .milliseconds(1400))
                        withAnimation(.easeOut(duration: 0.4)) { phase = .login }
                    }
            case .login:
                LoginView { phase = .main }
                    .transition(.opacity)
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
    }

    enum Phase { case splash, login, main }
}

/// Phase 3 placeholder — Phase 5에서 실 인증 결과로 main 전환. 디버그/Preview용으로 보존.
struct LoginPlaceholderView: View {
    let onSignIn: () -> Void
    var body: some View {
        ZStack {
            Color.MM.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                Text("말차맵에\n오신 걸 환영해요")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(Color.MM.deep)
                    .lineSpacing(6)
                Text("로그인하면 마신 말차와 위시리스트를\n모든 기기에서 동기화할 수 있어요.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.MM.muted)
                    .lineSpacing(5)
                Spacer()
                Button(action: onSignIn) {
                    HStack {
                        Image(systemName: "applelogo")
                        Text("Apple로 시작하기").bold()
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(.white)
                    .background(Color.MM.ink, in: RoundedRectangle(cornerRadius: 12))
                }
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

/// 4탭: 지도 / 피드 / 위시리스트 / 내정보.
/// Phase 3 mock: in-process Mock repositories로 4 화면 모두 렌더링 가능.
struct MainTabView: View {
    @State private var mockUid: String = "uid_self"
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

    @ViewBuilder
    private var wishlistTab: some View {
        let vm = WishlistViewModel(
            uid: mockUid,
            listUseCase: ListWishlistItemsUseCaseImpl(repository: mockWishlist),
            toggleUseCase: ToggleWishlistUseCaseImpl(repository: mockWishlist)
        )
        NavigationStack {
            WishlistView(viewModel: vm)
                .navigationTitle("위시리스트")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var profileTab: some View {
        let vm = ProfileViewModel(
            uid: mockUid,
            userRepository: mockUser,
            listCollections: ListCollectionItemsUseCaseImpl(repository: mockCollection)
        )
        NavigationStack {
            ProfileView(viewModel: vm)
                .navigationTitle("내정보")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Placeholders (디버그/Preview 용도, MainTabView에서 더 이상 사용하지 않음)

private struct MapPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.MM.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "map.fill").font(.system(size: 56)).foregroundStyle(Color.MM.matchaSoft)
                Text("지도").font(.system(size: 28, weight: .bold, design: .serif)).foregroundStyle(Color.MM.deep)
                Text("Google Maps SDK 통합 — Phase 5").font(.caption).foregroundStyle(Color.MM.muted)
            }
        }
    }
}
private struct FeedPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.MM.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "person.2.fill").font(.system(size: 56)).foregroundStyle(Color.MM.rose)
                Text("피드").font(.system(size: 28, weight: .bold, design: .serif)).foregroundStyle(Color.MM.deep)
                Text("친구 활동 — FeatureSocial").font(.caption).foregroundStyle(Color.MM.muted)
            }
        }
    }
}
private struct WishlistPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.MM.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "bookmark.fill").font(.system(size: 56)).foregroundStyle(Color.MM.gold)
                Text("위시리스트").font(.system(size: 28, weight: .bold, design: .serif)).foregroundStyle(Color.MM.deep)
                Text("국가별 그룹 + 미니 세계지도 — FeatureCollection").font(.caption).foregroundStyle(Color.MM.muted)
            }
        }
    }
}
private struct ProfilePlaceholderView: View {
    var body: some View {
        ZStack {
            Color.MM.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill").font(.system(size: 56)).foregroundStyle(Color.MM.matcha)
                Text("내정보").font(.system(size: 28, weight: .bold, design: .serif)).foregroundStyle(Color.MM.deep)
                Text("도감 / 리뷰 / 친구 — FeatureCollection.ProfileView").font(.caption).foregroundStyle(Color.MM.muted)
            }
        }
    }
}

#Preview {
    RootView()
}
