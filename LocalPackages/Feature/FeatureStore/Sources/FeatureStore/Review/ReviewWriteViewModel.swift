import Foundation
import Observation
import Domain

/// 리뷰 작성 화면 (handoff-mapping.md 화면 10) ViewModel.
/// - 별점 1~5 정수, 사진 0~5장(시안), 본문, 태그, 음료 종류
/// - 사진 업로드 큐: 개별 사진 단위 재시도 (ios-store agent §에러 3)
/// - 네트워크 끊김 시 로컬 임시 저장 — `localDrafts` 스냅샷으로 보관
@MainActor
@Observable
public final class ReviewWriteViewModel {

    // MARK: - Photo state

    public struct PhotoSlot: Identifiable, Sendable, Hashable {
        public enum Status: Sendable, Hashable {
            case pending          // 사용자가 선택한 직후 (업로드 대기)
            case uploading
            case uploaded(URL)
            case failed(String)   // 사용자에게 표시할 에러 사유
        }

        public let id: UUID
        public let data: Data
        public let fileName: String
        public var status: Status

        public init(id: UUID = UUID(), data: Data, fileName: String, status: Status = .pending) {
            self.id = id
            self.data = data
            self.fileName = fileName
            self.status = status
        }

        public var uploadedURL: URL? {
            if case .uploaded(let u) = status { return u }
            return nil
        }
    }

    // MARK: - Form state
    public let storeId: String
    public var rating: Int = 0           // 0 = 미입력
    public var body: String = ""
    public var tags: Set<ReviewTag> = []
    public var drink: ReviewDrink? = nil
    public private(set) var photos: [PhotoSlot] = []

    // MARK: - Submission state
    public private(set) var submission: LoadState<String> = .idle  // payload = reviewId
    public private(set) var validationError: MMDomainError?

    // MARK: - Limits (시안 화면 10 grid: 사용자 표시 max 5장; schema 강제 max 4 — UI는 5표시이고 enforce는 schema)
    public static let photoMax = 5

    // MARK: - Deps
    private let writeReview: any WriteReviewUseCase
    private let uploader: any PhotoUploader

    /// ADR-304 — 게스트면 submit 차단 + 콜백.
    private var authState: AuthState

    /// ADR-304 — 게스트가 작성/제출 시도 시 UI에 로그인 시트 요청.
    public var onRequireLogin: ((LoginGate) -> Void)?

    public init(
        storeId: String,
        writeReview: any WriteReviewUseCase,
        uploader: any PhotoUploader,
        authState: AuthState = .authenticated(.fixture())
    ) {
        self.storeId = storeId
        self.writeReview = writeReview
        self.uploader = uploader
        self.authState = authState
    }

    public func updateAuthState(_ newValue: AuthState) {
        self.authState = newValue
    }

    /// FeatureStore가 Domain의 LoginIntent에 의존하지 않도록 별도 라벨 정의(컴포지션 루트가 매핑).
    public enum LoginGate: String, Sendable, Hashable {
        case review
    }

    // MARK: - Photo intents

    public func addPhoto(data: Data, fileName: String) {
        guard photos.count < Self.photoMax else { return }
        photos.append(PhotoSlot(data: data, fileName: fileName))
    }

    public func removePhoto(id: UUID) {
        photos.removeAll { $0.id == id }
    }

    public func toggleTag(_ tag: ReviewTag) {
        if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
    }

    /// 모든 pending/failed 사진 업로드 시도. 실패는 슬롯 단위로 status에 기록.
    public func uploadPendingPhotos() async {
        for index in photos.indices {
            let slot = photos[index]
            switch slot.status {
            case .uploaded, .uploading:
                continue
            case .pending, .failed:
                photos[index].status = .uploading
                do {
                    let url = try await uploader.upload(localData: slot.data, fileName: slot.fileName)
                    photos[index].status = .uploaded(url)
                } catch {
                    photos[index].status = .failed(String(describing: error))
                }
            }
        }
    }

    /// 단일 슬롯 재시도.
    public func retryPhoto(id: UUID) async {
        guard let index = photos.firstIndex(where: { $0.id == id }) else { return }
        let slot = photos[index]
        photos[index].status = .uploading
        do {
            let url = try await uploader.upload(localData: slot.data, fileName: slot.fileName)
            photos[index].status = .uploaded(url)
        } catch {
            photos[index].status = .failed(String(describing: error))
        }
    }

    // MARK: - Validation / Submit

    /// 등록 버튼 활성화 — 별점 ≥ 1 AND 본문 trimmed 비어있지 않음 + 정식 인증.
    /// ADR-304: 게스트는 작성 자체는 가능하나 submit 시점에 차단 → 버튼은 비활성화로 시각화.
    public var canSubmit: Bool {
        rating >= 1
            && !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && authState.isAuthenticated
    }

    /// 게스트가 리뷰 화면에 들어왔는가 — UI에서 로그인 CTA 카드 노출 분기.
    public var isGuestBlocked: Bool {
        authState.isGuest
    }

    /// 사진 업로드가 모두 완료되었는가? (failed/pending이 1건도 없어야 submit 가능)
    public var photosReady: Bool {
        photos.allSatisfy { if case .uploaded = $0.status { return true } else { return false } }
    }

    /// 등록. 사진 미업로드 시 자동으로 uploadPendingPhotos 호출 후 진행.
    /// ADR-304: 게스트면 onRequireLogin(.review) 발화 후 즉시 리턴.
    public func submit() async {
        validationError = nil
        if authState.isGuest {
            onRequireLogin?(.review)
            return
        }
        guard canSubmit else {
            validationError = .invalidInput(rating < 1 ? "rating" : "body")
            return
        }
        submission = .loading

        await uploadPendingPhotos()
        // 일부 사진 실패 시 사용자에게 알림(submission은 idle로 복귀, validationError 세팅)
        let uploadedURLs = photos.compactMap(\.uploadedURL)
        if uploadedURLs.count != photos.count {
            submission = .idle
            validationError = .network("photo_upload_partial")
            return
        }

        let draft = ReviewDraft(
            storeId: storeId,
            rating: rating,
            body: body,
            photos: uploadedURLs,
            tags: Array(tags),
            drink: drink
        )

        do {
            let reviewId = try await writeReview(draft)
            submission = .loaded(reviewId)
        } catch {
            submission = .failed(mmError(error))
        }
    }

    /// 폼 직렬화 — 네트워크 끊김 시 사용자 입력을 보관(ios-store agent §에러 2).
    public func snapshot() -> ReviewDraftSnapshot {
        ReviewDraftSnapshot(
            storeId: storeId,
            rating: rating,
            body: body,
            tags: Array(tags),
            drink: drink,
            uploadedPhotoURLs: photos.compactMap(\.uploadedURL)
        )
    }

    public func restore(from snapshot: ReviewDraftSnapshot) {
        rating = snapshot.rating
        body = snapshot.body
        tags = Set(snapshot.tags)
        drink = snapshot.drink
        // 업로드 완료된 URL은 dummy slot으로 재구성 (data 없음 — 추가 사진은 재선택 필요)
        photos = snapshot.uploadedPhotoURLs.enumerated().map { idx, url in
            PhotoSlot(data: Data(), fileName: "restored-\(idx)", status: .uploaded(url))
        }
    }
}

/// 입력 상태 보관용 직렬화 모델 — 네트워크 끊김 등 시 로컬 저장 (UserDefaults/Disk).
public struct ReviewDraftSnapshot: Sendable, Codable, Hashable {
    public let storeId: String
    public let rating: Int
    public let body: String
    public let tags: [ReviewTag]
    public let drink: ReviewDrink?
    public let uploadedPhotoURLs: [URL]

    public init(
        storeId: String,
        rating: Int,
        body: String,
        tags: [ReviewTag],
        drink: ReviewDrink?,
        uploadedPhotoURLs: [URL]
    ) {
        self.storeId = storeId
        self.rating = rating
        self.body = body
        self.tags = tags
        self.drink = drink
        self.uploadedPhotoURLs = uploadedPhotoURLs
    }
}
