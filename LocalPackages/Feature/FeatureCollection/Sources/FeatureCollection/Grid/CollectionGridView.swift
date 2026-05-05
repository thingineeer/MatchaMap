import SwiftUI
import Domain
import DesignSystem

/// 도감 그리드 — handoff-mapping §13 + screens.md C1 정합.
/// LazyVGrid 3컬럼 + prefetch (loadMoreIfNeeded). 250+ 항목 60fps 목표.
public struct CollectionGridView: View {
    @Bindable private var viewModel: CollectionGridViewModel
    /// 보상형 광고 잠금 해제 핸들러 — FeatureMonetize composition root에서 주입.
    /// 시그니처는 SwiftUI Button action 표준(`() -> Void`). Composition Root에서
    /// `Task { @MainActor in await rewardedAdCoordinator.showRewardedAd(...) }`
    /// 패턴으로 wrap (ios-lead 합의 2026-05-04 옵션 A).
    private let onRequestUnlock: () -> Void

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: MMSpacing.sm),
        GridItem(.flexible(), spacing: MMSpacing.sm),
        GridItem(.flexible(), spacing: MMSpacing.sm)
    ]

    public init(viewModel: CollectionGridViewModel, onRequestUnlock: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onRequestUnlock = onRequestUnlock
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: MMSpacing.sm) {
                ForEach(viewModel.items) { item in
                    CollectionCardView(item: item)
                        .task {
                            await viewModel.loadMoreIfNeeded(currentItem: item)
                        }
                }
                ForEach(0..<lockedSlotCount, id: \.self) { _ in
                    LockedCollectionSlotView(onTap: onRequestUnlock)
                }
            }
            .padding(.horizontal, MMSpacing.md)
        }
        .background(Color.MM.bg)
        .task { await viewModel.loadInitial() }
        .refreshable { await viewModel.refresh() }
    }

    /// 도감 잠금 슬롯 표시 — 사용자별 unlockedSlots 만큼 차감 (보상형 광고로 늘어남).
    /// MVP: 보유 < 6이면 부족분만큼 잠금 슬롯 표시 (사용자에게 "수집 여지" 시각화).
    private var lockedSlotCount: Int {
        let target = max(6, viewModel.items.count + 3)
        let visible = viewModel.items.count + viewModel.unlockedSlots
        return max(0, target - visible)
    }
}

// MARK: - Card

struct CollectionCardView: View {
    let item: CollectionItem

    var body: some View {
        VStack(spacing: MMSpacing.xs) {
            ZStack {
                RoundedRectangle(cornerRadius: MMRadius.lg)
                    .fill(colorTierBg)
                    .aspectRatio(1, contentMode: .fit)
                if item.viaReview {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.MM.gold)
                        .padding(MMSpacing.xs)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            Text(item.store.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.MM.deep)
                .lineLimit(1)
            if let region = item.originRegion, region != .unknown, region != .other {
                Text(region.rawValue.uppercased())
                    .font(.system(size: 9, weight: .medium))
                    .tracking(0.2)
                    .foregroundStyle(Color.MM.muted)
            }
        }
    }

    private var colorTierBg: Color {
        guard let tier = item.colorTier else { return Color.MM.matchaPale }
        return Color.MM.matchaTier(tier.dsTier)
    }
}

// MARK: - Locked Slot (보상형 광고 unlock)

struct LockedCollectionSlotView: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: MMRadius.lg)
                    .fill(Color.MM.cream)
                    .aspectRatio(1, contentMode: .fit)
                VStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.MM.muted)
                    Text("UNLOCK")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(0.2)
                        .foregroundStyle(Color.MM.muted)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
