import Foundation
import FirebaseCore
import FirebaseFirestore

/// asia-northeast3 region Firestore + 옵션으로 emulator 분기.
/// 본 클라이언트는 stateless wrapper — 실 read/write는 각 Repository가 collection path를 받아 수행.
public final class FirestoreClient: @unchecked Sendable {

    public static let regionAsiaNortheast3 = "asia-northeast3"

    public let firestore: Firestore

    public init(useEmulator: Bool = false, emulatorHost: String = "127.0.0.1", emulatorPort: Int = 8080) {
        let db = Firestore.firestore()
        if useEmulator {
            let settings = db.settings
            settings.host = "\(emulatorHost):\(emulatorPort)"
            settings.cacheSettings = MemoryCacheSettings()
            settings.isSSLEnabled = false
            db.settings = settings
        }
        self.firestore = db
    }
}
