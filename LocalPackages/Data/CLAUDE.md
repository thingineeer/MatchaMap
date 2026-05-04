# LocalPackages/Data

> Domain Repository 프로토콜의 **구현체** + 외부 SDK 어댑터.

## 책임

- Domain Repository **구현**:
  - `FirebaseStoreRepository`, `FirebaseReviewRepository`, `FirebaseAuthRepository`, ...
- DTO ↔ Domain Entity 매핑 (`StoreDTO`, `ReviewDTO`).
- DataSource:
  - `FirestoreStoreDataSource` (Firestore 쿼리 캡슐화)
  - `GoogleMapsPlacesDataSource` (Google Places SDK)
  - `AdMobAdDataSource` (광고 슬롯 로드)
- HTTPClient 구현 (`URLSessionHTTPClient: HTTPClient`).

## 의존

- 내부: `Core`, `Domain`.
- 외부 (Phase 3 활성화): `firebase-ios-sdk`, `ios-maps-sdk`, `ios-places-sdk`.

## 금지

- `import Feature/*` (역참조 금지).
- `import DesignSystem` (UI 무관).

## Public API 규약

- Repository 구현체는 `final class` + `Sendable` (또는 `@unchecked Sendable` + actor 격리 명시).
- 이니셜라이저는 모든 의존을 인자로 받는다 (DI 강제).
- 실제 Firebase 인스턴스는 Composition Root에서 주입.

## 테스트

- DTO 매핑 단위 테스트 (`Tests/DataTests/DTOs/...`).
- Repository는 fake DataSource로 테스트 (Firebase emulator는 Phase 3+에서 검토).
