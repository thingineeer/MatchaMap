---
name: feedback-build-number-format
description: 빌드 번호는 YYMMDD_HHMM(KST). 자동 증가 정수 또는 Xcode 기본값 사용 금지
type: feedback
---

**규칙**: 빌드 번호 = `YYMMDD_HHMM` (KST). 예: `260504_1615`.

**Why:**
- 사용자가 명시: "앱 빌드 번호는 260504_1615 이런식으로 날짜 시간으로 구분하고 싶습니다."
- 사람이 즉시 빌드 시점을 인식 가능. 클래시 발생 시 디버깅에 유리.
- Xcode 기본 정수 증가는 머신 간 비결정적이고 의미가 없다.

**How to apply:**
- fastlane `bump_build` lane이 빌드 직전 자동 주입.
- 수동 Xcode 빌드 시에도 동일 규칙 적용 (스크립트 빌드 페이즈 또는 fastlane만 사용).
- 마케팅 버전(`CFBundleShortVersionString`)은 SemVer (1.0.0). 빌드 번호와 분리.
