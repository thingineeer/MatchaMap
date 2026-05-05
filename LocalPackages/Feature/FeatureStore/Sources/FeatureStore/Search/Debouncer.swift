import Foundation

/// 디바운스 헬퍼 — Sendable closure를 N ms 후 1회만 실행.
/// 같은 actor 위에서만 사용한다고 가정(현재 호출자: @MainActor SearchViewModel).
@MainActor
final class Debouncer {

    private let interval: Duration
    private let sleeper: @Sendable (Duration) async throws -> Void
    private var pendingTask: Task<Void, Never>?

    init(
        milliseconds: Int,
        sleeper: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.interval = .milliseconds(milliseconds)
        self.sleeper = sleeper
    }

    /// 새 작업 예약. 기존 대기 중 작업은 취소.
    func schedule(_ work: @escaping @MainActor () async -> Void) {
        pendingTask?.cancel()
        let interval = self.interval
        let sleeper = self.sleeper
        pendingTask = Task { @MainActor in
            do {
                try await sleeper(interval)
            } catch {
                return // cancelled
            }
            if Task.isCancelled { return }
            await work()
        }
    }

    func cancel() {
        pendingTask?.cancel()
        pendingTask = nil
    }
}
