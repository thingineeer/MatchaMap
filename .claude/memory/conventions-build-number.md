---
name: conventions-build-number
description: 빌드 번호 포맷은 YYMMDD_HHMM(KST). fastlane bump_build lane이 자동 주입
type: feedback
---

**규칙**: `CFBundleVersion = $(date +"%y%m%d_%H%M")` (KST 기준).

**예시**: `260504_1615` (2026년 5월 4일 16시 15분).

**Why:**
- 사용자가 "앱 빌드 번호는 260504_1615 이런식으로 날짜 시간으로 구분하고 싶다"고 명시.
- 사람이 읽었을 때 어느 시점 빌드인지 즉시 식별 가능. 자동 증가 정수보다 훨씬 디버깅에 유리.

**자동화**:
- `fastlane/Fastfile`의 `bump_build` lane이 매 빌드 직전 `set_info_plist_value`로 주입.
- TZ는 KST(`Asia/Seoul`) 강제. CI 환경에서도 동일.

**How to apply:**
- 수동 빌드 시에도 Xcode → Target → Build Settings → CFBundleVersion 수동 설정 금지. 반드시 fastlane 통과.
- App Store Connect에는 정수형 빌드 번호도 받지만, "마침표/언더스코어/하이픈" 포함된 문자열도 허용 — 본 포맷 OK.
