# ADR-001 — iOS 모듈 경계 (Clean Architecture)

- **일자**: 2026-05-04
- **상태**: Accepted (Phase 2)
- **결정자**: `ios-lead`
- **리뷰어**: `po-lead`(승인 대기), `designer-lead`, `server-lead`, `qa-lead`
- **관련 ADR**: ADR-002(DI), ADR-003(Test Strategy), ADR-301(Backend), CLAUDE.md §5.1

## 컨텍스트

말차맵 v1.0.0의 iOS 코드베이스를 단일 앱 타깃 안에 모두 두면 다음 문제가 발생한다:

1. **빌드 시간**: SwiftUI Preview · 단위 테스트 시 전체 타깃을 매번 빌드.
2. **의존 방향 무규율**: SDK(Firebase/GoogleMaps)를 어디서나 import 가능 → 도메인 로직과 통신 코드가 뒤엉킴.
3. **5인 동시 작업**: `ios-lead` 본인 + `ios-map`/`ios-auth-monetize`/`ios-store`/`ios-social-collection` 4명이 같은 타깃을 편집하면 머지 충돌과 빌드 깨짐 빈번.
4. **TDD 강제 곤란**: Domain UseCase를 테스트하려면 SDK 빌드가 매번 끼어듬.

## 결정

**LocalPackages 8개 모듈로 분리. 의존 방향은 한 방향 그래프(DAG)로 강제.**

```
                     ┌──────────────────────────┐
                     │    MatchaMap (App)       │
                     │  Composition Root        │
                     │  — MatchaMapApp.swift    │
                     └────────┬─────────────────┘
                              │ imports
        ┌──────────┬──────────┼──────────┬──────────┐
        ▼          ▼          ▼          ▼          ▼
  ┌─────────┐┌─────────┐┌─────────┐┌─────────┐┌──────────┐
  │FeatureMap││FeatureA-││FeatureSt││FeatureSo││FeatureCo-│   FeatureMonetize도 동일 레벨
  │         ││uth      ││ore      ││cial     ││llection  │
  └─┬───┬───┘└─┬───┬───┘└─┬───┬───┘└─┬───┬───┘└──┬───┬───┘
    │   │     │   │     │   │     │   │       │   │
    ▼   ▼     ▼   ▼     ▼   ▼     ▼   ▼       ▼   ▼
  ┌──────────┐                ┌─────────────────┐
  │  Domain  │ ◀──────────────│  DesignSystem   │
  │ (외부 0) │                │  (SwiftUI only) │
  └──────────┘                └─────────────────┘
        ▲
        │ implements
  ┌─────┴──────────────────────────────────────┐
  │              Data                           │
  │  (Firebase / GoogleMaps / GooglePlaces)    │
  └────────┬───────────────────────────────────┘
           │ uses
           ▼
       ┌────────┐
       │  Core  │  (Foundation / OSLog only)
       └────────┘
```

### 핵심 규칙 (DAG 위배 금지)

1. **`Domain`은 외부 0 의존**: Foundation도 최소(Date/UUID 등 값 타입만). 절대 SDK·UI·Combine·SwiftUI import 금지.
2. **`Feature/*`는 `Data`를 직접 import 금지**: `Domain`의 Repository/UseCase 프로토콜만 의존. 구현체는 Composition Root에서 주입.
3. **`Data`는 `Feature/*`를 import 금지**: 역참조 금지.
4. **`DesignSystem`은 `Domain`을 import 금지**: 역참조 금지. UI 토큰만.
5. **`Core`는 다른 LocalPackage를 import 금지**: 가장 아래 레이어.
6. **앱 타깃(`MatchaMap/`)만 모든 모듈을 import 가능**. 그 외에는 위 규칙 따름.

## 모듈 명세

### 1. `Core`
- **외부 의존**: `Foundation`, `OSLog`만.
- **내부 의존**: 없음 (다른 LocalPackage import 금지).
- **책임**:
  - `Logger` (OSLog 래퍼, subsystem `th1ngjin.MatchaMap`).
  - `AppEnvironment` (Bundle 정보, build number 헬퍼).
  - `Result` 확장, `Date` 헬퍼 등 단순 유틸.
  - 네트워크 추상 프로토콜(`HTTPClient` protocol)만 — 실제 URLSession 구현은 Data에.
- **금지**: SwiftUI / SDK / UIKit / Combine.
- **Public API 예시**:
  ```swift
  public protocol HTTPClient: Sendable {
      func send(_ request: URLRequest) async throws -> (Data, URLResponse)
  }
  public enum LogCategory: String, Sendable { case app, data, ui, analytics }
  public struct Logger: Sendable { public init(category: LogCategory) }
  ```

### 2. `DesignSystem`
- **외부 의존**: `SwiftUI`만 + Resource bundle(컬러/폰트/SVG 아이콘).
- **내부 의존**: 없음.
- **책임 — 토큰 SSOT (단일 진실 원천)**:
  - 디자인 토큰 6 카테고리는 본 모듈이 **단일 진실 원천**. 다른 어떤 모듈도 색상/폰트/스페이싱을 직접 정의하거나 리터럴로 사용할 수 없다.
    | 카테고리 | 토큰 enum | SSOT 문서 |
    |---|---|---|
    | Color | `MMColor` | `docs/design/design-system.md` § 컬러 |
    | Typography | `MMTypography` | `docs/design/design-system.md` § 2.5 |
    | Spacing | `MMSpacing` | `docs/design/design-system.md` § 스페이싱 |
    | Radius | `MMRadius` | `docs/design/design-system.md` § 라디우스 |
    | Shadow | `MMShadow` | `docs/design/design-system.md` § 섀도 |
    | Motion | `MMMotion` | `docs/design/design-system.md` § 모션 |
  - **Pretendard 폰트 등록** + `MMTypography` 토큰 (Dynamic Type `relativeTo` 매핑은 `docs/design/design-system.md` § 2.5 본문 참조 — 본 ADR은 SSOT를 위치만 인용).
  - **공통 컴포넌트**: `MMButton`, `MMCard`, `MMTag`, `MMRatingBadge`, `MMSearchBar`, `MMEmptyState` 등 (`docs/design/components.md` 13개 카탈로그).
  - **매장 핀 SVG** (`MatchaPinBasic/Premium/Iconic`) — `_design_assets/svg/pin/`에서 Asset Catalog로 변환.
  - **Liquid Glass 머터리얼** 헬퍼 (`MMGlassBackground` ViewModifier).
- **금지**: `Domain` import, 비즈니스 로직, 네트워크. **Sendable 미준수** public 타입 금지(아래).
- **Sendable 강제**: 모든 public `struct`/`enum`/`class` 타입은 `Sendable` 준수.
  - `enum` + `static let` 토큰은 자동 Sendable (`MMColor`, `MMTypography`, `MMSpacing`, `MMRadius`, `MMShadow`, `MMMotion`).
  - `struct Shadow`처럼 컴포지트 값 타입은 명시 `: Sendable` 필수.
  - 위반 시 PR 차단 (`.coderabbit.yaml` DesignSystem path_instructions 룰).
- **Feature/* 강제 규칙**: 다른 LocalPackages는 `DesignSystem`만 import. Color 리터럴/폰트 리터럴/하드코딩 spacing 사용 시 `.coderabbit.yaml`이 PR 차단.
- **Public API 예시**:
  ```swift
  public enum MMColor: Sendable {
      public static let matchaPrimary: Color = Color("MatchaPrimary", bundle: .module)
  }
  public enum MMTypography: Sendable {
      // Dynamic Type relativeTo 매핑은 design-system.md §2.5 SSOT 참조.
      public static let body: Font = .system(.body, design: .default)
      public static let title2: Font = .system(.title2, design: .default).weight(.semibold)
  }
  public struct MMButton<Label: View>: View {
      public init(action: @escaping () -> Void, @ViewBuilder label: () -> Label)
  }
  ```

### 3. `Domain`
- **외부 의존**: 0 (Foundation은 `Date`/`UUID`/기본 컬렉션 한정으로 사용).
- **내부 의존**: 없음.
- **책임**:
  - **Entity** (값 타입): `Store`, `Review`, `User`, `Friend`, `Wishlist`, `CollectionEntry`, `Country` 등.
  - **Repository protocol**: `StoreRepository`, `ReviewRepository`, `AuthRepository`, `WishlistRepository`, `FriendRepository`, `CollectionRepository`, `AdRepository` 등. (구현은 `Data`)
  - **UseCase**: `GetStoreDetailsUseCase`, `SearchStoresInBoundsUseCase`, `RegisterStoreToCollectionUseCase`, `SignInWithAppleUseCase` 등.
  - **Domain Error**: `MMDomainError` (auth/network/permission/notFound/unknown).
- **금지**:
  - SwiftUI / Combine / Firebase / GoogleMaps / Foundation의 URLSession.
  - `import Core` 도 원칙적 금지(Logger는 인프라 관심사) — 단 `Sendable` 등 표준 프로토콜만 사용.
- **Public API 예시**:
  ```swift
  public struct Store: Sendable, Hashable, Identifiable {
      public let id: String
      public let name: String
      public let location: Coordinate
      public let grade: StoreGrade   // .basic / .premium / .iconic
      public let matchaScore: Double // 0.0 ~ 5.0
  }
  public protocol StoreRepository: Sendable {
      func storeDetails(id: String) async throws -> Store
      func storesInBounds(_ bounds: BoundingBox) async throws -> [Store]
  }
  public protocol GetStoreDetailsUseCase: Sendable {
      func callAsFunction(id: String) async throws -> Store
  }
  ```

### 4. `Data`
- **외부 의존**: `FirebaseFirestore`, `FirebaseAuth`, `FirebaseStorage`, `FirebaseAppCheck`, `FirebaseMessaging`, `FirebaseAnalytics`, `GoogleMaps`, `GooglePlaces`.
- **내부 의존**: `Core`, `Domain`.
- **책임**:
  - Domain Repository 프로토콜 **구현체** (`FirebaseStoreRepository`, `FirebaseAuthRepository` 등).
  - DTO: Firestore 문서 ↔ Domain Entity 매핑 (`StoreDTO`, `ReviewDTO`).
  - DataSource: `FirestoreStoreDataSource`, `GoogleMapsPlacesDataSource`, `AdMobAdDataSource`.
  - HTTPClient URLSession 구현 (`URLSessionHTTPClient: HTTPClient`).
- **금지**: `Feature/*`를 import. `DesignSystem`을 import (UI 무관).
- **Public API 예시**:
  ```swift
  public final class FirebaseStoreRepository: StoreRepository {
      public init(firestore: Firestore = .firestore())
  }
  ```

### 5. `Feature/FeatureMap`
- **외부 의존**: `GoogleMaps` (지도 뷰 직접 임베드 필요).
- **내부 의존**: `Domain`, `DesignSystem`.
- **책임**:
  - `MapScreen` SwiftUI View + `GMSMapView` UIViewRepresentable 래퍼.
  - 매장 핀 마커, 클러스터링, 카메라 컨트롤.
  - `MapViewModel` (Domain UseCase 주입).
  - 위치 권한 흐름 + `travel_mode` 계산용 reverseGeocode.
- **Public API**: `public struct MapScreen: View { public init(viewModel: MapViewModel) }`.

### 6. `Feature/FeatureAuth`
- **외부 의존**: `AuthenticationServices` (ASAuthorizationAppleIDProvider, Passkey).
- **내부 의존**: `Domain`, `DesignSystem`.
- **책임**:
  - Apple Sign In 버튼 + Passkey 등록/로그인 UI.
  - `AuthViewModel`이 `SignInWithAppleUseCase`/`RegisterPasskeyUseCase` 주입.
- **Public API**: `public struct AuthEntryScreen: View { public init(viewModel: AuthViewModel) }`.

### 7. `Feature/FeatureStore`
- **외부 의존**: 없음 (이미지 로드는 Core/Data 경유).
- **내부 의존**: `Domain`, `DesignSystem`.
- **책임**:
  - 매장 상세, 메뉴, 리뷰 작성/조회, 검색·필터.

### 8. `Feature/FeatureSocial`
- **외부 의존**: 없음.
- **내부 의존**: `Domain`, `DesignSystem`.
- **책임**:
  - 친구 피드, 친구 추가/수락, 활동 알림.

### 9. `Feature/FeatureCollection`
- **외부 의존**: 없음.
- **내부 의존**: `Domain`, `DesignSystem`.
- **책임**:
  - 도감(컬렉션), 위시리스트, 랭킹.

### 10. `Feature/FeatureMonetize`
- **외부 의존**: `GoogleMobileAds`(AdMob), `StoreKit`(향후 v1.1.0 구독 대비).
- **내부 의존**: `Domain`, `DesignSystem`.
- **책임**:
  - 배너/인터스티셜/보상형 광고 슬롯 컴포넌트.
  - ATT 프롬프트 흐름.
  - 첫 60초 차단 가드.

## 의존 표 (Quick Reference)

| 모듈 | Core | Domain | DesignSystem | Data | Feat.Map | Feat.Auth | Feat.Store | Feat.Social | Feat.Collection | Feat.Monetize | App |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Core | – | x | x | x | x | x | x | x | x | x | x |
| Domain | x | – | x | x | x | x | x | x | x | x | x |
| DesignSystem | x | x | – | x | x | x | x | x | x | x | x |
| Data | ✓ | ✓ | x | – | x | x | x | x | x | x | x |
| Feature/* | x | ✓ | ✓ | x | – | – | – | – | – | – | x |
| App | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | – |

> ✓ = import 허용, x = import 금지, – = 자기 자신.
> **Feature → Data 임포트 금지**가 가장 중요한 규칙이다 (DI는 Composition Root에서).

## 결정 근거

1. **DAG 강제**: 단방향 의존만 허용. SwiftPM 그래프가 자동 검증해 준다 (순환 import 시 빌드 실패).
2. **Domain의 외부 0 의존**이 핵심:
   - 단위 테스트 0.1초 내 실행 가능.
   - 백엔드 교체(Firebase → Supabase) 시 `Data`만 갈아치우면 됨 (decisions-stack §재검토 트리거 발동 시).
   - 사용자가 명시한 *"소프트웨어 규칙을 잘 지킨다"*에 가장 부합.
3. **5인 동시 작업 안전**: 모듈마다 1명 책임 → worktree 분담 가능.
   - `ios-map` → `Feature/FeatureMap` + `Data`의 GoogleMaps 부분.
   - `ios-auth-monetize` → `Feature/FeatureAuth`, `Feature/FeatureMonetize`.
   - `ios-store` → `Feature/FeatureStore`.
   - `ios-social-collection` → `Feature/FeatureSocial`, `Feature/FeatureCollection`.
   - `ios-lead` → `Core`, `Domain`, `DesignSystem`(공통), `Data`(공통), Composition Root.
4. **PBXFileSystemSynchronizedRootGroup과 충돌 없음**: LocalPackages는 `MatchaMap/` 외부에 있으므로 자동 픽업 대상 아님 → Xcode의 `Local Packages`로 별도 등록 (Package Dependencies).

## 대안 (검토 후 기각)

### A. 단일 타깃 + 폴더 분리만
- 빌드 시간 단축 효과 0. 의존 방향 강제 불가. **기각**.

### B. Embedded Frameworks (XCFramework)
- 동적 프레임워크는 앱 시작 시간 증가. 우리는 정적 결합으로 충분. **기각**.

### C. SwiftPM 외부 모노레포
- v1.x 단계에서 외부 모노레포는 과한 분리. 향후 안드로이드 합류 시 재검토. **현 단계 기각**.

## 영향

- **빌드**: SwiftPM 패키지 추가 시 첫 resolve에 ~20초. 그 이후 incremental은 모듈 단위로 캐시.
- **TDD 가능**: `Domain` 테스트는 SDK 없이 `swift test`로도 가능 (10초 미만).
- **Composition Root**: ADR-002에서 정의.

## 향후 변경 트리거

- 안드로이드 합류 → `Domain`을 KMP(Kotlin Multiplatform)로 재구성하거나 별도 KMP 모듈로 미러링 검토.
- Firebase → Supabase 전환 → `Data` 모듈만 교체 (Domain·Feature 영향 0).

## Changelog

- 2026-05-04 초안 (ios-lead). po-lead 사인오프 대기.
