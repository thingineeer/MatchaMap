# App Store Review 체크리스트 — 말차맵 v1.0.0

> 출시 직전 `qa-lead`가 사인오프하기 위한 최종 체크리스트.

## 1. 정보 권한 (Info.plist)

- [ ] `NSLocationWhenInUseUsageDescription` — 한국어 + 영어 카피 자연스러움
- [ ] `NSPhotoLibraryUsageDescription` — 리뷰 사진 첨부 목적 명시
- [ ] `NSCameraUsageDescription` — 리뷰 사진 촬영 목적 명시
- [ ] `NSUserTrackingUsageDescription` — ATT 카피 6개 언어
- [ ] `CFBundleVersion` = `YYMMDD_HHMM` 포맷
- [ ] `CFBundleShortVersionString` = `1.0.0` SemVer

## 2. 인증 / 계정

- [ ] Sign in with Apple 활성화 + Capability 추가
- [ ] Passkey AASA 호스팅 (`https://matchamap.app/.well-known/apple-app-site-association`)
- [ ] **계정 삭제 메뉴 제공** (Apple 정책 강제)
- [ ] 비밀번호 미사용 (Apple/Passkey만)

## 3. 광고 (AdMob)

- [ ] 첫 60초 광고 차단
- [ ] 첫 화면 광고 차단
- [ ] 인터스티셜 쿨다운 ≥ 90s
- [ ] 보상형 광고는 자발적 시청만
- [ ] App Store Submission 정보에서 "Uses IDFA" 정확히 응답
- [ ] AdMob App ID는 vault에서 빌드 타임 주입 (코드 하드코딩 0)

## 4. 콘텐츠

- [ ] 부적절 리뷰/사진 모더레이션 함수 활성화 (Cloud Functions)
- [ ] 신고/차단 기능 제공 (사용자 신고 가능)

## 5. 다국어 (6개 언어)

- [ ] String Catalog 빈 키 0
- [ ] App Store metadata 6개 언어 description/keywords/whatsnew/subtitle
- [ ] 스크린샷 6개 언어 × 6.7"/6.1"/iPad

## 6. 접근성

- [ ] VoiceOver 모든 컨트롤 라벨
- [ ] Dynamic Type 호환 (Largest Accessibility Size까지)
- [ ] 컬러 대비 WCAG AA 이상

## 7. 성능

- [ ] 콜드 스타트 ≤ 1.5s (iPhone 17)
- [ ] 도시 줌 P95 ≤ 600ms
- [ ] 메모리 누수 0 (Instruments Leaks)
- [ ] 충돌 보고 0 (TestFlight 1주 베타)

## 8. 빌드

- [ ] dSYM Crashlytics 업로드 자동화 OK
- [ ] `bundle exec fastlane beta` 통과
- [ ] TestFlight 외부 테스터 1명 이상 사인오프

## 9. 게이트

| 게이트 | 통과 |
|---|---|
| QA 회귀 시트 | TBD |
| 다국어 검증 | TBD |
| 접근성 검증 | TBD |
| 광고 정책 검증 | TBD |
| PO 사인오프 | TBD |
