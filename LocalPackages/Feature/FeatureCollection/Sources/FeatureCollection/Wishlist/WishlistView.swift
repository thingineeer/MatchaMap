import SwiftUI
import Domain
import DesignSystem

/// 위시리스트 화면 — handoff-mapping §12.
/// 헤더 + 미니 세계지도 + 국가별 그룹 row.
public struct WishlistView: View {
    @Bindable private var viewModel: WishlistViewModel

    public init(viewModel: WishlistViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                MiniWorldMapView(highlights: viewModel.worldMapHighlights, height: 160)
                    .padding(.horizontal, MMSpacing.md)
                    .overlay(alignment: .topTrailing) {
                        Text("\(viewModel.items.count) PINS")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(0.3)
                            .foregroundStyle(Color.MM.deep)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.MM.paper.opacity(0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .padding(MMSpacing.md)
                    }

                ForEach(viewModel.groupedByCountry, id: \.country) { group in
                    countrySection(country: group.country, items: group.items)
                }
            }
            .padding(.vertical, MMSpacing.md)
        }
        .background(Color.MM.bg)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private func countrySection(country: String, items: [WishlistItem]) -> some View {
        VStack(alignment: .leading, spacing: MMSpacing.sm) {
            HStack {
                Text(country.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.3)
                    .foregroundStyle(Color.MM.muted)
                Spacer()
                Text("\(items.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.MM.deep)
            }
            ForEach(items) { item in
                WishlistRowView(item: item) {
                    Task { await viewModel.toggle(store: item.store, note: item.note) }
                }
                .opacity(viewModel.optimisticPlaceIds.contains(item.storeId) ? 0.6 : 1.0)
            }
        }
        .padding(.horizontal, MMSpacing.md)
    }
}

struct WishlistRowView: View {
    let item: WishlistItem
    let onToggleBookmark: () -> Void

    var body: some View {
        HStack(spacing: MMSpacing.sm) {
            RoundedRectangle(cornerRadius: MMRadius.sm)
                .fill(Color.MM.matchaPale)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.store.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.MM.deep)
                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 11, weight: .regular))
                        .italic()
                        .foregroundStyle(Color.MM.rose)
                }
                Text(item.store.city)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.MM.muted)
            }
            Spacer()
            Button(action: onToggleBookmark) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.MM.deep)
            }
            .buttonStyle(.plain)
        }
        .padding(MMSpacing.sm)
        .background(Color.MM.paper)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: MMRadius.lg)
                .strokeBorder(Color.MM.lineSoft, lineWidth: 1)
        )
    }
}
