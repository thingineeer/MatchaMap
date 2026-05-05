import SwiftUI
import Domain
import DesignSystem

/// 검색 필터 모달 — handoff-mapping.md 화면 9 + Domain.StoreSearchFilters 편집.
public struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let initial: StoreSearchFilters
    private let onApply: (StoreSearchFilters) -> Void

    @State private var pinTiers: Set<StorePinTier>
    @State private var drinks: Set<ReviewDrink>
    @State private var priceLevels: Set<Int>
    @State private var openNow: Bool
    @State private var maxDistanceKM: Double

    public init(initial: StoreSearchFilters, onApply: @escaping (StoreSearchFilters) -> Void) {
        self.initial = initial
        self.onApply = onApply
        _pinTiers = State(initialValue: initial.pinTiers)
        _drinks = State(initialValue: initial.drinks)
        _priceLevels = State(initialValue: initial.priceLevels)
        _openNow = State(initialValue: initial.openNow)
        _maxDistanceKM = State(initialValue: (initial.maxDistanceMeters ?? 5000) / 1000)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MMSpacing.xl) {
                    section("등급") {
                        chipRow(
                            items: StorePinTier.allCases,
                            isSelected: { pinTiers.contains($0) },
                            label: { $0.rawValue },
                            onTap: { tier in
                                if pinTiers.contains(tier) { pinTiers.remove(tier) }
                                else { pinTiers.insert(tier) }
                            }
                        )
                    }
                    section("음료 종류") {
                        chipRow(
                            items: ReviewDrink.allCases,
                            isSelected: { drinks.contains($0) },
                            label: { drinkLabel($0) },
                            onTap: { d in
                                if drinks.contains(d) { drinks.remove(d) }
                                else { drinks.insert(d) }
                            }
                        )
                    }
                    section("가격대") {
                        chipRow(
                            items: [1, 2, 3, 4],
                            isSelected: { priceLevels.contains($0) },
                            label: { String(repeating: "₩", count: $0) },
                            onTap: { p in
                                if priceLevels.contains(p) { priceLevels.remove(p) }
                                else { priceLevels.insert(p) }
                            }
                        )
                    }
                    section("거리 (\(Int(maxDistanceKM)) km)") {
                        Slider(value: $maxDistanceKM, in: 1...50, step: 1)
                            .tint(Color.MM.deep)
                    }
                    section("영업중") {
                        Toggle("지금 영업중인 매장만", isOn: $openNow)
                            .toggleStyle(.switch)
                            .tint(Color.MM.deep)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.MM.deep)
                    }
                }
                .padding(MMSpacing.md)
            }
            .background(Color.MM.bg)
            .navigationTitle("필터")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("초기화") {
                        pinTiers = []
                        drinks = []
                        priceLevels = []
                        openNow = false
                        maxDistanceKM = 5
                    }
                    .foregroundStyle(Color.MM.muted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("적용") {
                        let next = StoreSearchFilters(
                            pinTiers: pinTiers,
                            drinks: drinks,
                            priceLevels: priceLevels,
                            maxDistanceMeters: maxDistanceKM * 1000,
                            openNow: openNow
                        )
                        onApply(next)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.MM.deep)
                }
            }
        }
    }

    @ViewBuilder
    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: MMSpacing.sm) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.MM.deep)
            content()
        }
    }

    private func chipRow<T: Hashable>(
        items: [T],
        isSelected: @escaping (T) -> Bool,
        label: @escaping (T) -> String,
        onTap: @escaping (T) -> Void
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MMSpacing.xs) {
                ForEach(items, id: \.self) { item in
                    let selected = isSelected(item)
                    Button {
                        onTap(item)
                    } label: {
                        Text(label(item))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(selected ? Color.MM.paper : Color.MM.deep)
                            .padding(.horizontal, MMSpacing.sm)
                            .padding(.vertical, MMSpacing.xs)
                            .background(selected ? Color.MM.deep : Color.MM.cream, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func drinkLabel(_ d: ReviewDrink) -> String {
        switch d {
        case .usucha:      return "우스차"
        case .koicha:      return "코이차"
        case .matchaLatte: return "라떼"
        case .icedMatcha:  return "아이스"
        case .dessert:     return "디저트"
        case .other:       return "기타"
        }
    }
}
