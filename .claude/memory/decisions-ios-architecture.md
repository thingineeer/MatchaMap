---
name: decisions-ios-architecture
description: iOS Phase 2 아키텍처 결정 — LocalPackages 9 모듈, Composition Root DI(라이브러리 미사용), TDD 강제. ADR-001/002/003 Accepted
type: project
---

**결정**: iOS는 Clean Architecture + LocalPackages 9 모듈로 분리. ADR-001/002/003 v0.1 Accepted (2026-05-04).

**모듈 구조**:
- `LocalPackages/Core` — Foundation/OSLog만.
- `LocalPackages/DesignSystem` — SwiftUI만 + Resource bundle (Phase 3에서 활성).
- `LocalPackages/Domain` — 외부 의존 0. Entity + Repository protocol + UseCase + Mock.
- `LocalPackages/Data` — Firebase/GoogleMaps SDK + Domain Repository 구현.
- `LocalPackages/Feature/{FeatureMap,FeatureAuth,FeatureStore,FeatureSocial,FeatureCollection,FeatureMonetize}` — 화면.

**핵심 규칙**:
- `Feature/*` → `Data` 직접 import **금지**. Composition Root에서 protocol 주입.
- `Domain` → 외부 의존 0. SwiftUI/Combine/Firebase 모두 금지. Foundation은 값 타입에 한해.
- `DesignSystem` → `Domain` import 금지.
- DI 라이브러리(Swinject, Factory 등) **미사용**. Manual + closure factory 패턴.
- ViewModel은 `@MainActor` + `@Observable` (Observation framework, iOS 17+).

**Why:**
- 사용자가 명시한 *"소프트웨어 규칙을 잘 지킨다"* + 5명 iOS 동시 작업 충돌 방지.
- Domain 외부 0 의존 → 단위 테스트 0.1초 이내 (실측: 6 테스트 0.002s).
- 백엔드 교체(Firebase → Supabase) 시 `Data`만 갈아치우면 됨 (decisions-stack §재검토 트리거 발동 시).
- DI 라이브러리는 컴파일 타임 검증을 잃는다. Swift 5/6의 protocol+actor면 충분.

**검증 결과 (2026-05-04 swift test)**:
- Core/Domain/DesignSystem/Data: PASS (10 테스트).
- FeatureMap/Auth/Store/Social/Collection/Monetize: PASS (각 1 테스트, 총 6).
- **합계 16 테스트 0 실패, 평균 < 0.005s/모듈**.

**How to apply:**
- iOS 5명은 자기 모듈 worktree에서 작업 (`feat/<module>-<story>`).
- 새 UseCase/Entity 추가 시 TDD 사이클: Tests에 실패 테스트 → 통과 → 리팩터.
- `import Data`를 `Feature/*`에서 시도하면 코드리뷰에서 차단.
- 상세는 `docs/architecture/ADR-001~003.md` 참조.
