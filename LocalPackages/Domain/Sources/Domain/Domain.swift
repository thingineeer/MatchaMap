// Domain — 비즈니스 로직 계층의 엔트리.
// 외부 의존성 0. Foundation은 값 타입(Date, UUID)에 한해 사용.
//
// 본 파일은 모듈 진입점. 실제 타입은 하위 디렉토리에:
// - Entities/        값 타입 엔티티(Store, Review, ...)
// - Repositories/    저장소 프로토콜(StoreRepository, ...)
// - UseCases/        UseCase 프로토콜 + 기본 구현
// - Errors/          MMDomainError
// - Testing/         #DEBUG 한정 mock/fixture (Preview에서 재사용)

public enum Domain {
    /// SemVer aligned with module manifest. Increment on breaking API change.
    public static let version: String = "0.1.0"
}
