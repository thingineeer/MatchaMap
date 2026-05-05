import SwiftUI
import Domain
import DesignSystem

/// 매장 상세 화면 — handoff-mapping.md 화면 7,8.
/// 헤로 + 평점 + 메뉴 칩 + 영업시간 + 주소 + 리뷰 탭.
public struct StoreDetailScreen: View {
    @Bindable private var viewModel: StoreDetailViewModel

    public init(viewModel: StoreDetailViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                heroSection
                tabSelector
                tabContent
            }
            .padding(.bottom, MMSpacing.xxl)
        }
        .background(Color.MM.bg)
        .ignoresSafeArea(edges: .top)
        .task { await viewModel.onAppear() }
    }

    // MARK: - Hero (헤더 이미지 + 이름 + 평점)

    @ViewBuilder
    private var heroSection: some View {
        switch viewModel.store {
        case .idle, .loading:
            heroSkeleton
        case .loaded(let store):
            heroLoaded(store: store)
        case .failed(let err):
            heroError(err)
        }
    }

    private func heroLoaded(store: Store) -> some View {
        VStack(alignment: .leading, spacing: MMSpacing.md) {
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.MM.matchaSoft, Color.MM.matchaPale],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(height: 280)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.MM.paper.opacity(0.4))
                    .padding(MMSpacing.xl)
            }
            VStack(alignment: .leading, spacing: MMSpacing.xs) {
                Text(store.name)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(Color.MM.deep)
                if let city = store.city {
                    Text("\(city), \(store.countryCode)")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(0.3)
                        .foregroundStyle(Color.MM.muted)
                }
                ratingRow(store: store)
                    .padding(.top, MMSpacing.xs)
                if let dist = viewModel.ratingDistribution {
                    ratingBars(dist: dist)
                        .padding(.top, MMSpacing.xs)
                }
            }
            .padding(.horizontal, MMSpacing.md)
        }
    }

    private func ratingRow(store: Store) -> some View {
        HStack(spacing: MMSpacing.xs) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: i < Int(store.ratingAvg.rounded()) ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.MM.gold)
                }
            }
            Text(String(format: "%.1f", store.ratingAvg))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.MM.deep)
            Text("(\(store.reviewCount))")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.MM.muted)
        }
    }

    private func ratingBars(dist: [(rating: Int, count: Int, fraction: Double)]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(dist, id: \.rating) { row in
                HStack(spacing: MMSpacing.xs) {
                    Text("\(row.rating)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.MM.muted)
                        .frame(width: 12, alignment: .trailing)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.MM.lineSoft)
                            Capsule()
                                .fill(Color.MM.matcha)
                                .frame(width: geo.size.width * row.fraction)
                        }
                    }
                    .frame(height: 6)
                    Text("\(row.count)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.MM.muted)
                        .frame(width: 32, alignment: .leading)
                }
            }
        }
    }

    private var heroSkeleton: some View {
        VStack(alignment: .leading, spacing: MMSpacing.md) {
            Rectangle()
                .fill(Color.MM.lineSoft)
                .frame(height: 280)
            VStack(alignment: .leading, spacing: MMSpacing.sm) {
                Capsule().fill(Color.MM.lineSoft).frame(width: 180, height: 22)
                Capsule().fill(Color.MM.lineSoft).frame(width: 110, height: 12)
            }
            .padding(.horizontal, MMSpacing.md)
        }
        .redacted(reason: .placeholder)
    }

    private func heroError(_ err: MMDomainError) -> some View {
        VStack(spacing: MMSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(Color.MM.muted)
            Text("매장 정보를 불러오지 못했어요")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.MM.deep)
            Text(String(describing: err))
                .font(.system(size: 11))
                .foregroundStyle(Color.MM.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MMSpacing.lg)
            Button("다시 시도") {
                Task { await viewModel.retry() }
            }
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, MMSpacing.lg)
            .padding(.vertical, MMSpacing.sm)
            .foregroundStyle(Color.MM.paper)
            .background(Color.MM.deep, in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MMSpacing.xxl)
    }

    // MARK: - Tabs

    private var tabSelector: some View {
        HStack(spacing: MMSpacing.lg) {
            ForEach(StoreDetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(MMMotion.standard) {
                        viewModel.selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(label(for: tab))
                            .font(.system(size: 13, weight: viewModel.selectedTab == tab ? .semibold : .medium))
                            .foregroundStyle(viewModel.selectedTab == tab ? Color.MM.deep : Color.MM.muted)
                        Capsule()
                            .fill(viewModel.selectedTab == tab ? Color.MM.deep : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, MMSpacing.md)
    }

    private func label(for tab: StoreDetailTab) -> String {
        switch tab {
        case .overview: return "소개"
        case .menu:     return "메뉴"
        case .reviews:  return "리뷰"
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .overview:
            overviewSection
        case .menu:
            menuSection
        case .reviews:
            ReviewListView(viewModel: viewModel)
                .padding(.horizontal, MMSpacing.md)
        }
    }

    // MARK: - Overview / Menu

    @ViewBuilder
    private var overviewSection: some View {
        if let store = viewModel.store.value {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                if !store.tagsTop.isEmpty {
                    sectionHeader("태그")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: MMSpacing.xs) {
                            ForEach(store.tagsTop, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.MM.deep)
                                    .padding(.horizontal, MMSpacing.sm)
                                    .padding(.vertical, MMSpacing.xs)
                                    .background(Color.MM.matchaPale, in: Capsule())
                            }
                        }
                    }
                }
                if let address = store.address {
                    sectionHeader("주소")
                    Text(address)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.MM.text)
                }
                if let hours = store.openingHours {
                    sectionHeader("영업시간")
                    openingHoursList(hours)
                }
            }
            .padding(.horizontal, MMSpacing.md)
        }
    }

    private var menuSection: some View {
        VStack(alignment: .leading, spacing: MMSpacing.md) {
            sectionHeader("메뉴")
            // Phase 4: 매장별 메뉴 endpoint 연동. MVP: placeholder 4종.
            ForEach(MenuCategory.allCases.prefix(4), id: \.self) { cat in
                HStack {
                    Image(systemName: "leaf")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.MM.matcha)
                    Text(menuLabel(cat))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.MM.deep)
                    Spacer()
                    Text("--")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.MM.muted)
                }
                .padding(.vertical, MMSpacing.xs)
            }
            Text("메뉴 정보는 Phase 4에서 연동돼요.")
                .font(.system(size: 11))
                .foregroundStyle(Color.MM.muted)
                .padding(.top, MMSpacing.xs)
        }
        .padding(.horizontal, MMSpacing.md)
    }

    private func menuLabel(_ cat: MenuCategory) -> String {
        switch cat {
        case .usucha:  return "우스차"
        case .koicha:  return "코이차"
        case .latte:   return "말차 라떼"
        case .iced:    return "아이스 말차"
        case .dessert: return "디저트"
        case .other:   return "기타"
        }
    }

    private func openingHoursList(_ hours: OpeningHours) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(OpeningHours.Weekday.allCases, id: \.self) { day in
                HStack {
                    Text(weekdayLabel(day))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.MM.deep)
                        .frame(width: 36, alignment: .leading)
                    if hours.isClosed(on: day) {
                        Text("휴무").font(.system(size: 12)).foregroundStyle(Color.MM.muted)
                    } else {
                        let slots = hours.slots[day] ?? []
                        Text(slots.map { "\($0.open)–\($0.close)" }.joined(separator: ", "))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.MM.text)
                    }
                    Spacer()
                }
            }
        }
    }

    private func weekdayLabel(_ d: OpeningHours.Weekday) -> String {
        switch d {
        case .mon: return "월"
        case .tue: return "화"
        case .wed: return "수"
        case .thu: return "목"
        case .fri: return "금"
        case .sat: return "토"
        case .sun: return "일"
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.3)
            .foregroundStyle(Color.MM.muted)
    }
}
