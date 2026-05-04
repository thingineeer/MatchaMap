# ADR-003 — 테스트 전략 (TDD + Layer별 책임)

- **일자**: 2026-05-04
- **상태**: Accepted (Phase 2)
- **결정자**: `ios-lead`
- **공동 리뷰**: `qa-lead`
- **관련 ADR**: ADR-001(Module Boundary), ADR-002(DI), CLAUDE.md §5.2

## 컨텍스트

CLAUDE.md §5.2: *"iOS 개발자는 무조건 TDD: 실패하는 테스트 → 통과 → 리팩터."* 5인 iOS 팀이 동시에 작업하므로, 테스트 표준 부재 시 회귀 빈발.

## 결정

### 1. **TDD 사이클 강제**
모든 기능은 다음 순서로:
1. **Red**: 실패하는 테스트를 먼저 작성 → `xcodebuild test`로 빨간색 확인.
2. **Green**: 최소 코드로 통과시킨다.
3. **Refactor**: 테스트가 그린일 때만 리팩터.

PR 게이트: 새 코드는 반드시 테스트와 함께 와야 한다 (코드리뷰에서 ios-lead가 거부).

### 2. **레이어별 테스트 책임**

| 레이어 | 테스트 종류 | 도구 | 비율 (대략) |
|---|---|---|---|
| `Domain` | Unit (UseCase, Entity 로직) | XCTest in SwiftPM `swift test` | 50% (피라미드 베이스) |
| `Data` | Unit (DTO 매핑, Repository fake DataSource) | XCTest | 25% |
| `Feature` ViewModel | Unit (state 전이, mock UseCase 주입) | XCTest @MainActor | 15% |
| `DesignSystem` | Visual smoke (Preview만 — Phase 4에서 Snapshot 검토) | (Phase 4) | 5% |
| `Core` | Unit (헬퍼) | XCTest | 5% |
| **앱 통합** | E2E UI 자동화 | **Appium**(QA 팀) | XCUITest 미사용 |

> **현 단계는 Unit Test만**. Snapshot Testing은 Phase 4(첫 빌드 안정화 후) 검토. UI 자동화는 QA 팀이 Appium으로 별도 운영(CLAUDE.md §6 ios-lead가 자동화 방향 결정).

### 3. **Test Target 구조**

각 LocalPackage는 `Sources/<Module>/`와 `Tests/<Module>Tests/`를 자체 보유. SwiftPM이 자동으로 test target 생성. 추가 Xcode 타깃은 **앱 단위 통합 테스트만** 별도로:

```
LocalPackages/
├── Domain/
│   ├── Sources/Domain/...
│   └── Tests/DomainTests/        ← swift test로 실행 가능 (SDK 의존 0)
├── Data/
│   ├── Sources/Data/...
│   └── Tests/DataTests/          ← Firebase emulator는 Phase 3에서 검토, 현재는 fake DataSource
├── Feature/FeatureMap/
│   ├── Sources/FeatureMap/...
│   └── Tests/FeatureMapTests/    ← MockUseCase 주입 패턴
└── ... (다른 모듈 동일)

MatchaMap.xcodeproj
├── MatchaMap (App)
└── MatchaMapTests (Unit Testing Bundle)   ← Composition Root 통합 테스트 1~2개만
```

### 4. **Unit Testing Bundle 추가 절차**

Xcode에서 한 번만 수동:
1. Xcode 열기: `open MatchaMap.xcodeproj`.
2. Project Navigator → MatchaMap 프로젝트 → Targets → `+` → iOS → **Unit Testing Bundle**.
3. Product Name: `MatchaMapTests`.
4. Target to be Tested: `MatchaMap`.
5. 생성되면 `MatchaMapTests/MatchaMapTests.swift` 자동 생성.
6. 즉시 커밋: `git add MatchaMap.xcodeproj MatchaMapTests/ && git commit -m "[infra] add MatchaMapTests unit testing bundle"`.

> **주의**: PBXFileSystemSynchronizedRootGroup이라도 *새 타깃 추가*는 Xcode 직접. `project.pbxproj`는 Xcode가 생성/수정한다 (사용자가 손편집 금지). 본 ADR-003 산출물 7번 참고.

### 5. **단위 테스트 패턴**

#### 5.1 Domain UseCase 테스트 (가장 중요)

```swift
// LocalPackages/Domain/Tests/DomainTests/GetStoreDetailsUseCaseTests.swift
import XCTest
@testable import Domain

final class GetStoreDetailsUseCaseTests: XCTestCase {

    func test_callAsFunction_returnsStore_whenRepositorySucceeds() async throws {
        // Given
        let mock = MockStoreRepository()
        mock.stubStore = .fixture(id: "abc", name: "말차하우스")
        let sut = GetStoreDetailsUseCaseImpl(repository: mock)

        // When
        let store = try await sut(id: "abc")

        // Then
        XCTAssertEqual(store.id, "abc")
        XCTAssertEqual(store.name, "말차하우스")
    }

    func test_callAsFunction_throws_whenRepositoryFails() async {
        // Given
        let mock = MockStoreRepository()
        mock.stubError = MMDomainError.notFound
        let sut = GetStoreDetailsUseCaseImpl(repository: mock)

        // When / Then
        do {
            _ = try await sut(id: "missing")
            XCTFail("expected throw")
        } catch let error as MMDomainError {
            XCTAssertEqual(error, .notFound)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}
```

#### 5.2 Data DTO 매핑 테스트

```swift
// LocalPackages/Data/Tests/DataTests/StoreDTOTests.swift
import XCTest
@testable import Data
@testable import Domain

final class StoreDTOTests: XCTestCase {
    func test_toDomain_mapsAllFields() throws {
        let dto = StoreDTO(
            id: "1",
            name: "Cafe",
            latitude: 37.5,
            longitude: 127.0,
            grade: "iconic",
            matchaScore: 4.7
        )
        let store = dto.toDomain()
        XCTAssertEqual(store.grade, .iconic)
        XCTAssertEqual(store.matchaScore, 4.7)
    }
}
```

#### 5.3 Feature ViewModel 테스트 (@MainActor)

```swift
// LocalPackages/Feature/FeatureStore/Tests/FeatureStoreTests/StoreDetailViewModelTests.swift
import XCTest
@testable import FeatureStore
import Domain

@MainActor
final class StoreDetailViewModelTests: XCTestCase {

    func test_load_setsLoadedState_whenUseCaseSucceeds() async {
        let mockRepo = MockStoreRepository()
        mockRepo.stubStore = .fixture(id: "1")
        let useCase = GetStoreDetailsUseCaseImpl(repository: mockRepo)
        let sut = StoreDetailViewModel(getStoreDetails: useCase)

        await sut.load(id: "1")

        guard case .loaded(let store) = sut.state else {
            return XCTFail("expected .loaded, got \(sut.state)")
        }
        XCTAssertEqual(store.id, "1")
    }
}
```

### 6. **테스트 명명**

`test_<unitOfWork>_<expectedBehavior>_when<condition>` 패턴 권장. 한국어 허용 (`test_매장상세_로드성공_저장소응답시`).

### 7. **테스트 실행 명령**

#### 7.1 SwiftPM 단독 (가장 빠름, SDK 없는 모듈만)

```sh
cd LocalPackages/Domain && swift test
```

`Domain`은 외부 의존이 없어 macOS에서도 실행 가능. CI에서 가장 빠른 게이트.

#### 7.2 Xcode 시뮬레이터 (Data, Feature 등 SDK 사용 모듈)

```sh
xcodebuild test \
  -project MatchaMap.xcodeproj \
  -scheme MatchaMap \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:DomainTests \
  -only-testing:DataTests \
  -only-testing:FeatureStoreTests
```

#### 7.3 전체 (PR 머지 게이트)

```sh
xcodebuild test \
  -project MatchaMap.xcodeproj \
  -scheme MatchaMap \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

### 8. **CI/PR 게이트 (Phase 3 도입 예정)**

GitHub Actions 또는 Xcode Cloud:
1. PR 생성 → Domain/Data/Feature 테스트 실행.
2. 실패 시 머지 차단.
3. CodeRabbit AI는 별도 (보강 리뷰).

### 9. **Snapshot Testing은 Phase 4**

- Snapshot은 디자인 토큰 회귀 방지에 강력하지만 false positive(폰트 렌더링 차이) 부담.
- Phase 4(첫 베타 후) 안정화 시 `swift-snapshot-testing` 검토.
- 그 전까지는 `#Preview` 매크로로 디자인 회귀 시각 검증 + 디자이너 핸드오프 매핑(handoff-mapping.md).

### 10. **UI 자동화 (XCUITest)는 미사용**

- QA 팀이 Appium 스택을 운영 (CLAUDE.md §2 qa-functional, qa-localization).
- iOS 개발자는 ViewModel + Domain만 단위 테스트 책임.
- E2E 시나리오 계약은 `docs/qa/scenarios/`.

## 결정 근거

1. **TDD가 사용자 명시 요구**: CLAUDE.md §5.2 명문. 협상 불가.
2. **Domain 외부 0 의존 → 0.1초 테스트** 가능. 빠른 피드백 루프.
3. **레이어별 책임 분리**: Domain은 비즈니스 로직, Data는 매핑, ViewModel은 상태 전이. 각각 다른 종류의 회귀를 잡는다.
4. **SwiftPM 자체 test target**으로 Xcode 무관하게 CI 가능. 빠른 게이트.
5. **Snapshot/UI 자동화 후속화**: 우선순위는 비즈니스 로직 회귀 방지.

## 시연 (산출물 6)

`Domain` 모듈에 `GetStoreDetailsUseCase`를 TDD로 구현. 실패 테스트 → 통과 → 리팩터 사이클을 본 ADR과 동시에 시연 (LocalPackages/Domain/Tests/DomainTests/GetStoreDetailsUseCaseTests.swift).

## Changelog

- 2026-05-04 초안 (ios-lead). qa-lead/po-lead 사인오프 대기.
