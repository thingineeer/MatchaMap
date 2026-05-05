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

**후속 결정 (Phase 3 진입 시 추가, 2026-05-04)**:

1. **Color namespace 컨벤션 + SSOT 8 카테고리**: `Color.MM.<token>` (Color extension 패턴) — designer-lead 결정. `MMColor` top-level enum 별칭은 v1.x에서 추가하지 않음.
   - 토큰 SSOT 표 8 카테고리(ADR-001 §DesignSystem):
     Color(`Color.MM`) / ColorTier(`MMColorTier` 5단계, ADR-302 v1.1) / Typography(`MMTypography` 11 토큰 + relativeTo SSOT §2.5) / Spacing(`MMSpacing`) / Radius(`MMRadius`) / Shadow(`MMShadow` + `struct Shadow: Sendable` ViewModifier) / Motion(`MMMotion`) / OriginCoords(`MatchaOriginCoordsProvider` 8 region × {lat,lng} hardcoded §9).
   - Color만 namespace, 나머지 7 카테고리는 top-level enum (의도된 비대칭).
2. **StoreGrade → PinTier (server-side derive)**: server-data 의제 2 결정. Domain의 `StoreGrade.from(matchaScore:)` 함수는 **삭제 예정** — server-functions가 `pinTier` enum(S/A/B/C)을 doc에 캐시. iOS는 `Store.pinTier: PinTier`로 받기만. designer-icon 4등급 핀과 1:1 정합. Phase 3 ios-store가 schema.md §2.1 정합 수정.
3. **Domain Entity Phase 3 매핑**: server-data 의제 1·3·4·5·6 회신 동의 — `id: String` Data 검증, geohash 미보유, `StoreOrigin`/`OpeningHours` value type, `storesInBounds` 시그니처에 `minPinTier: PinTier?` 추가.
4. **Info.plist 옵션 1 채택** (ios-auth-monetize 제안): `INFOPLIST_KEY_NS*UsageDescription` 빌드 설정으로 권한 카피 5종 주입 (NSLocationWhenInUseUsageDescription, NSCameraUsageDescription, NSPhotoLibraryUsageDescription, NSUserTrackingUsageDescription, GADApplicationIdentifier 별도). PBXFileSystemSynchronizedRootGroup + GENERATE_INFOPLIST_FILE=YES 유지. Phase 4 ios-lead 통합 시점에 main이 적용.
5. **RepositoryError enum 표준** (server-lead Task #16 합의): 12 케이스 enum + Data Mappers/RepositoryErrorMapper.swift. Phase 3 ADR-001 v0.2 또는 별도 ADR-006으로 형식화 검토.
6. **PushTokenRepository protocol 신규** (ADR-302 v1.3, server-data 권고 2026-05-04): `users/{uid}/fcmTokens/{tokenId}` 서브컬렉션이 SSOT. `users.notification.fcmToken` 단일 필드 deprecated. Domain에 `PushTokenRepository` + `PushPermission` enum 추가, ios-auth-monetize Phase 3 own. 3 메서드: `registerToken(_:permission:)` / `updateLastSeen()`(1h throttle) / `deleteCurrentDeviceToken()`. **throttle 회귀 테스트는 cost-projection 가드** — 미준수 시 Firestore Write Count 폭증($2.7/월 → 폭증). PR 머지 차단 룰 적용.
7. **deepMatcha hex `#556B43` 정정** (designer-lead 2026-05-04, 3-way 충돌 해결): 초안 `#5A7A4A` → `#556B43`(designer-icon 권고 + ios-social-collection 임시값 일치). WCAG AA cream 5.5:1 / paper 6.4:1 / bg 6.0:1. iOS 측 변경 0줄, server-functions colorTier.ts 1줄 변경 의뢰됨.
8. **인프라 활성화 완료** (team-lead a6b1ef9, 2026-05-04): Firebase `MatchaMapAPP` 라이브 — Firestore + Storage + Auth Apple Provider + App Check(App Attest, TEAM_ID `8Q4H7X3Q58`) + Cloud Functions 14개 deploy(asia-northeast3) + Hosting AASA(`one-problem-app.web.app`) + AdMob 3슬롯 vault + Maps SDK + Places API. Composition Root 구현 즉시 가능 상태.
   - 빌드 타임 변수: `Configs/Info.xcconfig`에 `GOOGLE_APP_ID_IOS` / `GADApplicationIdentifier` / `GMS_API_KEY_IOS` 정의 (ios-lead Task #24 작업).
   - callable Functions 호출 패턴: `Functions.functions(region: "asia-northeast3").httpsCallable("submitReview")` 등 14개.
   - AppCheckProviderFactory: App Attest first + DeviceCheck fallback.
