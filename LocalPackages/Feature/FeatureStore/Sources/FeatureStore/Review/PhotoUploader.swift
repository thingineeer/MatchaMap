import Foundation

/// 사진 업로드 단일 작업 — Storage 경로(`reviews/{reviewId}/{n}.jpg`) 또는 가공된 URL 반환.
/// Phase 3에서 Data 모듈의 FirebaseStoragePhotoUploader가 이 프로토콜로 등록.
public protocol PhotoUploader: Sendable {
    /// `localData`를 업로드하고 원격 URL 반환.
    /// - Throws: 네트워크 끊김 등 임의 에러. 호출자(ReviewWriteViewModel)가 재시도 큐에 보관.
    func upload(localData: Data, fileName: String) async throws -> URL
}
