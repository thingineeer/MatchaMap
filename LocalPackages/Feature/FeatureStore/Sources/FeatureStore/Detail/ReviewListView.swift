import SwiftUI
import Domain
import DesignSystem

/// 리뷰 리스트 — handoff-mapping 화면 8 정렬 segmented + 카드 리스트.
/// StoreDetailViewModel을 공유 (sort 상태 + reviews LoadState).
public struct ReviewListView: View {
    @Bindable private var viewModel: StoreDetailViewModel

    public init(viewModel: StoreDetailViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MMSpacing.md) {
            sortPicker
            content
        }
    }

    private var sortPicker: some View {
        HStack(spacing: 0) {
            ForEach(ReviewSortOrder.allCases, id: \.self) { sort in
                Button {
                    Task { await viewModel.selectSort(sort) }
                } label: {
                    Text(sortLabel(sort))
                        .font(.system(size: 12, weight: viewModel.sort == sort ? .semibold : .medium))
                        .foregroundStyle(viewModel.sort == sort ? Color.MM.paper : Color.MM.muted)
                        .padding(.vertical, MMSpacing.xs)
                        .frame(maxWidth: .infinity)
                        .background(viewModel.sort == sort ? Color.MM.deep : Color.MM.cream)
                }
                .buttonStyle(.plain)
            }
        }
        .clipShape(Capsule())
    }

    private func sortLabel(_ sort: ReviewSortOrder) -> String {
        switch sort {
        case .latest:  return "최신순"
        case .rating:  return "별점순"
        case .helpful: return "도움순"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.reviews {
        case .idle, .loading:
            VStack(spacing: MMSpacing.md) {
                ForEach(0..<3, id: \.self) { _ in skeletonCard }
            }
        case .loaded(let page):
            if page.items.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: MMSpacing.md) {
                    ForEach(page.items, id: \.id) { review in
                        reviewCard(review)
                    }
                }
            }
        case .failed(let err):
            VStack(spacing: MMSpacing.sm) {
                Text("리뷰를 불러오지 못했어요")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.MM.deep)
                Text(String(describing: err))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.MM.muted)
                Button("다시 시도") {
                    Task { await viewModel.retry() }
                }
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, MMSpacing.lg)
                .padding(.vertical, MMSpacing.xs)
                .foregroundStyle(Color.MM.paper)
                .background(Color.MM.deep, in: Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(MMSpacing.lg)
        }
    }

    private func reviewCard(_ review: Review) -> some View {
        VStack(alignment: .leading, spacing: MMSpacing.sm) {
            HStack(spacing: MMSpacing.xs) {
                Circle()
                    .fill(Color.MM.matchaSoft)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(review.author.displayName.prefix(1).uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.MM.paper)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.author.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.MM.deep)
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: i < review.rating ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.MM.gold)
                        }
                    }
                }
                Spacer()
            }
            Text(review.body)
                .font(.system(size: 13))
                .foregroundStyle(Color.MM.text)
                .lineSpacing(2)
            if !review.photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MMSpacing.xs) {
                        ForEach(review.photos, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: MMRadius.md)
                                .fill(Color.MM.matchaPale)
                                .frame(width: 96, height: 96)
                        }
                    }
                }
            }
            if !review.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MMSpacing.xxs) {
                        ForEach(review.tags, id: \.self) { tag in
                            Text(tag.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.MM.deep)
                                .padding(.horizontal, MMSpacing.xs)
                                .padding(.vertical, 2)
                                .background(Color.MM.matchaPale, in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(MMSpacing.md)
        .background(Color.MM.paper)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: MMRadius.xl)
                .strokeBorder(Color.MM.lineSoft, lineWidth: 1)
        )
    }

    private var skeletonCard: some View {
        VStack(alignment: .leading, spacing: MMSpacing.xs) {
            Capsule().fill(Color.MM.lineSoft).frame(width: 110, height: 12)
            Capsule().fill(Color.MM.lineSoft).frame(maxWidth: .infinity, maxHeight: 12)
            Capsule().fill(Color.MM.lineSoft).frame(width: 200, height: 12)
        }
        .padding(MMSpacing.md)
        .background(Color.MM.paper)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.xl))
        .redacted(reason: .placeholder)
    }

    private var emptyState: some View {
        VStack(spacing: MMSpacing.sm) {
            Image(systemName: "text.quote")
                .font(.system(size: 28))
                .foregroundStyle(Color.MM.muted)
            Text("아직 리뷰가 없어요")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.MM.deep)
            Text("이 매장의 첫 리뷰를 남겨보세요.")
                .font(.system(size: 11))
                .foregroundStyle(Color.MM.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(MMSpacing.xl)
    }
}
