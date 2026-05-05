---
name: handoff-firebase-pending
description: Firebase 라이브 셋업 진행 상태 + 사용자 직접 처리 필요 항목. Phase 5 TestFlight 직전에 일괄 처리
type: project
---

## 활성화 완료 (자동)
- iOS 앱 (Bundle: th1ngjin.MatchaMap, GOOGLE_APP_ID: 1:286698500021:ios:324ab4a9cdc8f402bcb3fc).
- GoogleService-Info.plist → vault + symlink.
- Firestore Native Mode (default) — asia-northeast3.
- Storage — asia-northeast3.
- Auth Apple Provider 사용 설정.
- App Check + App Attest 등록 (TEAM_ID 8Q4H7X3Q58).
- Hosting + AASA 배포 (https://one-problem-app.web.app/.well-known/apple-app-site-association).
- firestore.rules + storage.rules + indexes 21건 deploy.
- Secret Manager API 활성화. Secrets: ADMOB_SSV_PUBLIC_KEY (placeholder), GOOGLE_PLACES_API_KEY (placeholder), FCM_SERVICE_ACCOUNT_KEY (placeholder).

## 사용자 직접 처리 필요 (Phase 5 직전)

### A. Apple Developer Portal
1. **APNs Auth Key (.p8)** — FCM 푸시용. Apple Developer → Keys → Create. KeyID + Team ID. Firebase 콘솔 Cloud Messaging → APNs 인증서에 등록.
2. **Sign in with Apple Service ID** — iOS 앱은 native라 *불필요*. (웹에서도 사용 시 별도 등록.)
3. **DeviceCheck Key (.p8)** — Firebase App Check DeviceCheck 등록용 (App Attest fallback). Apple Developer → Keys → DeviceCheck. KeyID 등록.
4. **App Store Connect** — Phase 5에서 앱 생성 + Apple ID 발급.

### B. AdMob 콘솔 (po-growth)
1. AdMob 앱 생성 (Bundle: th1ngjin.MatchaMap).
2. ADMOB_APP_ID_IOS 발급 → vault `admob.json` 저장.
3. 광고 단위 3개 발급:
   - ADMOB_BANNER_MAP_UNIT_ID
   - ADMOB_INTERSTITIAL_STORE_UNIT_ID  
   - ADMOB_REWARDED_COLLECTION_UNIT_ID
4. SSV (Server-Side Verification) Public Key 발급 → `firebase functions:secrets:set ADMOB_SSV_PUBLIC_KEY`로 갱신.

### C. Google Maps SDK / Places API
1. Google Cloud Console → APIs & Services → Maps SDK for iOS + Places API enable.
2. API Key 발급 (iOS Bundle ID 제한 추가).
3. vault `.env` GMS_API_KEY_IOS / GMS_PLACES_API_KEY 갱신.
4. `firebase functions:secrets:set GOOGLE_PLACES_API_KEY` (Functions용 별도 키 권장).

### D. Functions 배포 실패 — Phase 5 재시도
1차 deploy `firebase deploy --only functions`에서 모든 함수 `Failed to create function in region asia-northeast3` 실패. 원인 후보:
- Cloud Build / Cloud Run / Eventarc / Pub/Sub API 활성화 IAM 전파 지연(~10분).
- 기본 Compute Engine SA 권한 누락.
- functions/package.json firebase-functions 버전 outdated 경고 — 영향 미미.

조치 (자동화):
- 5~30분 후 `firebase deploy --only functions --project one-problem-app` 재시도.
- 그래도 실패 시 `firebase deploy --debug` 출력으로 IAM 권한 사유 확인.

조치 (사용자):
- Cloud Console → IAM에서 다음 SA에 권한 부여(자동 전파 안 될 때):
  - 286698500021-compute@developer.gserviceaccount.com → Cloud Run Invoker / Eventarc Receiver
  - service-286698500021@gcf-admin-robot.iam.gserviceaccount.com → 자동 부여됨

### E. Cloud Monitoring 알림
ADR-303 §5에서 결정: MAU 40K Auth 비용 사전 경보. server-lead가 Phase 5 직전 Cloud Monitoring → Alerting Policy 설정.

## 즉시 사용 가능 (Phase 3 iOS 통합 가능)
- FirebaseAuth Apple Provider 토큰 교환.
- Firestore CRUD + 보안 규칙 enforce.
- Storage 업로드 (Default Deny rules + 5경로 패턴).
- App Check (App Attest) — iOS SDK에 AppCheckProviderFactory 등록.
- Hosting AASA — Passkey 작동 가능.

## 핸드오프 위치
본 메모 + `docs/server/firebase-setup-checklist.md` + `docs/architecture/ADR-303-app-check-security-rules.md`.
