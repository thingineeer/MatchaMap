# ADR-002 — 의존성 주입 전략 (POP + Composition Root)

- **일자**: 2026-05-04
- **상태**: Accepted (Phase 2)
- **결정자**: `ios-lead`
- **관련 ADR**: ADR-001(Module Boundary), ADR-003(Test Strategy)

## 컨텍스트

ADR-001에서 모듈 경계가 정해졌다. `Feature/*`는 `Data`를 직접 import 할 수 없다. 그렇다면:

- `Feature`는 어떻게 실제 Repository 구현체를 받는가?
- `Preview`/`Tests`에서는 어떻게 mock을 주입하는가?
- 의존성 컨테이너 라이브러리(Swinject, Factory, Resolver 등)를 쓸 것인가?

## 결정

### 1. **POP (Protocol-Oriented Programming) 강제**
모든 의존은 `Domain`의 프로토콜 타입으로 받는다. 구체 타입 import 금지.

### 2. **Composition Root: `MatchaMap/MatchaMapApp.swift`**
앱 타깃 한 곳에서 모든 객체 그래프를 조립. Feature 모듈은 Repository를 *생성*하지 않고 *주입받는다*.

### 3. **DI 컨테이너 라이브러리 미사용**
Swift 5/6의 actor·struct·protocol 조합으로 충분. Manual + Factory closure 패턴 사용. Swinject 같은 런타임 컨테이너는:
- 컴파일 타임 의존 검증을 잃는다.
- 런타임 graph 빌드는 불필요한 추상화.
- iOS 5인 팀 규모에 과한 인프라.

### 4. **Factory closure 패턴**
ViewModel/UseCase는 의존을 **이니셜라이저로** 받고, App 타깃의 `AppComposition` 구조체가 closure로 graph를 만든다.

## 패턴

### 4.1 Domain 프로토콜 정의

```swift
// LocalPackages/Domain/Sources/Domain/Repositories/StoreRepository.swift
public protocol StoreRepository: Sendable {
    func storeDetails(id: String) async throws -> Store
    func storesInBounds(_ bounds: BoundingBox) async throws -> [Store]
}

public protocol GetStoreDetailsUseCase: Sendable {
    func callAsFunction(id: String) async throws -> Store
}

public struct GetStoreDetailsUseCaseImpl: GetStoreDetailsUseCase {
    private let repository: StoreRepository
    public init(repository: StoreRepository) { self.repository = repository }
    public func callAsFunction(id: String) async throws -> Store {
        try await repository.storeDetails(id: id)
    }
}
```

### 4.2 Data 구현

```swift
// LocalPackages/Data/Sources/Data/Repositories/FirebaseStoreRepository.swift
import Domain
import FirebaseFirestore

public final class FirebaseStoreRepository: StoreRepository {
    private let firestore: Firestore
    public init(firestore: Firestore = .firestore()) { self.firestore = firestore }
    public func storeDetails(id: String) async throws -> Store { /* ... */ }
    public func storesInBounds(_ bounds: BoundingBox) async throws -> [Store] { /* ... */ }
}
```

### 4.3 Feature ViewModel — 프로토콜만 받음

```swift
// LocalPackages/Feature/FeatureStore/Sources/FeatureStore/StoreDetailViewModel.swift
import Domain
import Observation

@MainActor
@Observable
public final class StoreDetailViewModel {
    public private(set) var state: ViewState = .idle
    private let getStoreDetails: GetStoreDetailsUseCase

    public init(getStoreDetails: GetStoreDetailsUseCase) {
        self.getStoreDetails = getStoreDetails
    }

    public func load(id: String) async {
        state = .loading
        do {
            let store = try await getStoreDetails(id: id)
            state = .loaded(store)
        } catch {
            state = .failed(error)
        }
    }
}
```

> **중요**: `StoreDetailViewModel`은 `import Data`를 절대 하지 않는다. `Domain`만 import.

### 4.4 Composition Root — `AppComposition`

```swift
// MatchaMap/Composition/AppComposition.swift
import Core
import Data
import Domain
import FeatureMap
import FeatureStore
import FeatureAuth
import FeatureSocial
import FeatureCollection
import FeatureMonetize
import FirebaseFirestore

@MainActor
struct AppComposition {
    // MARK: - Repositories (lazy singleton via closure)
    private let firestore: Firestore
    private let logger: Logger

    init() {
        self.firestore = .firestore()
        self.logger = Logger(category: .app)
    }

    // MARK: - Factories (Feature ViewModel)
    func makeStoreDetailViewModel(storeId: String) -> StoreDetailViewModel {
        let repo = FirebaseStoreRepository(firestore: firestore)
        let useCase = GetStoreDetailsUseCaseImpl(repository: repo)
        return StoreDetailViewModel(getStoreDetails: useCase)
    }

    func makeMapViewModel() -> MapViewModel { /* ... */ }
    func makeAuthViewModel() -> AuthViewModel { /* ... */ }
    // ... 기타 Feature ViewModel
}

// MatchaMap/MatchaMapApp.swift
@main
struct MatchaMapApp: App {
    @State private var composition = AppComposition()
    var body: some Scene {
        WindowGroup {
            RootView(composition: composition)
        }
    }
}
```

### 4.5 Preview / Test에서 mock 주입

`Domain` 프로토콜에 대한 `MockStoreRepository`를 같은 모듈 내 또는 테스트 타깃에 정의:

```swift
// LocalPackages/Domain/Sources/Domain/Testing/MockStoreRepository.swift
// (또는 Tests에 둘 수도 있음 — 테스트 전용이면 Tests로)
public final class MockStoreRepository: StoreRepository {
    public var stubStore: Store?
    public var stubError: Error?
    public init() {}
    public func storeDetails(id: String) async throws -> Store {
        if let stubError { throw stubError }
        return stubStore ?? .preview
    }
    public func storesInBounds(_ bounds: BoundingBox) async throws -> [Store] {
        if let stubError { throw stubError }
        return [.preview]
    }
}
```

```swift
// SwiftUI Preview 예시
#Preview {
    let mock = MockStoreRepository()
    mock.stubStore = .preview
    let useCase = GetStoreDetailsUseCaseImpl(repository: mock)
    let viewModel = StoreDetailViewModel(getStoreDetails: useCase)
    return StoreDetailScreen(viewModel: viewModel)
}
```

```swift
// 단위 테스트 예시
final class StoreDetailViewModelTests: XCTestCase {
    @MainActor
    func test_load_setsLoadedState_whenRepositorySucceeds() async {
        let mock = MockStoreRepository()
        mock.stubStore = .fixture(id: "123", name: "Matcha Cafe")
        let useCase = GetStoreDetailsUseCaseImpl(repository: mock)
        let sut = StoreDetailViewModel(getStoreDetails: useCase)

        await sut.load(id: "123")

        if case .loaded(let store) = sut.state {
            XCTAssertEqual(store.id, "123")
        } else { XCTFail("expected .loaded") }
    }
}
```

### 4.6 Mock의 위치 결정

| 옵션 | 위치 | 장단점 |
|---|---|---|
| A | `Domain/Sources/Domain/Testing/` | Preview에서도 재사용 가능. 단 Domain 바이너리 사이즈 ↑(미미). |
| B | `Domain/Tests/DomainTests/Mocks/` | Preview 재사용 불가 (Tests는 앱이 import 못 함). |

**채택: 옵션 A.** Preview에서 mock 사용을 위해. 단 `MockXxx`는 `#if DEBUG` 또는 `Testing` 서브폴더로 격리.

## DI 컨테이너 라이브러리 비교 (기각 근거)

| 라이브러리 | 컴파일 타임 검증 | 런타임 의존 | 학습 곡선 | 결론 |
|---|---|---|---|---|
| Manual + Factory (본 결정) | ✓ | 0 | 낮음 | **채택** |
| Swinject | x | 있음 | 중 | 런타임 graph는 5인 팀에 과함 |
| Factory (hmlongco) | △ | 있음 | 중 | property wrapper 매직, 디버깅 ↓ |
| Resolver | x | 있음 | 중 | Factory와 유사 |
| Swift `@Dependency` (point-free) | △ | 있음 | 높음 | TCA와 강결합, 우리는 Observation 사용 |

## 결정 근거

1. **명시성**: Composition Root 한 파일을 보면 의존 그래프 전체를 알 수 있다.
2. **컴파일 타임**: 빠진 의존이 있으면 **빌드 실패**. 런타임 fatalError 없음.
3. **단순성**: closure factory 패턴은 모든 Swift 개발자가 즉시 이해.
4. **테스트 친화적**: protocol → mock 주입이 자연스럽다.
5. **`@Observable` (Observation framework, iOS 17+) 친화적**: ViewModel은 단순 class. SwiftUI Bindable 통합도 쉬움.

## ViewModel 표준

- `@MainActor` (CLAUDE.md §5.1, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`).
- `@Observable` (Observation framework). `ObservableObject`/`@Published` 사용 금지(레거시).
- 상태는 `enum ViewState` 또는 `struct State` (불변 값).
- 비동기는 `async`/`await` (Combine 사용 금지, 단 SDK가 강제하면 Task로 변환).

## Future Work

- Swift 6.2의 `@retroactive` `Sendable` 지원 확장 시 `MockStoreRepository`의 mutable property 동시성 안전성 보강.
- `swift-dependencies`(point-free)는 Phase 3+ 대규모 화면 추가 시 재검토.

## Changelog

- 2026-05-04 초안 (ios-lead). po-lead 사인오프 대기.
