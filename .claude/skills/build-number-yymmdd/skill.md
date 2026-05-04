---
name: build-number-yymmdd
description: 빌드 번호를 YYMMDD_HHMM(KST) 포맷으로 Info.plist에 주입한다. fastlane bump_build lane이나 수동 빌드 직전에 항상 호출. 사용자가 명시한 사람이 읽을 수 있는 빌드 번호 정책을 강제 — 자동 정수 증가/Xcode 기본값 사용 금지.
---

# 빌드 번호 (YYMMDD_HHMM)

## 규칙

`CFBundleVersion = $(TZ=Asia/Seoul date +"%y%m%d_%H%M")`

예: `260504_1615`

## 왜

사용자가 명시("앱 빌드 번호는 260504_1615 이런식으로 날짜 시간으로 구분하고 싶습니다"). 사람이 즉시 빌드 시점을 식별 가능. 자동 증가 정수보다 디버깅에 유리.

## 어디서

1. **fastlane bump_build lane** (권장):
   ```ruby
   bn = Time.now.strftime("%y%m%d_%H%M")  # ENV TZ=Asia/Seoul 전제
   set_info_plist_value(path: "MatchaMap/Info.plist", key: "CFBundleVersion", value: bn)
   ```

2. **수동 (Xcode 외 스크립트)**:
   ```sh
   TZ=Asia/Seoul plutil -replace CFBundleVersion -string "$(date +'%y%m%d_%H%M')" MatchaMap/Info.plist
   ```

3. **CI(GitHub Actions 등)**:
   ```yaml
   env:
     TZ: Asia/Seoul
   run: bundle exec fastlane bump_build
   ```

## 금지

- Xcode 자동 증가 정수 (`agvtool next-version`).
- 빈 문자열 또는 SemVer만 (`1.0.0`만 사용 금지 — 마케팅 버전과 분리해야 함).
- TZ 미지정 (UTC로 인해 한국 시간과 어긋나는 빌드 번호 생성 위험).

## App Store Connect 호환

- 정수형 빌드 번호도 받지만 마침표/언더스코어/하이픈 포함된 문자열도 허용.
- 같은 마케팅 버전(`1.0.0`)에 여러 빌드 번호 업로드 가능.
- 단, 동일 빌드 번호 재업로드는 거부 → 분 단위 포맷이라 충돌 가능성 거의 없음.
