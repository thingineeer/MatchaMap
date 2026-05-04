---
name: feedback-info-plist-conflict
description: PBXFileSystemSynchronizedRootGroup + GENERATE_INFOPLIST_FILE=YES 환경에서 MatchaMap/Info.plist를 두면 빌드 충돌. 권한 키는 templates 또는 build setting으로
type: feedback
---

**규칙**: `MatchaMap/` 디렉토리 안에 `Info.plist` 파일을 두지 않는다.

**Why:**
- 본 프로젝트의 `MatchaMap/`는 `PBXFileSystemSynchronizedRootGroup`(Xcode 16+)으로 자동 파일 픽업.
- 동시에 `GENERATE_INFOPLIST_FILE = YES`라서 Xcode가 빌드 타임에 Info.plist를 자동 생성.
- 둘이 같은 출력 경로(`MatchaMap.app/Info.plist`)에 쓰려고 해서 빌드 실패: *"Multiple commands produce ... Info.plist"*.

**현재 처리:**
- 권한 키/AdMob ID 등 Info.plist 시드는 `docs/architecture/templates/Info.plist.template`에 보관.
- Phase 4에서 `ios-lead`가 다음 중 하나로 확정:
  1. INFOPLIST_KEY_NS*UsageDescription 빌드 설정으로 권한 키 주입 (Xcode 권장).
  2. `GENERATE_INFOPLIST_FILE = NO`로 전환 + `INFOPLIST_FILE = MatchaMap/Info.plist` 명시 (project.pbxproj 손편집 필요).

**fastlane bump_build 영향:**
- 현재 자동 생성 모드에서는 `set_info_plist_value(path: "MatchaMap/Info.plist", ...)` 가 동작하지 않을 수 있다.
- ios-lead가 옵션 2(명시 INFOPLIST_FILE)를 채택하면 그대로 동작.
- 옵션 1을 채택하면 fastlane은 `update_info_plist` 또는 `set_info_plist_value`를 빌드 후(아카이브 직전) 적용하거나, build setting의 `CURRENT_PROJECT_VERSION`을 갱신.

**How to apply:**
- 새 권한 키나 AdMob 설정이 필요하면 우선 `docs/architecture/templates/Info.plist.template`에 기록.
- `MatchaMap/Info.plist`를 절대 다시 만들지 말 것.
