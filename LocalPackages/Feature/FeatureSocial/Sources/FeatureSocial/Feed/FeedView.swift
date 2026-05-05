import SwiftUI
import Domain
import DesignSystem

/// 친구 피드 화면 — handoff-mapping §11 (Stories 미포함, MVP).
/// 옵티미스틱 좋아요/댓글 + 무한 스크롤 cursor pagination.
public struct FeedView: View {
    @Bindable private var viewModel: FeedViewModel

    public init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: MMSpacing.md) {
                ForEach(viewModel.events) { event in
                    FeedPostCard(event: event, viewModel: viewModel)
                        .task {
                            await viewModel.loadMoreIfNeeded(currentEvent: event)
                        }
                }
                if viewModel.isLoading && viewModel.events.isEmpty {
                    ProgressView()
                        .padding(.top, MMSpacing.xl)
                }
            }
            .padding(.horizontal, MMSpacing.md)
            .padding(.vertical, MMSpacing.md)
        }
        .background(Color.MM.bg)
        .task { await viewModel.loadInitial() }
        .refreshable { await viewModel.refresh() }
    }
}

struct FeedPostCard: View {
    let event: FeedEvent
    @Bindable var viewModel: FeedViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: MMSpacing.sm) {
            actorHeader
            payloadBody
            actionsRow
        }
        .padding(MMSpacing.md)
        .background(Color.MM.paper)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: MMRadius.xl)
                .strokeBorder(Color.MM.lineSoft, lineWidth: 1)
        )
    }

    private var actorHeader: some View {
        HStack(spacing: MMSpacing.sm) {
            Circle()
                .fill(LinearGradient(colors: [Color.MM.matcha, Color.MM.rose], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(event.actor.displayName.prefix(1).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.MM.paper)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(event.actor.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.MM.deep)
                Text(eventVerb)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.MM.muted)
            }
            Spacer()
            Text(relativeTime)
                .font(.system(size: 10, weight: .medium))
                .tracking(0.2)
                .foregroundStyle(Color.MM.muted)
        }
    }

    @ViewBuilder
    private var payloadBody: some View {
        switch event.payload {
        case .review(let rating, let bodyExcerpt, _):
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < rating ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.MM.gold)
                    }
                }
                Text(bodyExcerpt)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.MM.text)
                    .lineLimit(3)
            }
        case .collection(let drink, let grade, _):
            HStack(spacing: MMSpacing.xs) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.MM.matcha)
                Text("\(drink.rawValue.replacingOccurrences(of: "_", with: " "))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.MM.deep)
                if let grade {
                    Text("· \(grade.rawValue)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.MM.muted)
                }
            }
        case .checkin(let note):
            Text(note ?? "체크인했습니다")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.MM.text)
        case .friendAdded:
            Text("새로운 친구를 추가했어요")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.MM.text)
        case .none:
            EmptyView()
        }
    }

    private var actionsRow: some View {
        let targetId = event.target.targetId
        let liked = viewModel.isLiked(targetId: targetId)
        let count = viewModel.likeCount(targetId: targetId)
        let comments = viewModel.comments(targetId: targetId)
        return HStack(spacing: MMSpacing.lg) {
            Button {
                Task { await viewModel.toggleLike(target: event) }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: liked ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(liked ? Color.MM.rose : Color.MM.muted)
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.MM.muted)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(liked ? "Unlike" : "Like")

            HStack(spacing: 4) {
                Image(systemName: "bubble.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.MM.muted)
                if !comments.isEmpty {
                    Text("\(comments.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.MM.muted)
                }
            }
            Spacer()
        }
    }

    private var eventVerb: String {
        switch event.type {
        case .collection: return "도감에 추가했어요"
        case .review:     return "리뷰를 남겼어요"
        case .checkin:    return "체크인했어요"
        case .friendAdded: return "친구가 됐어요"
        }
    }

    private var relativeTime: String {
        let interval = Date().timeIntervalSince(event.createdAt)
        if interval < 60 { return "지금" }
        if interval < 3600 { return "\(Int(interval/60))M" }
        if interval < 86400 { return "\(Int(interval/3600))H" }
        return "\(Int(interval/86400))D"
    }
}
