import SwiftUI
import Domain
import DesignSystem

/// 매장 검색 화면 — handoff-mapping.md 화면 9.
/// 빈 query: 최근 검색어 + 최근 본 매장. 결과: 도시별 그룹.
public struct StoreSearchScreen: View {
    @Bindable private var viewModel: SearchViewModel
    @State private var showFilters: Bool = false
    @State private var selectedResult: SearchResult?

    public init(viewModel: SearchViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, MMSpacing.md)
                    .padding(.vertical, MMSpacing.sm)
                ScrollView {
                    if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        recentsContent
                    } else {
                        resultsContent
                    }
                }
            }
            .background(Color.MM.bg)
            .navigationTitle("검색")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .task { await viewModel.onAppear() }
            .sheet(isPresented: $showFilters) {
                FilterSheet(
                    initial: viewModel.filters,
                    onApply: { next in
                        Task { await viewModel.applyFilters(next) }
                    }
                )
            }
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: MMSpacing.xs) {
            HStack(spacing: MMSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.MM.muted)
                TextField("매장 또는 도시", text: $viewModel.query)
                    .font(.system(size: 14))
                    .submitLabel(.search)
                    .onSubmit { Task { await viewModel.onSubmit() } }
                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.clearQuery()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.MM.mutedSoft)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, MMSpacing.sm)
            .padding(.vertical, MMSpacing.xs)
            .background(Color.MM.cream)
            .clipShape(Capsule())

            Button {
                showFilters = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12, weight: .semibold))
                    Text("필터")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(viewModel.filters.isActive ? Color.MM.paper : Color.MM.deep)
                .padding(.horizontal, MMSpacing.sm)
                .padding(.vertical, MMSpacing.xs)
                .background(
                    viewModel.filters.isActive ? Color.MM.deep : Color.MM.cream,
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Recents

    @ViewBuilder
    private var recentsContent: some View {
        VStack(alignment: .leading, spacing: MMSpacing.lg) {
            if !viewModel.recentQueries.isEmpty {
                VStack(alignment: .leading, spacing: MMSpacing.xs) {
                    sectionHeader("최근 검색어")
                    FlowChips(items: viewModel.recentQueries) { q in
                        viewModel.query = q
                    }
                }
            }
            if !viewModel.recentStores.isEmpty {
                VStack(alignment: .leading, spacing: MMSpacing.xs) {
                    sectionHeader("최근 본 매장")
                    LazyVStack(spacing: MMSpacing.xs) {
                        ForEach(viewModel.recentStores) { item in
                            resultRow(item: item)
                        }
                    }
                }
            }
            if viewModel.recentQueries.isEmpty && viewModel.recentStores.isEmpty {
                emptyHint
            }
        }
        .padding(.horizontal, MMSpacing.md)
        .padding(.vertical, MMSpacing.md)
    }

    private var emptyHint: some View {
        VStack(spacing: MMSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(Color.MM.muted)
            Text("매장 이름이나 도시로 검색해보세요")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.MM.deep)
            Text("예: 마차하우스, 교토, 우지")
                .font(.system(size: 11))
                .foregroundStyle(Color.MM.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MMSpacing.xxl)
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsContent: some View {
        switch viewModel.results {
        case .idle:
            EmptyView()
        case .loading:
            ProgressView()
                .padding(.top, MMSpacing.xl)
        case .loaded(let page):
            if page.results.isEmpty {
                VStack(spacing: MMSpacing.sm) {
                    Image(systemName: "leaf")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.MM.muted)
                    Text("결과가 없어요")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.MM.deep)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MMSpacing.xxl)
            } else {
                LazyVStack(alignment: .leading, spacing: MMSpacing.lg) {
                    ForEach(viewModel.groupedResults, id: \.groupKey) { group in
                        VStack(alignment: .leading, spacing: MMSpacing.xs) {
                            sectionHeader(group.groupKey)
                            ForEach(group.items) { item in
                                resultRow(item: item)
                            }
                        }
                    }
                }
                .padding(.horizontal, MMSpacing.md)
                .padding(.vertical, MMSpacing.md)
            }
        case .failed(let err):
            VStack(spacing: MMSpacing.sm) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.MM.muted)
                Text("검색에 실패했어요")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.MM.deep)
                Text(String(describing: err))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.MM.muted)
                Button("다시 시도") {
                    Task { await viewModel.onSubmit() }
                }
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, MMSpacing.lg)
                .padding(.vertical, MMSpacing.xs)
                .foregroundStyle(Color.MM.paper)
                .background(Color.MM.deep, in: Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(MMSpacing.xl)
        }
    }

    private func resultRow(item: SearchResult) -> some View {
        Button {
            Task { await viewModel.onSelectResult(item) }
            selectedResult = item
        } label: {
            HStack(spacing: MMSpacing.sm) {
                RoundedRectangle(cornerRadius: MMRadius.md)
                    .fill(Color.MM.matchaPale)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.MM.matcha)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.MM.deep)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        if let city = item.city {
                            Text(city)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.MM.muted)
                        }
                        Text(item.countryCode)
                            .font(.system(size: 10, weight: .medium))
                            .tracking(0.2)
                            .foregroundStyle(Color.MM.muted)
                        if let rating = item.rating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.MM.gold)
                                Text(String(format: "%.1f", rating))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.MM.deep)
                            }
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.MM.muted)
            }
            .padding(MMSpacing.sm)
            .background(Color.MM.paper)
            .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.3)
            .foregroundStyle(Color.MM.muted)
    }
}

// MARK: - FlowChips (간단 wrap)

private struct FlowChips: View {
    let items: [String]
    let onTap: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MMSpacing.xs) {
                ForEach(items, id: \.self) { q in
                    Button {
                        onTap(q)
                    } label: {
                        Text(q)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.MM.deep)
                            .padding(.horizontal, MMSpacing.sm)
                            .padding(.vertical, MMSpacing.xs)
                            .background(Color.MM.cream, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
