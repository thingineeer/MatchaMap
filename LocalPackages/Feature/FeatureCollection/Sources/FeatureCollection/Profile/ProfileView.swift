import SwiftUI
import Domain
import DesignSystem

/// 프로필 화면 — handoff-mapping §13.
/// 통계 (collectionCount/reviewCount/wishlistCount/friendCount) + 최근 도감 carousel + 메뉴.
public struct ProfileView: View {
    @Bindable private var viewModel: ProfileViewModel

    public init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: MMSpacing.lg) {
                avatarRow
                statsHero
                recentCollectionsSection
                menuList
            }
            .padding(MMSpacing.md)
        }
        .background(Color.MM.bg)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private var avatarRow: some View {
        HStack(spacing: MMSpacing.md) {
            Circle()
                .fill(LinearGradient(
                    colors: [Color.MM.matcha, Color.MM.rose],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 64, height: 64)
                .overlay(
                    Circle()
                        .fill(Color.MM.cream)
                        .frame(width: 56, height: 56)
                )
                .overlay(
                    Text(viewModel.profile?.displayName.prefix(1).uppercased() ?? "M")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.MM.deep)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.profile?.displayName ?? "Loading...")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.MM.deep)
                if let homeCountry = viewModel.profile?.homeCountryCode {
                    Text(homeCountry)
                        .font(.system(size: 11, weight: .medium))
                        .tracking(0.2)
                        .foregroundStyle(Color.MM.muted)
                }
            }
            Spacer()
        }
    }

    private var statsHero: some View {
        let stats = viewModel.profile?.stats ?? .zero
        return HStack(spacing: 0) {
            statCell(label: "마신 잔", value: stats.collectionCount)
            Divider().frame(height: 36).background(Color.MM.lineSoft)
            statCell(label: "리뷰", value: stats.reviewCount)
            Divider().frame(height: 36).background(Color.MM.lineSoft)
            statCell(label: "위시", value: stats.wishlistCount)
            Divider().frame(height: 36).background(Color.MM.lineSoft)
            statCell(label: "친구", value: stats.friendCount)
        }
        .padding(.vertical, MMSpacing.md)
        .background(Color.MM.paper)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.xxl))
    }

    private func statCell(label: String, value: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.MM.deep)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .tracking(0.2)
                .foregroundStyle(Color.MM.rose)
        }
        .frame(maxWidth: .infinity)
    }

    private var recentCollectionsSection: some View {
        VStack(alignment: .leading, spacing: MMSpacing.sm) {
            HStack {
                Text("최근 마신 말차")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.MM.deep)
                Spacer()
                Text("전체 →")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.MM.rose)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MMSpacing.sm) {
                    ForEach(viewModel.recentItems) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            RoundedRectangle(cornerRadius: MMRadius.lg)
                                .fill(item.colorTier.map { Color.MM.matchaTier($0.dsTier) } ?? Color.MM.matchaPale)
                                .frame(width: 130, height: 130)
                            Text(item.store.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.MM.deep)
                                .lineLimit(1)
                                .frame(width: 130, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    private var menuList: some View {
        VStack(spacing: 0) {
            menuRow(label: "위시리스트", systemImage: "bookmark")
            Divider().background(Color.MM.lineSoft)
            menuRow(label: "내 리뷰", systemImage: "text.quote")
            Divider().background(Color.MM.lineSoft)
            menuRow(label: "친구", systemImage: "person.2")
            Divider().background(Color.MM.lineSoft)
            menuRow(label: "알림 설정", systemImage: "bell")
        }
        .background(Color.MM.paper)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.xxl))
        .overlay(
            RoundedRectangle(cornerRadius: MMRadius.xxl)
                .strokeBorder(Color.MM.lineSoft, lineWidth: 1)
        )
    }

    private func menuRow(label: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .font(.system(size: 16))
                .foregroundStyle(Color.MM.muted)
                .frame(width: 28)
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.MM.deep)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.MM.muted)
        }
        .padding(.horizontal, MMSpacing.md)
        .padding(.vertical, MMSpacing.md)
    }
}

@MainActor
@Observable
public final class ProfileViewModel {
    public private(set) var profile: UserProfile?
    public private(set) var recentItems: [CollectionItem] = []
    public private(set) var isLoading: Bool = false
    public private(set) var error: String?

    private let uid: String
    private let userRepo: any UserRepository
    private let listCollections: any ListCollectionItemsUseCase

    public init(
        uid: String,
        userRepository: any UserRepository,
        listCollections: any ListCollectionItemsUseCase
    ) {
        self.uid = uid
        self.userRepo = userRepository
        self.listCollections = listCollections
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        async let profileTask: () = loadProfile()
        async let recentTask: () = loadRecent()
        _ = await (profileTask, recentTask)
    }

    private func loadProfile() async {
        do {
            profile = try await userRepo.profile(uid: uid)
        } catch {
            self.error = String(describing: error)
        }
    }

    private func loadRecent() async {
        do {
            let page = try await listCollections(uid: uid, cursor: nil, limit: 8)
            recentItems = page.items
        } catch {
            self.error = String(describing: error)
        }
    }
}
