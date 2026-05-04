public enum MMDomainError: Error, Sendable, Hashable {
    case notFound
    case unauthorized
    case permissionDenied
    case network(String)
    case invalidInput(String)
    case unknown(String)
}
