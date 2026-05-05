# MatchaMap v1.0.0 — Deployment Readiness

> Phase 5 직전 사용자(`po-lead` + `imyeongjin`)가 직접 처리해야 할 항목 일괄.
> 모든 자동화 가능한 작업은 16-에이전트 팀이 완료. 본 문서는 *사용자 손이 필요한* 항목만 담음.

생성: 2026-05-05 · Owner: po-lead · Reviewer: ios-lead

---

## A. Apple Developer Portal ✅ COMPLETED 2026-05-05

### A-1. APNs Auth Key (.p8) — ✅ vault 적재 완료
- `WADW3XGZWW` (fearindexPushKey) — Team Scoped (All topics) / Sandbox & Production
- Apple 팀(8Q4H7X3Q58) 내 모든 Bundle ID에 작동 — `th1ngjin.MatchaMap` 포함.
- ✅ vault 복사 완료: `~/.env-vault/projects/matchamap-ios/AuthKey_WADW3XGZWW.p8` (private repo 커밋됨)

**잔여 (사용자 직접 1분):** Firebase 콘솔 → MatchaMapAPP → 프로젝트 설정 → Cloud Messaging → APNs 인증 키 → 업로드 (.p8 + KeyID `WADW3XGZWW` + Team ID `8Q4H7X3Q58`)

### A-2. DeviceCheck Key (.p8) — ✅ 발급 + vault 적재 완료
- ✅ Apple Developer Portal에서 신규 발급: `MatchaMap DeviceCheck`
- ✅ KeyID: `GZ8UP8C6Y6`
- ✅ vault: `~/.env-vault/projects/matchamap-ios/AuthKey_GZ8UP8C6Y6.p8` (private repo 커밋됨)

**잔여 (사용자 직접 1분):** Firebase 콘솔 → App Check → MatchaMap iOS → DeviceCheck → 업로드 (.p8 + KeyID `GZ8UP8C6Y6` + Team ID `8Q4H7X3Q58` + Token TTL 1 hour) → 저장
(Firebase Console DeviceCheck UI는 Angular validator가 native file picker만 허용하여 자동 업로드 차단됨)

### A-3. App Store Connect 앱 — ✅ 생성 완료
- ✅ App 이름: 말차맵 / Apple ID: `6766536774` / Bundle ID: `th1ngjin.MatchaMap` / 기본 언어: 한국어 / SKU: `matchamap-ios-v1` / 사용자 액세스 권한: 전체 액세스
- ✅ App Identifier 등록(th1ngjin.MatchaMap) + App Attest + Push Notifications + Sign In with Apple capabilities 활성화
- ✅ vault `.env`에 `APP_STORE_CONNECT_APPLE_ID=6766536774` 추가

### A-4. App Store Connect API Key — ✅ 발급 + vault 적재 완료
- ✅ 키 이름: `MatchaMap-CI`, 권한: 관리자
- ✅ KeyID: `7HY84GW35N`
- ✅ Issuer ID: `e5ea7eb2-038f-46e0-91c7-719bb0c07b2e`
- ✅ vault: `~/.env-vault/projects/matchamap-ios/AuthKey_7HY84GW35N.p8` (private repo 커밋됨)
- ✅ vault `.env` 환경변수: `APP_STORE_CONNECT_API_KEY_ID` / `APP_STORE_CONNECT_API_ISSUER_ID` / `APP_STORE_CONNECT_API_KEY_PATH` / `APP_STORE_CONNECT_TEAM_ID`

---

## B. AdMob 콘솔 ✅ COMPLETED 2026-05-05

### B-1. SSV Callback URL — ✅ 등록 완료
- AdMob "publisher-별 SSV 키 발급"은 존재하지 않음 (Google 공통 ECDSA 키, `gstatic.com/admob/reward/verifier-keys.json`).
- 실제 작업: Rewarded-Collection 광고 단위 → 고급 설정 → 서버 측 확인 → Callback URL 등록.
- ✅ 등록 URL: `https://asia-northeast3-one-problem-app.cloudfunctions.net/verifyAdMobSsvCallback`
- ✅ `verifyAdMobSsvCallback` HTTPS 함수 deploy 완료 (asia-northeast3, public invoker, ECDSA 검증 + 1시간 키 캐시 + idempotent rewardedReceipts).
- AdMob 콘솔 "URL 확인" 검증 PASS + 페이지 reload로 영속성 확인 완료.

### B-2. AdMob 검수 (옵션, 자동)
- 첫 광고 노출 후 24-48시간 내 AdMob이 앱 정책 검수 (콘솔 이메일 도착)
- ATT 프롬프트 카피 6언어 정합 확인

---

## C. Google Cloud Console — Maps + Places ✅ COMPLETED 2026-05-05

### C-1. iOS Key — ✅ 제한 적용 완료
- `AIzaSyCRdA5oGuL5ZNfZ1BTs1Jn42XGEOty7Dpk` (Firebase 자동 생성 키 재사용)
- Application 제한: **iOS 앱 + Bundle ID `th1ngjin.MatchaMap`**
- API 제한: **27개** (Firebase 25개 + Maps SDK for iOS + Places API)
- gcloud로 적용 완료. updateTime 2026-05-05T12:56:34Z.
- 사용처: iOS 앱의 `GMSServices.provideAPIKey()`, Places SDK 호출.
- Phase 5 잔여: `FeatureMap/MapView.swift`의 `// TODO(Phase5): GMSMapView 교체` 활성화.

### C-2. Server Key — ✅ 신규 발급 완료
- 신규 키 `AIzaSyDLd18Ztp1MyWZjdFTYwb7wLDagzCDWO3Q` (vault api-keys.json `places_server_key`)
- 이름: "Places Server Key (Cloud Functions)"
- Application 제한: 없음 (Cloud Functions egress IP 동적)
- API 제한: **Places API only**
- ✅ Firebase secret `GOOGLE_PLACES_API_KEY` v2 갱신 + `mergeStoreSearch` 재배포 완료.
- vault `.env`: `GMS_API_KEY_IOS` + `GOOGLE_PLACES_API_KEY` 추가됨.

---

## D. fastlane match Git Repo ✅ PARTIAL 2026-05-05

### D-1. match git repo — ✅ 생성 + vault 갱신 완료
- ✅ GitHub Private repo: https://github.com/thingineeer/matchamap-ios-certificates
- ✅ `MATCH_GIT_URL` + `MATCH_PASSWORD` (32자 random) → vault `.env` 추가됨

### 잔여 (사용자 처리, ~30분)
- 첫 실행: `bundle exec fastlane match appstore --readonly false` (인증서 + 프로비저닝 생성 + 암호화 push) — ASC API Key 필요 (§A-4)
- 이후 모든 머신: `bundle exec fastlane sync_certificates` (readonly)

---

## E. Cloud Monitoring 알림 (server-lead)

ADR-303 §5에 따른 MAU 임계 사전 경보:

### E-1. Auth 비용 알림
1. https://console.cloud.google.com/monitoring → Alerting Policy → "+ CREATE POLICY"
2. Metric: `firebase.googleapis.com/auth/user_count`
3. Threshold: 40,000 (Spark plan은 50K, 80% 시점 알림)
4. Notification Channel: imyeongjin@gmail.com

### E-2. Functions 호출 횟수 알림
1. Metric: `cloudfunctions.googleapis.com/function/execution_count`
2. Threshold: 일 100,000건 (Blaze 비용 폭발 방지)

---

## F. Marketing/Support/Privacy URL 호스팅 — TODO (사용자)

**상태**: GitHub Pages public repo 생성은 사용자 권한 필요해서 보류 (이번 자동화 세션에서 차단됨).

### F-1. URL 호스팅 (사용자 직접 진행)
1. GitHub에 public repo 생성: `thingineeer/matchamap` (homepage URL: `https://thingineeer.github.io/matchamap`)
2. `index.md`, `support.md`, `privacy.md` 3개 페이지 작성 (Privacy 정책은 6개국 컴플라이언스 — GDPR + CCPA + 개인정보보호법)
3. Settings → Pages → Source: main branch root → Enable
4. App Store Connect 메타데이터에서 URL 갱신:
   - Marketing URL: `https://thingineeer.github.io/matchamap`
   - Support URL: `https://thingineeer.github.io/matchamap/support`
   - Privacy URL: `https://thingineeer.github.io/matchamap/privacy`
5. `fastlane/metadata/{ko,en-US,...}/marketing_url.txt` `support_url.txt` `privacy_url.txt` 갱신.

**중요**: Privacy URL은 심사 제출 전 반드시 작동해야 함 (Apple 5.1.1 거절 사유).

## F-bis. 6언어 번역 검수 (qa-localization 보강)

자동 생성된 String Catalog 6언어 번역 → 네이티브 검수:
- ko: imyeongjin (본인)
- en-US: 영어 네이티브 1인 검수 권장 (LinkedIn 또는 Crowdin)
- en-GB: en-US 베이스에서 minor 변경만
- de-DE: 독일어 네이티브 (Fiverr/ProZ 5만원~)
- ja: 일본어 네이티브 (말차 도메인 친밀자 권장)
- fr-FR: 프랑스어 네이티브

검수 완료 시 `docs/qa/localization-audit-v1.0.0.md` 갱신.

---

## G. Privacy Manifest ✅ COMPLETED 2026-05-05

`MatchaMap/PrivacyInfo.xcprivacy` 작성 완료 (iOS 17+ 심사 필수):
- 4 NSPrivacyAccessedAPI: UserDefaults / FileTimestamp / DiskSpace / SystemBootTime
- 11 NSPrivacyCollectedDataType: UserID / Email / Name / CoarseLocation / PhotosOrVideos / OtherUserContent / ProductInteraction / AdvertisingData / DeviceID / CrashData / PerformanceData
- 4 NSPrivacyTrackingDomains: googletagmanager.com / googleadservices.com / doubleclick.net / googlesyndication.com
- 1.0.0 브랜치 머지 완료 (커밋 `c6ccee7` 기준)

원본 템플릿:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <!-- UserDefaults: 광고 경험 + ATT 상태 -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array><string>CA92.1</string></array>
        </dict>
        <!-- File timestamp: 도감 메모리 페이지 -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array><string>C617.1</string></array>
        </dict>
    </array>
    <key>NSPrivacyTracking</key>
    <true/>
    <key>NSPrivacyTrackingDomains</key>
    <array>
        <string>googletagmanager.com</string>
        <string>googleadservices.com</string>
        <string>doubleclick.net</string>
    </array>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <!-- 사용자 식별자 (Firebase Auth UID) -->
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeUserID</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
        </dict>
        <!-- 위치 (대략) -->
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeCoarseLocation</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
        </dict>
    </array>
</dict>
</plist>
```

---

## H. App Store 심사 사전 체크 (qa-lead)

`docs/qa/checklists/app-store-review.md` 항목 모두 PASS 검증 후 `submit_for_review`:

- [ ] ATT 프롬프트 6언어 (ko/en-US/en-GB/de-DE/ja/fr-FR) 모두 등록
- [ ] Sign in with Apple — 이름 자동 채움 + 실제 이름 미저장 옵션 동작
- [ ] AdMob 첫 60초 광고 차단 가드 동작 검증
- [ ] 위치 권한 거부 시 fallback (수동 검색)
- [ ] Privacy Manifest 누락 키 0
- [ ] Crashlytics 빈 대시보드 (첫 출시 baseline)
- [ ] App Store Connect "App Privacy" 섹션 채움 (Privacy Manifest 자동 매핑 + 수기 보강)
- [ ] 4-K 매장 데이터 페이지 — 거짓 정보 0 (Apple 1.1.6)

---

## 자동 완료 항목 (참고)

✅ Firebase 프로젝트 생성 (MatchaMapAPP, asia-northeast3)
✅ Firestore Native Mode + Storage + Auth Apple Provider 활성화
✅ App Check + App Attest 등록 (Team 8Q4H7X3Q58)
✅ Hosting + AASA 배포 (Passkey 작동)
✅ firestore.rules + storage.rules + 21 indexes deploy
✅ Cloud Functions 14개 deploy (asia-northeast3, callable + scheduled + triggers)
✅ AdMob 앱 + 광고 단위 3개 (Banner-Map, Interstitial-Store, Rewarded-Collection)
✅ iOS 앱 빌드 PASS (Splash + Login + 4탭 + 6 Feature 모듈)
✅ String Catalog 6언어 (자동 추출)
✅ fastlane lane 7개 (sync_certificates, bump_build, beta, submit_for_review, refresh_dsyms, screenshots, upload_metadata)
✅ App Store 메타데이터 6언어 × 9파일

---

## 최종 출시 시퀀스

1. 위 §A-§H 항목 모두 처리 (**예상 1-2일**)
2. 시뮬레이터 매트릭스 회귀 (qa-functional, **반나절**)
3. `bundle exec fastlane bump_build` → `bundle exec fastlane beta`
4. TestFlight 외부 테스터 5-10명 1주
5. 회귀 결함 수정 → `bundle exec fastlane beta` 재업로드
6. `bundle exec fastlane submit_for_review`
7. Apple 심사 24-72시간
8. 출시 후: `git checkout release && git merge --no-ff main && git tag v1.0.0 && git push --tags`

---

생성: 2026-05-05 · Owner: po-lead · Last review: ios-lead
