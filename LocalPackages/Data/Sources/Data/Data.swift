// Data — Domain Repository 프로토콜 구현 + 외부 SDK 어댑터.
// 의존: Core, Domain (+ Phase 3에서 Firebase / GoogleMaps SDK).
// Feature/* import 금지. DesignSystem import 금지.
//
// Phase 3에서 채울 항목:
// - Repositories/FirebaseStoreRepository.swift
// - Repositories/FirebaseAuthRepository.swift
// - DataSources/FirestoreStoreDataSource.swift
// - DataSources/GoogleMapsPlacesDataSource.swift
// - DataSources/AdMobAdDataSource.swift
// - DTOs/StoreDTO.swift
// - HTTPClient/URLSessionHTTPClient.swift

import Core
import Domain
import Foundation

public enum Data {
    public static let version: String = "0.1.0"
}

/// URLSession 기반 HTTPClient 구현. Core의 프로토콜을 준수.
public struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> (Foundation.Data, URLResponse) {
        try await session.data(for: request)
    }
}
