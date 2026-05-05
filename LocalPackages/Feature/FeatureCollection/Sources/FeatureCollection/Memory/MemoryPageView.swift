import SwiftUI
import Domain
import DesignSystem

/// 메모리 페이지 — 도감 카드 상세. screens.md C2 / handoff-mapping §13.
/// 등급/원산지/colorTier 5단계 슬라이더 + 메모/사진.
public struct MemoryPageView: View {
    @Bindable private var viewModel: MemoryPageViewModel

    public init(viewModel: MemoryPageViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                header
                colorTierSlider
                metadataSection
                noteSection
                if let coord = originCoord {
                    miniOriginMapSection(coord)
                }
            }
            .padding(MMSpacing.md)
        }
        .background(Color.MM.bg)
        .navigationTitle(viewModel.item.store.name)
    }

    private var header: some View {
        HStack(spacing: MMSpacing.sm) {
            Circle()
                .fill(viewModel.colorTierColor)
                .frame(width: 64, height: 64)
                .overlay(Circle().strokeBorder(Color.MM.line, lineWidth: 1))
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.item.store.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.MM.deep)
                Text(viewModel.item.store.city.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .tracking(0.3)
                    .foregroundStyle(Color.MM.muted)
            }
            Spacer()
        }
    }

    private var colorTierSlider: some View {
        VStack(alignment: .leading, spacing: MMSpacing.xs) {
            Text("색감")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.MM.text)
            HStack(spacing: MMSpacing.xs) {
                ForEach(MatchaColorTier.allCases, id: \.self) { tier in
                    let selected = viewModel.draftColorTier == tier
                    Button {
                        viewModel.setColorTier(tier)
                    } label: {
                        Circle()
                            .fill(Color.MM.matchaTier(tier))
                            .frame(width: selected ? 36 : 28, height: selected ? 36 : 28)
                            .overlay(
                                Circle().strokeBorder(
                                    selected ? Color.MM.deep : Color.MM.line,
                                    lineWidth: selected ? 2 : 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tier.rawValue)
                }
            }
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: MMSpacing.xs) {
            metadataRow(label: "음료", value: viewModel.item.drink.rawValue.replacingOccurrences(of: "_", with: " "))
            if let grade = viewModel.item.grade {
                metadataRow(label: "등급", value: grade.rawValue)
            }
            if let region = viewModel.item.originRegion {
                metadataRow(label: "원산지", value: region.rawValue)
            }
            metadataRow(label: "방문", value: viewModel.formattedVisitedAt)
        }
        .padding(MMSpacing.md)
        .background(Color.MM.paper)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .tracking(0.2)
                .foregroundStyle(Color.MM.muted)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.MM.deep)
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: MMSpacing.xs) {
            Text("메모")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.MM.text)
            TextEditor(text: $viewModel.draftNote)
                .frame(minHeight: 80)
                .padding(MMSpacing.xs)
                .background(Color.MM.paper)
                .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
        }
    }

    private var originCoord: GeoCoord? {
        MatchaOriginCoords.coord(for: viewModel.item.originRegion?.rawValue)
    }

    private func miniOriginMapSection(_ coord: GeoCoord) -> some View {
        VStack(alignment: .leading, spacing: MMSpacing.xs) {
            Text("원산지")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.MM.text)
            MiniWorldMapView(highlights: [coord], height: 120)
        }
    }
}

@MainActor
@Observable
public final class MemoryPageViewModel {
    public private(set) var item: CollectionItem
    public var draftNote: String
    public private(set) var draftColorTier: MatchaColorTier?
    public private(set) var isSaving: Bool = false
    public private(set) var error: String?

    private let updateUseCase: any UpdateCollectionItemUseCase

    public init(item: CollectionItem, updateUseCase: any UpdateCollectionItemUseCase) {
        self.item = item
        self.draftNote = item.note ?? ""
        self.draftColorTier = item.colorTier?.dsTier
        self.updateUseCase = updateUseCase
    }

    public var colorTierColor: Color {
        if let tier = draftColorTier {
            return Color.MM.matchaTier(tier)
        }
        return Color.MM.matchaPale
    }

    public var formattedVisitedAt: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: item.visitedAt)
    }

    public func setColorTier(_ tier: MatchaColorTier) {
        draftColorTier = tier
    }

    public func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await updateUseCase(
                uid: item.uid,
                itemId: item.id,
                patch: CollectionItemPatch(
                    note: draftNote.isEmpty ? nil : draftNote,
                    colorTier: draftColorTier?.domain
                )
            )
        } catch {
            self.error = String(describing: error)
        }
    }
}
