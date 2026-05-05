import SwiftUI
import Domain
import DesignSystem

/// 리뷰 작성 화면 — handoff-mapping.md 화면 10.
/// 별점 + 본문 + 태그 + 음료 + 사진 (max 5).
public struct ReviewWriteView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var viewModel: ReviewWriteViewModel
    @State private var showErrorAlert: Bool = false
    @State private var alertMessage: String = ""

    public init(viewModel: ReviewWriteViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MMSpacing.xl) {
                    ratingSection
                    drinkSection
                    bodySection
                    tagsSection
                    photoSection
                }
                .padding(MMSpacing.md)
            }
            .background(Color.MM.bg)
            .navigationTitle("리뷰 작성")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundStyle(Color.MM.muted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("등록") {
                        Task {
                            await viewModel.submit()
                            handleSubmissionResult()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.canSubmit ? Color.MM.deep : Color.MM.muted)
                    .disabled(!viewModel.canSubmit || viewModel.submission.isLoading)
                }
            }
            .overlay {
                if viewModel.submission.isLoading {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView("등록 중…")
                            .padding(MMSpacing.lg)
                            .background(Color.MM.paper, in: RoundedRectangle(cornerRadius: MMRadius.lg))
                    }
                }
            }
            .alert("리뷰 등록 실패", isPresented: $showErrorAlert) {
                Button("다시 시도") {
                    Task {
                        await viewModel.submit()
                        handleSubmissionResult()
                    }
                }
                Button("닫기", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func handleSubmissionResult() {
        switch viewModel.submission {
        case .loaded:
            dismiss()
        case .failed(let err):
            alertMessage = String(describing: err)
            showErrorAlert = true
        default:
            if let v = viewModel.validationError {
                alertMessage = String(describing: v)
                showErrorAlert = true
            }
        }
    }

    // MARK: - Rating

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: MMSpacing.sm) {
            sectionLabel("별점")
            HStack(spacing: MMSpacing.xs) {
                ForEach(1...5, id: \.self) { i in
                    Button {
                        withAnimation(MMMotion.fast) { viewModel.rating = i }
                    } label: {
                        Image(systemName: i <= viewModel.rating ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundStyle(i <= viewModel.rating ? Color.MM.gold : Color.MM.mutedSoft)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Drink

    private var drinkSection: some View {
        VStack(alignment: .leading, spacing: MMSpacing.sm) {
            sectionLabel("음료")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MMSpacing.xs) {
                    ForEach(ReviewDrink.allCases, id: \.self) { drink in
                        let isOn = viewModel.drink == drink
                        Button {
                            viewModel.drink = isOn ? nil : drink
                        } label: {
                            Text(drinkLabel(drink))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(isOn ? Color.MM.paper : Color.MM.deep)
                                .padding(.horizontal, MMSpacing.sm)
                                .padding(.vertical, MMSpacing.xs)
                                .background(isOn ? Color.MM.deep : Color.MM.cream, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
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

    // MARK: - Body

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: MMSpacing.sm) {
            sectionLabel("후기")
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: MMRadius.lg)
                    .strokeBorder(Color.MM.lineSoft, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: MMRadius.lg).fill(Color.MM.paper)
                    )
                if viewModel.body.isEmpty {
                    Text("이 매장의 말차는 어땠나요?")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.MM.mutedSoft)
                        .padding(.horizontal, MMSpacing.md)
                        .padding(.top, MMSpacing.sm + 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.body)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.MM.text)
                    .padding(MMSpacing.xs)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 140)
            }
        }
    }

    // MARK: - Tags

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: MMSpacing.sm) {
            sectionLabel("태그")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MMSpacing.xs) {
                    ForEach(ReviewTag.allCases, id: \.self) { tag in
                        let isOn = viewModel.tags.contains(tag)
                        Button {
                            viewModel.toggleTag(tag)
                        } label: {
                            Text(tag.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(isOn ? Color.MM.paper : Color.MM.deep)
                                .padding(.horizontal, MMSpacing.sm)
                                .padding(.vertical, MMSpacing.xs)
                                .background(isOn ? Color.MM.matcha : Color.MM.matchaPale, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Photos

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: MMSpacing.sm) {
            sectionLabel("사진 (\(viewModel.photos.count)/\(ReviewWriteViewModel.photoMax))")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MMSpacing.xs) {
                    ForEach(viewModel.photos) { slot in
                        photoSlotView(slot)
                    }
                    if viewModel.photos.count < ReviewWriteViewModel.photoMax {
                        addPhotoButton
                    }
                }
            }
            Text("사진 첨부는 Phase 4에서 PhotosPicker로 활성화돼요.")
                .font(.system(size: 11))
                .foregroundStyle(Color.MM.muted)
        }
    }

    private func photoSlotView(_ slot: ReviewWriteViewModel.PhotoSlot) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: MMRadius.md)
                .fill(Color.MM.matchaPale)
                .frame(width: 96, height: 96)
                .overlay(slotStatusOverlay(slot))
            Button {
                viewModel.removePhoto(id: slot.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.MM.deep)
                    .background(Circle().fill(Color.MM.paper))
            }
            .buttonStyle(.plain)
            .padding(4)
        }
    }

    @ViewBuilder
    private func slotStatusOverlay(_ slot: ReviewWriteViewModel.PhotoSlot) -> some View {
        switch slot.status {
        case .pending:
            Image(systemName: "photo.fill")
                .font(.system(size: 24))
                .foregroundStyle(Color.MM.muted)
        case .uploading:
            ProgressView().tint(Color.MM.deep)
        case .uploaded:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.MM.matcha)
        case .failed:
            Button {
                Task { await viewModel.retryPhoto(id: slot.id) }
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 18))
                    Text("재시도")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(Color.MM.rose)
            }
            .buttonStyle(.plain)
        }
    }

    private var addPhotoButton: some View {
        Button {
            // Phase 4: PhotosPicker. MVP placeholder — empty data로 슬롯 추가하지 않음.
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .medium))
                Text("추가")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(Color.MM.muted)
            .frame(width: 96, height: 96)
            .background(Color.MM.cream, in: RoundedRectangle(cornerRadius: MMRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: MMRadius.md)
                    .strokeBorder(Color.MM.lineSoft, style: StrokeStyle(lineWidth: 1, dash: [3]))
            )
        }
        .buttonStyle(.plain)
        .disabled(true)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.MM.deep)
    }
}
