//
//  RootView.swift
//  MatchaMap
//
//  앱 진입 컨테이너. Splash → Login(Apple/Passkey) → MainTab 라우팅.
//  Phase 3 placeholder — Phase 4에서 실 인증 결과로 분기.
//

import SwiftUI
import DesignSystem

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
                LoginPlaceholderView { phase = .main }
                    .transition(.opacity)
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
    }

    enum Phase { case splash, login, main }
}

/// Phase 3 placeholder. Phase 4에서 FeatureAuth.LoginView로 교체.
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
struct MainTabView: View {
    var body: some View {
        TabView {
            MapPlaceholderView()
                .tabItem { Label("지도", systemImage: "map") }
            FeedPlaceholderView()
                .tabItem { Label("피드", systemImage: "person.2") }
            WishlistPlaceholderView()
                .tabItem { Label("위시리스트", systemImage: "bookmark") }
            ProfilePlaceholderView()
                .tabItem { Label("내정보", systemImage: "person.crop.circle") }
        }
        .tint(Color.MM.deep)
    }
}

private struct MapPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.MM.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "map.fill").font(.system(size: 56)).foregroundStyle(Color.MM.matchaSoft)
                Text("지도").font(.system(size: 28, weight: .bold, design: .serif)).foregroundStyle(Color.MM.deep)
                Text("Google Maps SDK 통합 — Phase 3 ios-map worktree").font(.caption).foregroundStyle(Color.MM.muted)
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
