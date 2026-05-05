import Foundation
import FirebaseStorage

/// Firebase Storage wrapper — 실 업로드/다운로드 헬퍼.
/// 매장 사진/리뷰 이미지가 본 클라이언트를 거쳐감.
public final class FirebaseStorageClient: @unchecked Sendable {
    public let storage: Storage

    public init(bucket: String? = nil) {
        if let bucket {
            self.storage = Storage.storage(url: "gs://\(bucket)")
        } else {
            self.storage = Storage.storage()
        }
    }
}
