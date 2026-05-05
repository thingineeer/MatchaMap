import Foundation
import Domain

/// 화면 단위 비동기 로딩 상태. Skeleton + retry 정합 (ios-store agent §에러 핸들링 1).
public enum LoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case failed(MMDomainError)

    public var value: Value? {
        if case .loaded(let v) = self { return v }
        return nil
    }

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var error: MMDomainError? {
        if case .failed(let e) = self { return e }
        return nil
    }
}

extension LoadState: Equatable where Value: Equatable {}

/// MMDomainError가 아닌 일반 Error를 도메인 에러로 변환.
public func mmError(_ error: Error) -> MMDomainError {
    if let mm = error as? MMDomainError { return mm }
    return .unknown(String(describing: error))
}
