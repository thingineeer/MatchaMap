# App Store Review 체크리스트 — 말차맵 v1.0.0

> 출시 직전 `qa-lead`가 사인오프하기 위한 최종 체크리스트.
> Apple 가이드라인(2025 개정) + 한국 통신/광고 규제 + GDPR 반영.

## 1. 정보 권한 (Info.plist)

- [ ] `NSLocationWhenInUseUsageDescription` — 한국어 + 영어 카피 자연스러움
- [ ] `NSPhotoLibraryUsageDescription` — 리뷰 사진 첨부 목적 명시
- [ ] `NSCameraUsageDescription` — 리뷰 사진 촬영 목적 명시
- [ ] `NSUserTrackingUsageDescription` — ATT 카피 6개 언어 정합 확인
  - [ ] ko: "맞춤형 광고 제공 및 광고 효과 측정을 위해 추적 권한이 필요합니다."
  - [ ] en-US: "We use tracking to deliver personalized ads and measure performance."
  - [ ] en-GB: 동일하되 영국식 어조
  - [ ] de-DE: "Wir verwenden Tracking, um personalisierte Werbung anzuzeigen und deren Wirksamkeit zu messen."
  - [ ] ja: "パーソナライズされた広告の配信と効果測定のために、トラッキングの許可が必要です。"
  - [ ] fr-FR: "Nous utilisons le suivi pour proposer des publicités personnalisées et mesurer leur performance."
- [ ] `CFBundleVersion` = `YYMMDD_HHMM` 포맷 (KST)
- [ ] `CFBundleShortVersionString` = `1.0.0` SemVer

## 2. 인증 / 계정

- [ ] Sign in with Apple 활성화 + Capability 추가
- [ ] Passkey AASA 호스팅 (`https://matchamap.app/.well-known/apple-app-site-association`)
- [ ] **계정 삭제 메뉴 제공** (Apple 정책 강제 — 5.1.1)
- [ ] 비밀번호 미사용 (Apple/Passkey만)
- [ ] **Apple ID 비식별화 정책**
  - [ ] 이름은 사용자 입력으로 자동 채움하되 "실제 이름 공개" 토글 제공 (디폴트 OFF — 닉네임 사용 권장)
  - [ ] 이메일 hide-my-email relay 정상 처리
  - [ ] Firestore에는 `displayName` 또는 사용자가 직접 입력한 닉네임만 저장 (Apple 제공 실명 미저장 옵션 보장)

## 3. 광고 (AdMob)

- [ ] **첫 화면 광고 차단** — Splash/Login에 광고 0
- [ ] **첫 60초 광고 차단** — 콜드 스타트 후 60초간 모든 광고 호출 supress
- [ ] 인터스티셜 쿨다운 ≥ 90s
- [ ] 보상형 광고는 **자발적 시청**만 (사용자가 명시 동의 후)
- [ ] 보상형 광고 시청 중도 이탈 시 보상 미지급
- [ ] App Store Submission 정보에서 "Uses IDFA" 정확히 응답
- [ ] AdMob App ID는 vault에서 빌드 타임 주입 (코드 하드코딩 0)
- [ ] 어린이용 카테고리 미지정 (성인용 광고 회피)
- [ ] 광고 식별자(IDFA) 사용 시 ATT 사전 동의 필수

## 4. 콘텐츠 (Apple 1.1.6 — 정확성)

- [ ] **매장 데이터 정확성 게이트**
  - [ ] 매장 정보(주소/영업시간/메뉴) 출처 명시 (사용자 제출 또는 검증된 데이터)
  - [ ] 사용자 신고 기능 — "정보 오류 신고" CTA 모든 매장 페이지에 노출
  - [ ] 신고 접수 후 48시간 내 검토 SLA 명시
- [ ] 부적절 리뷰/사진 모더레이션 함수 활성화 (Cloud Functions)
- [ ] 신고/차단 기능 제공 (사용자 신고 가능)
- [ ] 차단된 사용자의 콘텐츠는 즉시 비노출

## 5. Privacy Manifest (PrivacyInfo.xcprivacy)

> Phase 5에서 `MatchaMap/PrivacyInfo.xcprivacy` 작성 시 채울 키 목록.

- [ ] `NSPrivacyTracking` = `false` (앱 자체는 추적 안 함, AdMob SDK는 별도 manifest 보유)
- [ ] `NSPrivacyTrackingDomains` = [] (추적 도메인 없음 — AdMob 도메인은 SDK manifest에서 신고)
- [ ] `NSPrivacyCollectedDataTypes`:
  - [ ] `NSPrivacyCollectedDataTypeEmailAddress` (Apple Sign In) — Linked, NotForTracking, App Functionality
  - [ ] `NSPrivacyCollectedDataTypeName` (사용자 입력) — Linked, NotForTracking, App Functionality
  - [ ] `NSPrivacyCollectedDataTypePreciseLocation` (지도) — Linked, NotForTracking, App Functionality
  - [ ] `NSPrivacyCollectedDataTypePhotosOrVideos` (리뷰 사진) — Linked, NotForTracking, App Functionality
  - [ ] `NSPrivacyCollectedDataTypeUserID` (Firebase Auth uid) — Linked, NotForTracking, App Functionality
  - [ ] `NSPrivacyCollectedDataTypeDeviceID` (광고 IDFA) — Linked, **ForTracking**, Third-Party Advertising (ATT 동의 시만)
- [ ] `NSPrivacyAccessedAPITypes`:
  - [ ] `NSPrivacyAccessedAPICategoryFileTimestamp` (사진 메타데이터) — Reason `C617.1` (앱 기능)
  - [ ] `NSPrivacyAccessedAPICategoryUserDefaults` — Reason `CA92.1` (앱 자체 설정)
  - [ ] `NSPrivacyAccessedAPICategoryDiskSpace` (다운로드 가능 여부) — 사용 시 Reason 명시

## 6. 다국어 (6개 언어)

- [ ] String Catalog 빈 키 0 (`scripts/verify-localizations.py` PASS)
- [ ] App Store metadata 6개 언어 description/keywords/whatsnew/subtitle
- [ ] 스크린샷 6개 언어 × 6.7"/6.1"/iPad

## 7. 접근성

- [ ] VoiceOver 모든 컨트롤 라벨 (각 시나리오 .md "접근성" 섹션 참조)
- [ ] Dynamic Type 호환 (Largest Accessibility Size까지)
- [ ] 컬러 대비 WCAG AA 이상 (라이트/다크 모두)
- [ ] Reduce Motion 대응 (모든 transition)

## 8. 성능

- [ ] 콜드 스타트 ≤ 1.5s (iPhone 17 Pro)
- [ ] 도시 줌 P95 ≤ 600ms
- [ ] 메모리 누수 0 (Instruments Leaks)
- [ ] 충돌 보고 0 (TestFlight 1주 베타)

## 9. 빌드

- [ ] dSYM Crashlytics 업로드 자동화 OK
- [ ] `bundle exec fastlane beta` 통과
- [ ] TestFlight 외부 테스터 1명 이상 사인오프

## 10. 게이트

| 게이트 | 통과 |
|---|---|
| QA 회귀 시트 ([regression/v1.0.0.md](../regression/v1.0.0.md)) | TBD |
| 다국어 검증 (6개 언어) | TBD |
| 접근성 검증 (VoiceOver/Dynamic Type/Contrast) | TBD |
| 광고 정책 검증 (첫 화면/60초 차단) | TBD |
| Privacy Manifest 검증 | TBD |
| 매장 데이터 정확성 (1.1.6) | TBD |
| Sign in with Apple 비식별화 | TBD |
| PO 사인오프 | TBD |
