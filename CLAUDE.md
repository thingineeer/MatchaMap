# CLAUDE.md — 말차맵 (MatchaMap)

> 매 세션 시작 시 반드시 이 파일과 `.claude/memory/MEMORY.md`를 먼저 읽으세요.
> 이 파일은 16명 에이전트 팀 전원에게 적용되는 최상위 규칙 문서입니다.

---

## 1. 프로젝트 한 줄 정의

전세계 말차 덕후를 위한 글로벌 말차 카페 발견·기록·도감 앱. iOS 26.2 SwiftUI + Liquid Glass · Google Maps SDK · Firebase 백엔드 · Apple/Passkey 로그인 · MVP 수익화는 AdMob.

- **앱 이름(KR/JA/ZH 우선)**: 말차맵 (MatchaMap)
- **앱 이름(EN/DE/FR/그 외)**: MatchaMap
- **Bundle ID**: `th1ngjin.MatchaMap`
- **iOS 배포 타깃**: iOS 26.2 (Xcode 26.3, Swift 5.0)
- **타깃 디바이스**: iPhone + iPad (`TARGETED_DEVICE_FAMILY = "1,2"`)
- **Firebase 프로젝트**: `MatchaMapAPP` (구 `one-problem-app`을 이름 변경 — Firebase 신규 프로젝트 한도 초과로 재활용)
- **광고**: Google AdMob (MVP)
- **타깃 시장(MVP 우선순위)**: 🇰🇷 KR → 🇯🇵 JP → 🇺🇸 US → 🇬🇧 UK → 🇩🇪 DE → 🇫🇷 FR (다국어 6개 catalog)

## 2. 16명 팀 구성

세부 에이전트 정의는 `.claude/agents/{name}.md` 참조. 모든 에이전트는 `model: "opus"`.

| # | name | 역할 | 카테고리 |
|---|---|---|---|
| 1 | `po-lead` | PO 리더 · 가설/검증 · 우선순위 결정 | Product (2) |
| 2 | `po-growth` | 시장조사 · 수익화 · AdMob 슬롯 · GTM | Product |
| 3 | `ios-lead` | iOS 15년차 리드 · 코드리뷰 · 모듈 경계 결정 | iOS (5) |
| 4 | `ios-map` | Google Maps SDK · 마커 · 클러스터링 · 카메라 | iOS |
| 5 | `ios-auth-monetize` | Apple Sign In · Passkey · AdMob SDK 통합 | iOS |
| 6 | `ios-store` | 스토어 상세 · 메뉴 · 리뷰 · 검색 · 필터 | iOS |
| 7 | `ios-social-collection` | 피드 · 위시리스트 · 도감 · 랭킹 | iOS |
| 8 | `qa-lead` | QA 15년차 리드 · 시나리오 사인오프 · Appium | QA (3) |
| 9 | `qa-functional` | 기능 회귀 · 사용자 플로우 · 시뮬레이터 | QA |
| 10 | `qa-localization` | 6개 언어 카탈로그 · RTL/길이 검증 | QA |
| 11 | `designer-lead` | 디자인 시스템 · 화면 시안 검수 · 토큰 | Design (2) |
| 12 | `designer-icon` | 앱 아이콘 · SVG · 픽셀 단위 정렬 | Design |
| 13 | `server-lead` | 백엔드 리드 · Firebase/Supabase 최종 결정 | Server (4) |
| 14 | `server-data` | Firestore 스키마 · 데이터 모델 · 인덱스 | Server |
| 15 | `server-functions` | Cloud Functions · API 계약 · 리전 | Server |
| 16 | `server-auth` | Auth · Storage · Push · App Check | Server |

> **안드로이드(Compose)는 추후 트리거 발생 후 시작.** 현재 단계에서 안드로이드 에이전트는 정의하지 않습니다.

## 3. 협업 규칙 (전원 필독)

- **반증 우선**: 다른 에이전트가 반론을 제기하면 자기 결정과 비교하여 *더 나은 방향*으로 합의를 이끈다. 권위가 아니라 근거로 설득한다.
- **모듈 경계 충돌 방지**: 두 에이전트가 같은 파일을 동시에 편집하지 않는다. worktree 단위로 모듈을 분담한다 (§ 6 브랜치 전략).
- **결정은 문서로 남긴다**: 중요한 기술/제품 결정은 `docs/` 하위 ADR로 기록 (`docs/architecture/ADR-XXX.md`).
- **PO가 만드는 산출물(`docs/product/`)에 따라 iOS 리드가 구현 계획(`docs/architecture/`)을 짜고 → 디자이너가 시안(`docs/design/`)을 → 서버가 API 계약(`docs/server/`)을 → 개발자가 구현 → QA가 검증(`docs/qa/`)** 하는 사이클이 기본. 그러나 중간에 다른 에이전트가 개입해 토론·보강은 환영.
- **메시지는 SendMessage로**: 텍스트 출력만으로는 다른 에이전트에게 전달되지 않는다. 팀원 간 소통은 반드시 `SendMessage`.
- **태스크는 TaskUpdate로**: 작업 시작 시 `in_progress`, 완료 시 `completed`. 검증 없이 완료 처리 금지.

## 4. 메모리 규칙

- **프로젝트 로컬 메모리만 사용**: `.claude/memory/MEMORY.md`. 글로벌 `~/.claude/projects/.../memory/`에는 절대 쓰지 않는다 (Git을 통해 다른 머신과 동기화하기 위함).
- **자동 메모리는 비활성화**: 시스템 프롬프트의 auto-memory 경로는 무시하고, 대신 본 프로젝트의 `.claude/memory/`에 기록한다.
- **MEMORY.md는 인덱스**: 본문이 아닌 포인터만 유지. 본문은 `.claude/memory/{topic}.md`에.

## 5. 아키텍처 규칙

### 5.1 iOS Clean Architecture (모듈 분리)

```
MatchaMap (App)
├── LocalPackages/
│   ├── Core/                  # Network, Logger, Config, DI Helpers
│   ├── DesignSystem/          # 토큰(MM2 팔레트), Components, SVG Icons
│   ├── Domain/                # Entities, UseCases, Repository protocols (외부 의존성 0)
│   ├── Data/                  # Repository impl, DataSources(Firebase/GMaps), DTOs
│   └── Feature/
│       ├── FeatureMap/
│       ├── FeatureAuth/
│       ├── FeatureStore/
│       ├── FeatureSocial/
│       ├── FeatureCollection/
│       └── FeatureMonetize/
└── MatchaMap/                 # App entry, AppDelegate, Composition Root
```

- **POP(Protocol-Oriented Programming) 준수**: 모든 의존성은 프로토콜로. Domain은 외부 0 의존.
- **MainActor 기본**: 빌드 설정 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. 백그라운드 작업은 명시적으로 `nonisolated` 또는 다른 actor에 할당.
- **`SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`**: 전이 import 멤버는 보이지 않으므로 명시적 `import` 필수.
- **String Catalog 강제**: `LOCALIZATION_PREFERS_STRING_CATALOGS = YES`. `.xcstrings`만 사용, raw key 대신 생성된 심볼 참조.
- **PBXFileSystemSynchronizedRootGroup**: `MatchaMap/` 디렉토리에 새 파일을 떨어뜨리면 자동으로 빌드에 포함. **절대 `project.pbxproj`의 Sources 빌드 페이즈를 손으로 편집하지 말 것.**
- **Xcode 빌드 명령**:
  ```sh
  open MatchaMap.xcodeproj
  xcodebuild -project MatchaMap.xcodeproj -scheme MatchaMap -configuration Debug \
             -destination 'platform=iOS Simulator,name=iPhone 17' build
  ```

### 5.2 TDD 강제

iOS 개발자는 **무조건 TDD**: 실패하는 테스트 → 통과 → 리팩터. 첫 테스트 타깃은 **Unit Testing Bundle**을 Xcode에서 한 번 추가한 뒤 `xcodebuild test`. UI 자동화는 QA 팀이 Appium으로 별도 실행.

## 6. Git 브랜치 전략 (필수 숙지)

```
release  ← 앱스토어에 실제 배포된 버전만 (태그 기반)
   ↑ merge after store release
main     ← QA 통과한 코드 (배포 후보)
   ↑ merge after QA sign-off
dev      ← 개발 진행 중 (default branch, 통합 베이스)
   ↑ merge from version branches
1.0.0    ← 버전 단위 통합 브랜치 (dev에서 분기)
   ↑ merge from worktree feature branches
feat/*   ← worktree 단위 개별 기능 브랜치 (커밋 N개)
```

### 6.1 작업 흐름

1. `dev`에서 버전 브랜치 분기: `git checkout -b 1.0.0 dev`
2. 기능별로 worktree 생성: `EnterWorktree(name: "feat/feature-map-mvp")` → 그 안에서 N커밋
3. worktree 작업 완료 시 **머지(스쿼시 머지 절대 금지, no-ff 일반 merge)**: `git merge --no-ff feat/feature-map-mvp` (대상은 `1.0.0` 브랜치)
4. `1.0.0`에서 통합 테스트 후 `dev` ← `1.0.0` 머지 (`--no-ff`)
5. QA 사인오프 시 `main` ← `dev` 머지 (`--no-ff`)
6. 앱스토어 배포 완료 시 `release` ← `main` 머지 + 태그 (`v1.0.0`)

### 6.2 절대 규칙

- **스쿼시 머지 금지**: 모든 머지는 `--no-ff` (merge commit 보존). 작업 이력을 남긴다.
- **하나의 worktree 브랜치 = 하나의 기능 단위**: 너무 큰 작업은 N개로 쪼갠다. 각 브랜치 안에서는 N개 커밋 OK.
- **force push 금지** (`main`/`release`/`dev`).
- **--no-verify 금지**: pre-commit 훅 우회 금지.
- **`AGENTS.md` 또는 본 `CLAUDE.md`를 우회하는 머지 금지**: 리드의 코드리뷰 통과가 머지 조건.

### 6.3 커밋 규칙

- 커밋 메시지: `[<area>] <imperative subject>` (한국어/영어 자유)
  - area 예: `ios`, `server`, `design`, `docs`, `fastlane`, `infra`, `qa`
- 본문은 *왜(Why)*를 설명. 무엇(What)은 diff로 충분.
- 코드 변경 + 문서 변경은 같은 커밋에 묶어도 OK.

## 7. 빌드 번호 규칙

빌드 번호 포맷은 **`YYMMDD_HHMM`** (KST 기준):
- 예: `260504_1615`
- 마케팅 버전(`CFBundleShortVersionString`): SemVer (1.0.0).
- 빌드 번호(`CFBundleVersion`): `YYMMDD_HHMM`. 사람이 읽어도 어느 빌드인지 즉시 식별 가능.
- fastlane이 자동 주입: `set_info_plist_value(path: "...Info.plist", key: "CFBundleVersion", value: Time.now.strftime("%y%m%d_%H%M"))`.

## 8. fastlane 배포 (FearIndex-iOS 패턴 차용)

`/Users/imyeongjin/Desktop/FearIndex-iOS/fastlane/Fastfile`을 레퍼런스로 활용. 핵심 lane:

| lane | 목적 |
|---|---|
| `sync_certificates` | match로 인증서/프로비저닝 동기화 |
| `bump_build` | `CFBundleVersion`을 `YYMMDD_HHMM`으로 갱신 |
| `beta` | TestFlight 업로드 (archive → upload) |
| `submit_for_review` | App Store 심사 제출 (자동 출시) |
| `refresh_dsyms` | dSYM Crashlytics 업로드 |
| `screenshots` | 시뮬레이터 스크린샷 6개 언어 일괄 생성 |
| `upload_metadata` | 6개 언어 메타데이터(설명/키워드/whatsnew) 업로드 |

- `fastlane/Appfile`: `app_identifier "th1ngjin.MatchaMap"`, `apple_id "<env>"`, `team_id "<env>"`.
- `fastlane/metadata/{ko,en-US,en-GB,de-DE,ja,fr-FR}/`: 언어별 메타데이터 디렉토리.
- API Key는 `~/.env-vault/projects/matchamap-ios/`에 보관, fastlane 시작 시 `setup_api_key` 헬퍼가 환경변수에서 로드.

## 9. 보안 / 시크릿 관리

- 본 레포는 **Public 공개 가능** (CodeRabbit AI 리뷰를 자유롭게 돌리기 위함).
- 그러나 시크릿은 **절대 본 레포에 커밋 금지**.
- 시크릿 보관소: `https://github.com/thingineeer/thingineeer-env` 의 `projects/matchamap-ios/` 폴더.
- 로컬 경로: `~/.env-vault/projects/matchamap-ios/`.
- 본 레포에서 시크릿 참조 시 **반드시 환경변수 또는 symlink 통해서**:
  ```sh
  ln -s ~/.env-vault/projects/matchamap-ios/.env .env
  ```
- `.gitignore`로 `.env`, `GoogleService-Info.plist`(실값), `*.p8`, `*.cer`, `*.mobileprovision`, `fastlane/.env*`, `**/AuthKey_*.p8` 차단.
- `.env.example` 파일은 OK (실값 없는 키만).

## 10. CodeRabbit AI 리뷰

- `.coderabbit.yaml`로 한국어 리뷰 + path별 instructions 설정.
- 외부 PR + dev/main 대상 PR에 자동 리뷰 활성화.
- 리뷰 의견은 **수용/거부를 명시**해서 답변. 거부 시 *왜*를 함께 적는다 (`superpowers:receiving-code-review` 스킬 참조).

## 11. 애드몹 (수익화)

- **MVP**: AdMob — 배너 1슬롯(맵 하단), 인터스티셜 1슬롯(스토어 상세 진입 시 N회마다), 보상형 1슬롯(도감 잠금 해제).
- 광고 단위 ID는 `~/.env-vault/projects/matchamap-ios/admob.json`.
- ATT(App Tracking Transparency) 프롬프트 필수. 다국어 카피.
- 광고 노출 정책: 첫 화면 노출 금지, 첫 사용 60초 동안 광고 금지(UX 보호).

## 12. 다국어

- String Catalog 6개 언어: `ko`, `en-US`, `en-GB`, `de-DE`, `ja`, `fr-FR`.
- 디자인 단계에서 가장 긴 카피(독일어) 기준으로 레이아웃 검증.
- `qa-localization` 에이전트가 catalog의 누락 키와 길이 오버플로우를 회귀.

## 13. Ralph Loop 자율 작업

장시간(5–10시간) 자율 반복 코딩이 필요한 작업은 `ralph-loop` 플러그인의 `/ralph-loop` 또는 본 프로젝트의 `loop` 스킬을 사용. 멈춤 조건과 산출물을 명확히 정의한 후 시작.

## 14. 세션 시작 체크리스트

1. 본 `CLAUDE.md` 읽기
2. `.claude/memory/MEMORY.md` 읽기
3. 자신의 에이전트 정의 `.claude/agents/{내이름}.md` 읽기
4. `git status` + `git log --oneline -10`
5. 진행 중 태스크 확인: `TaskList`
6. 메시지 인박스 확인 (자동 전달되지만 누락 가능)

---

생성: 2026-05-04 · Owner: po-lead · Reviewer: ios-lead
