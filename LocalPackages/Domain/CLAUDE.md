# LocalPackages/Domain

> **외부 의존 0**. Foundation도 값 타입(Date, UUID)에 한해 사용.
> 비즈니스 로직의 단일 진실 원천.

## 책임

- **Entities** (값 타입): `Store`, `Review`, `User`, `Friend`, `Wishlist`, `CollectionEntry`, `Coordinate`, `BoundingBox`.
- **Repository protocol**: `StoreRepository`, `ReviewRepository`, `AuthRepository`, ...
- **UseCase**: `GetStoreDetailsUseCase`, `SearchStoresInBoundsUseCase`, `RegisterStoreToCollectionUseCase`, ...
- **Domain Error**: `MMDomainError`.
- **Testing**: Preview/Test 양쪽에서 재사용하는 Mock + fixture.

## 금지

- SwiftUI / Combine / Firebase / GoogleMaps / URLSession.
- `import Core` (인프라 관심사) — 표준 프로토콜(Sendable 등)만 활용.
- `import Data` 또는 `Feature/*` (역참조 금지).

## TDD 사이클

ADR-003 §1. 모든 신규 UseCase/Entity 메서드는:
1. Tests/DomainTests에 실패 테스트 추가 → `swift test`로 빨간색 확인.
2. Sources/Domain에 최소 구현 → 통과.
3. 리팩터.

## Public API 규약

- 모든 타입 `Sendable` + `Hashable`(가능한 경우) + `Codable`(영속화 가능한 값 타입만).
- Repository는 `protocol`이며 `Sendable`.
- UseCase는 `callAsFunction(...)` 단일 진입점.

## 테스트

`cd LocalPackages/Domain && swift test`.
- 0.1초 이내 실행 보장.
- SDK·UI·네트워크 무관.
