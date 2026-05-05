# fastlane Operations — 말차맵 iOS

> Phase 5 릴리스 자동화. 7개 핵심 lane + 보조 1개. FearIndex-iOS 검증된 패턴 차용.

---

## 1. 사전 셋업

### 1.1 Ruby + bundler

```sh
ruby -v          # 3.x 권장
gem install bundler
bundle install   # Gemfile + fastlane/Pluginfile 의존성 설치
```

### 1.2 vault symlink

시크릿 보관소: `~/.env-vault/projects/matchamap-ios/` (별도 private repo).

```sh
./scripts/setup-vault-symlinks.sh
```

연결되는 항목 (vault에 존재할 때만):
- `.env` → `./.env`, `./fastlane/.env`
- `Appfile.local`, `Matchfile.local` → `./fastlane/`
- `api_key.json` → `./fastlane/api_key.json` (ASC API JSON Key)
- `AuthKey_*.p8` → `./fastlane/`
- `GoogleService-Info.plist` → `./MatchaMap/GoogleService-Info.plist`
- `AdMob.local.xcconfig` → `./Configs/AdMob.local.xcconfig`

### 1.3 환경변수 (`fastlane/.env`)

`fastlane/.env.example`를 참고. 주요 키:

| 키 | 설명 |
|---|---|
| `APP_IDENTIFIER` | 기본값 `th1ngjin.MatchaMap` |
| `APPLE_ID` | App Store Connect Apple ID |
| `TEAM_ID` | Developer Portal team |
| `ITC_TEAM_ID` | App Store Connect team |
| `MATCH_GIT_URL` | match storage repo |
| `MATCH_PASSWORD` | match 암호화 비밀번호 |
| `ASC_API_KEY_PATH` | ASC API JSON Key 경로 (기본 vault) |

### 1.4 ASC API Key (json)

App Store Connect → Users and Access → Integrations → App Store Connect API → Generate.

`api_key.json` 포맷:
```json
{
  "key_id": "...",
  "issuer_id": "...",
  "key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----",
  "duration": 1200,
  "in_house": false
}
```

vault에 저장 후 `setup-vault-symlinks.sh`로 연결.

---

## 2. 7개 lane

전체 리스트 확인:
```sh
bundle exec fastlane lanes
```

### 2.1 `sync_certificates`

```sh
bundle exec fastlane sync_certificates
```

- match readonly 모드. 인증서/프로비저닝 프로파일을 vault git repo에서 동기화.
- ASC API Key로 인증.
- 새 디바이스 추가는 별도 절차 (`fastlane match nuke` + `match` 재실행은 사용자 승인 후에만).

### 2.2 `bump_build`

```sh
bundle exec fastlane bump_build
```

- `xcrun agvtool new-version -all "$(date +%y%m%d_%H%M)"` 실행.
- 모든 타깃의 `CFBundleVersion`을 KST 기준 `YYMMDD_HHMM`으로 갱신.
- PBXFileSystemSynchronizedRootGroup + GENERATE_INFOPLIST_FILE 환경에서 동작 (Xcode 자동 생성 plist 호환).
- 마케팅 버전(`CFBundleShortVersionString`)은 별도 lane(추후) 또는 Xcode UI에서 관리.

### 2.3 `beta` — TestFlight

```sh
bundle exec fastlane beta
bundle exec fastlane beta changelog:"v1.0.0 RC1 — 맵 검색 + 도감 잠금 해제"
```

흐름:
1. `setup_api_key_lane`
2. `sync_certificates`
3. `bump_build`
4. `build_app` (Release, app-store export, ExportOptions.plist 사용)
5. `upload_to_testflight` (skip_waiting_for_build_processing, internal only)
6. `refresh_dsyms`

산출물: `./build/ipa-out/MatchaMap.ipa`.

### 2.4 `submit_for_review`

```sh
bundle exec fastlane submit_for_review                        # 현재 프로젝트 버전 사용
bundle exec fastlane submit_for_review app_version:1.0.0      # 명시
```

- `upload_to_app_store` 호출. 바이너리는 이미 ASC에 있다고 가정 (beta lane으로 미리 업로드).
- 메타데이터 6개 언어 동기화 + precheck 실행.
- `submit_for_review: true`, `automatic_release: true` — 심사 통과 즉시 자동 출시.
- IDFA 사용/AdMob 광고/Limits Tracking 정책은 `submission_information`에 명시.

### 2.5 `refresh_dsyms`

```sh
bundle exec fastlane refresh_dsyms
```

- ASC에서 최신 dSYM zip 다운로드 → Crashlytics 업로드.
- bitcode 미사용 환경에서도 안전 (다운로드 실패 시 메시지만 출력하고 계속).
- `gsp_path: MatchaMap/GoogleService-Info.plist` 기준.

### 2.6 `screenshots`

```sh
bundle exec fastlane screenshots
```

- 6개 언어 × 3 디바이스(iPhone 17 Pro Max / iPhone 8 Plus / iPad Pro 12.9-inch) 일괄 스냅샷.
- 사전 조건: `MatchaMapUITests` 타깃에 SnapshotHelper 추가 + 테스트 케이스 작성. **Phase 5 후반**.
- 출력: `fastlane/screenshots/<lang>/<device>.png`.

### 2.7 `upload_metadata`

```sh
bundle exec fastlane upload_metadata
```

- `fastlane/metadata/{ko,en-US,en-GB,de-DE,ja,fr-FR}/`에 있는 텍스트(설명/키워드/whatsnew)만 업로드.
- 바이너리/스크린샷 스킵.

---

## 3. 보조 lane

### `doctor`

```sh
bundle exec fastlane doctor
```

- Debug 시뮬레이터 빌드 헬스체크. CI에서 가벼운 회귀 검증으로 사용.

---

## 4. 운영 워크플로 (권장)

### 4.1 RC 빌드 → TestFlight

```sh
./scripts/setup-vault-symlinks.sh
bundle install
bundle exec fastlane beta changelog:"<release notes>"
```

### 4.2 심사 제출

```sh
# 메타데이터 사전 검증
bundle exec fastlane upload_metadata

# 심사 제출 (자동 출시)
bundle exec fastlane submit_for_review app_version:1.0.0
```

### 4.3 충돌 발생 시

| 증상 | 원인 | 조치 |
|---|---|---|
| `match` certificate not found | vault git repo 미동기화 | vault repo `git pull` |
| `agvtool` no version found | xcconfig CURRENT_PROJECT_VERSION 미설정 | Xcode에서 한 번 빌드해 초기화 |
| TestFlight 업로드 거부 | 빌드 번호 중복 | `bump_build` 다시 호출 후 재빌드 |
| dSYM 업로드 실패 | bitcode 미생성 | bitcode off 환경에선 자동 dSYM 사용. 무시 가능 |

---

## 5. Phase 5 시점 사용자 승인 필요 항목

다음은 사용자(또는 PO/리드) 승인 후 직접 수행:

1. **App Store Connect API Key 발급** + vault 저장
2. **match git repo 초기화** (`fastlane match init` → 비밀번호 설정 → `fastlane match appstore`)
3. **App Store Connect 앱 생성** (Bundle ID 등록 + SKU)
4. **GoogleService-Info.plist 실값** vault 저장
5. **AdMob 광고 단위 ID** 발급 후 vault `AdMob.local.xcconfig` 저장
6. **6개 언어 메타데이터** 작성 → `fastlane/metadata/<lang>/`

위 6개가 갖춰진 후에야 실 lane 실행이 가능. 본 문서의 lane 정의는 검증되어 있으므로 시크릿 셋업만 끝나면 즉시 사용 가능.

---

생성: 2026-05-05 · Owner: ios-lead · Reviewer: po-lead
