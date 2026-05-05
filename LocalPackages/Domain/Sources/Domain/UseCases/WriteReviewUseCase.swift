import Foundation

public protocol WriteReviewUseCase: Sendable {
    @discardableResult
    func callAsFunction(_ draft: ReviewDraft) async throws -> String
}

public struct WriteReviewUseCaseImpl: WriteReviewUseCase {
    private let repository: ReviewRepository

    public init(repository: ReviewRepository) {
        self.repository = repository
    }

    @discardableResult
    public func callAsFunction(_ draft: ReviewDraft) async throws -> String {
        try Self.validate(draft)
        return try await repository.writeReview(draft)
    }

    /// schema.md §3.1 reviews 제약 정합:
    /// - storeId 필수
    /// - rating 1~5
    /// - body 1~2000 chars
    /// - photos 0~4 items (시안 화면 10은 5장 표시이나 schema는 0~4)
    ///   → 디자인 핸드오프-매핑 §10 "사진 max 9"는 클라 표시상 grid; schema enforce는 4. 본 enforcement는 schema 우선.
    /// - tags 0~8 items
    static func validate(_ draft: ReviewDraft) throws {
        if draft.storeId.isEmpty { throw MMDomainError.invalidInput("storeId") }
        if !(1...5).contains(draft.rating) { throw MMDomainError.invalidInput("rating") }
        let trimmed = draft.body.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { throw MMDomainError.invalidInput("body") }
        if trimmed.count > 2000 { throw MMDomainError.invalidInput("body") }
        if draft.photos.count > 4 { throw MMDomainError.invalidInput("photos") }
        if draft.tags.count > 8 { throw MMDomainError.invalidInput("tags") }
    }
}
