---
name: handoff-xcode-integration
description: ios-lead가 SwiftPM에서 LocalPackages 9 모듈 빌드/테스트 검증을 끝냈으나 Xcode 통합 단계는 사용자 UI 작업 필요 — Local Package 추가 + Unit Testing Bundle
type: project
---

**상태**: 2026-05-04, ios-lead가 LocalPackages 9 모듈 + ADR-001/002/003 + TDD 시연 16 테스트 PASS까지 완료. 그러나 Xcode 통합(Local Package 등록 + MatchaMapTests 타깃 추가)은 미완.

**Why:**
- `MatchaMap.xcodeproj/project.pbxproj`에 `XCLocalSwiftPackageReference` 0건. SourceKit이 LocalPackages를 인식 못해 IDE 진단 에러 30+ 발생 (실제 빌드는 무관).
- `project.pbxproj` 손편집은 PBXFileSystemSynchronizedRootGroup + Xcode 26.3 환경에서 위험. CLAUDE.md §5.1 *"`project.pbxproj` 수동 편집 금지"* 정책 준수.
- 따라서 Xcode UI에서 사용자가 직접 단계 수행 필요.

**사용자가 수행할 단계 (Xcode 26.3에서)**:

1. **Local Package 등록** (9개 모두):
   - `open MatchaMap.xcodeproj`.
   - File → Add Package Dependencies → 좌하단 *Add Local…* 버튼.
   - 디렉토리 선택 (각 패키지마다 1회씩 반복):
     - `LocalPackages/Core`
     - `LocalPackages/DesignSystem`
     - `LocalPackages/Domain`
     - `LocalPackages/Data`
     - `LocalPackages/Feature/FeatureMap`
     - `LocalPackages/Feature/FeatureAuth`
     - `LocalPackages/Feature/FeatureStore`
     - `LocalPackages/Feature/FeatureSocial`
     - `LocalPackages/Feature/FeatureCollection`
     - `LocalPackages/Feature/FeatureMonetize`
   - 각 추가 시 *Add to Target: MatchaMap* 체크 → Add Package.

2. **Unit Testing Bundle 타깃 추가**:
   - File → New → Target → iOS → **Unit Testing Bundle**.
   - Product Name: `MatchaMapTests`.
   - Target to be Tested: `MatchaMap`.
   - Finish.
   - Xcode가 `MatchaMapTests/` 디렉토리 + scheme 자동 생성.

3. **빌드/테스트 검증**:
   ```sh
   xcodebuild -project MatchaMap.xcodeproj -scheme MatchaMap \
     -destination 'platform=iOS Simulator,name=iPhone 17' build
   xcodebuild test -project MatchaMap.xcodeproj -scheme MatchaMap \
     -destination 'platform=iOS Simulator,name=iPhone 17'
   ```

4. **Info.plist 처리 결정** (feedback-info-plist-conflict.md 참조):
   - 옵션 1: `INFOPLIST_KEY_NS*UsageDescription` 빌드 설정으로 권한 키 주입 (Xcode UI 권장).
   - 옵션 2: `GENERATE_INFOPLIST_FILE = NO` + `INFOPLIST_FILE = MatchaMap/Info.plist` 명시.
   - ios-lead 권장: **옵션 1** — Xcode UI에서 Target → Info → Custom iOS Target Properties로 키 추가 (project.pbxproj 손편집 회피).
   - 적용할 키:
     - `NSLocationWhenInUseUsageDescription` (지도 매장 검색 + travel_mode 판별).
     - `NSCameraUsageDescription` (리뷰 사진 촬영).
     - `NSPhotoLibraryUsageDescription` (리뷰 사진 첨부).
     - `NSUserTrackingUsageDescription` (ATT, AdMob).
     - `GADApplicationIdentifier` (AdMob — `~/.env-vault/projects/matchamap-ios/admob.json`에서 로드).

5. **완료 후**:
   - 본 메모리 `status` 갱신 (또는 삭제) + ios-lead에 SendMessage.
   - Task #11을 completed로 변경.

**How to apply (다음 세션 ios-lead 또는 사용자):**
- 본 메모를 먼저 읽고 진행. 위 5단계가 완료되면 Phase 3(iOS 구현) 진입 가능.
- SwiftPM 단독 검증은 이미 PASS이므로 Domain/Data 단위 작업은 Xcode 통합 전에도 진행 가능 (`swift test`).
