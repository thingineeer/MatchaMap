# Firebase 콘솔 셋업 체크리스트 — MatchaMapAPP

- **작성**: `server-lead` · 2026-05-04
- **대상 프로젝트**: `MatchaMapAPP` (구 `one-problem-app` 이름 변경 재활용)
- **상태**: Phase 1 = 체크리스트만. Phase 2에서 콘솔 자동화 또는 사용자 수동 셋업으로 실 적용.
- **자동화**: `mcp__claude-in-chrome__*`로 Firebase Console 자동 점검은 Phase 2에서 (사용자 OAuth 위임 후). 본 Phase는 *문서만*.

> 각 항목은 [ ] 체크박스. 완료 시 사용자 또는 server-lead가 체크 + Changelog 갱신.

## 0. 전제

- [ ] 사용자가 Firebase 콘솔에 로그인 (devicernd.cgmsw.ai@gmail.com).
- [ ] 프로젝트 ID = `MatchaMapAPP` (정확한 ID는 콘솔 좌상단 톱니 > 프로젝트 설정에서 확인).
- [ ] 결제 계정 연결 완료 (Blaze 전환 준비, Phase 0 후반에 활성화).

## 1. 프로젝트 기본

- [ ] 프로젝트 이름 = `MatchaMapAPP` 확인.
- [ ] 프로젝트 ID 메모 → `~/.env-vault/projects/matchamap-ios/firebase-project-id.txt`.
- [ ] Default GCP resource location = `asia-northeast3` (Seoul). 한 번 설정하면 변경 불가.

## 2. iOS 앱 등록

- [ ] iOS 앱 추가:
  - Bundle ID: `th1ngjin.MatchaMap`
  - 닉네임: `MatchaMap iOS`
  - App Store ID: 추후(앱 등록 후 PO Growth가 채움)
- [ ] `GoogleService-Info.plist` 다운로드 → `~/.env-vault/projects/matchamap-ios/GoogleService-Info.plist` 보관.
  - **레포 커밋 금지**. 빌드 시 symlink로 주입: `MatchaMap/GoogleService-Info.plist → vault`.
- [ ] (옵션) `GoogleService-Info-Debug.plist` 별도 — Debug용 별도 Firebase 앱(또는 동일 앱) 사용 정책은 ios-lead가 결정.

## 3. Authentication

- [ ] **Sign-in method**:
  - [ ] Apple Provider 활성화
    - Service ID, OAuth code flow callback URL 설정 (Phase 2에서 server-auth가 진행)
    - Apple Developer Portal에서 Sign in with Apple capability 추가 — fastlane match에서 자동 처리
  - [ ] Email/Password = **Disabled** (정책: 사용 안 함)
  - [ ] Anonymous = **Disabled** (MVP에선 사용 안 함)
  - [ ] Google = Disabled (MVP에선 사용 안 함, AdMob과는 별개)
- [ ] **Authorized domains**:
  - [ ] `matchamapapp.firebaseapp.com` 기본
  - [ ] (Phase 4) 커스텀 도메인 `matchamap.app`(가칭) 등록 — Passkey AASA 호스팅용
- [ ] **MAU 알림**: Cloud Monitoring으로 50K(Spark 한도) 90% 도달 시 알림. (Phase 0 후반)

## 4. Firestore

- [ ] **모드**: **Native Mode** (Datastore Mode 절대 아님).
- [ ] **리전**: `asia-northeast3` (서울). **변경 불가**, 신중히.
- [ ] **데이터베이스 인스턴스**: `(default)` 단일.
- [ ] **보안 규칙 초기값**: 임시 lock-down — 모든 컬렉션 `if false`. (`security-rules.md` 가이드 따름)

  ```
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /{document=**} {
        allow read, write: if false;
      }
    }
  }
  ```

- [ ] **인덱스**: 빈 상태로 시작. Phase 2에서 server-data가 `firestore.indexes.json`에 정의 후 배포.
- [ ] **백업**: Firestore export 자동화는 Phase 3 (server-lead 책임). 일 1회 GCS 버킷 export.

## 5. Cloud Functions

- [ ] **2nd gen** 활성화 (Eventarc + Cloud Run 기반).
- [ ] **리전**: `asia-northeast3` 강제. 코드에서 `region: "asia-northeast3"` 옵션.
- [ ] **Node.js**: 20 LTS (또는 그 시점 최신 LTS). package.json `engines.node`에 명시.
- [ ] **TypeScript**: 5.x.
- [ ] **콜드 스타트 완화**: 핵심 콜러블(검색/검증)은 `min instances = 0`로 시작, 트래픽 임계 도달 시 1로 (server-lead 결정).
- [ ] **App Check 강제**: 모든 콜러블에 `enforceAppCheck: true`.
- [ ] **Secret Manager 통합**: Apple Service Key 등 비밀은 Secret Manager에 저장, Functions에서 `defineSecret(...)` 패턴 (Phase 2-3 server-auth 작성).

## 6. Cloud Storage

- [ ] **기본 버킷 생성**: `gs://matchamapapp.appspot.com` 또는 `gs://matchamapapp.firebasestorage.app` (콘솔이 자동 생성).
- [ ] **리전**: `asia-northeast3`. (us-* 무료 quota 포기 — 트래픽 latency 우선, ADR-301 § 리전 결정 근거 참조).
- [ ] **Storage 클래스**: Standard.
- [ ] **수명 주기 규칙**:
  - [ ] `tmp/` 경로 7일 후 자동 삭제 (서명 URL 임시 업로드용).
- [ ] **CORS**: 클라(iOS)는 SDK 사용이라 불필요. 웹 쇼케이스 사이트(Phase 4) 도메인 추가 검토.
- [ ] **보안 규칙 초기값**: lock-down (`if false`). Phase 2에 server-auth가 패턴 적용.

## 7. Hosting

- [ ] 기본 사이트 활성화 (`matchamapapp.web.app`).
- [ ] **용도**: Apple App Site Association(`apple-app-site-association`) 호스팅 — Passkey/Universal Link.
- [ ] **커스텀 도메인**: Phase 4에 PO Growth가 도메인 등록 후 추가.
- [ ] `firebase.json`의 hosting 섹션에서 `/.well-known/apple-app-site-association` MIME `application/json` + headers 설정.

## 8. App Check

- [ ] **iOS Provider**:
  - [ ] App Attest (iOS 14+, 기본).
  - [ ] DeviceCheck (fallback).
- [ ] **enforce 활성화 대상**:
  - [ ] Cloud Firestore — Enforce ON
  - [ ] Cloud Storage — Enforce ON
  - [ ] Cloud Functions(콜러블) — 코드에서 `enforceAppCheck: true`
  - [ ] Realtime DB — 미사용
  - [ ] Authentication(Apple) — Phase 2-3에 결정
- [ ] **Debug 토큰 등록**: 시뮬레이터/내부 테스트용. 토큰은 `~/.env-vault/projects/matchamap-ios/appcheck-debug.txt`. 레포 금지.
- [ ] **enforcement 시점**: Phase 2 통합 직후 *모니터링 모드*(거부율만 측정), 1주 모니터링 후 *enforce 모드* 전환.

## 9. Cloud Messaging (FCM)

- [ ] APNs Auth Key (.p8) Apple Developer Portal에서 발급.
- [ ] FCM 콘솔에 .p8 + Key ID + Team ID 업로드. (Phase 2-3 server-auth 책임)
- [ ] .p8은 `~/.env-vault/projects/matchamap-ios/AuthKey_*.p8`에 보관, 레포 금지.
- [ ] Topic 명명 규칙: `country_KR`, `country_JP`, ... 글로벌 캠페인용. `user_<uid>`는 사용자별 (toRegistrationToken으로 직접 보내는 것이 일반적).
- [ ] **Push 권한 요청 시점**: 첫 도감 잠금 해제 직후 (UX 친화). PO/iOS-lead 합의.

## 10. Analytics

- [ ] Google Analytics 활성화 (자동 — Firebase 콘솔에서 토글).
- [ ] BigQuery export 활성화 (무료 티어 내, Phase 3에 PO Growth가 분석 시작).
- [ ] **이벤트 명명 규칙**: snake_case, 도메인별 prefix(예: `store_view`, `review_submit`, `wishlist_toggle`).

## 11. Crashlytics

- [ ] 활성화. iOS 앱 첫 빌드에서 자동 등록.
- [ ] dSYM 자동 업로드 — fastlane `refresh_dsyms` lane (CLAUDE.md § 8 fastlane 참조).
- [ ] 알림: P0/P1 크래시 5건 이상 시 ios-lead + qa-lead.

## 12. 예산/모니터링

- [ ] **GCP Billing > Budgets**:
  - [ ] $20/월 알림 (50%, 90%) — server-lead 이메일.
  - [ ] $50/월 알림 (50%, 90%) — server-lead + po-lead.
  - [ ] $100/월 알림 (100%) — Supabase 재검토 트리거 #1 (ADR-301).
- [ ] **Cloud Monitoring 대시보드**: Firestore reads/writes/storage, Functions invocations/p95, Storage size/egress.
- [ ] **Uptime checks**: 핵심 콜러블 1개에 대해 분 단위 헬스체크 (Phase 3).

## 13. 보안/액세스

- [ ] **IAM**:
  - [ ] thingineeer (devicernd.cgmsw.ai@gmail.com) = Owner.
  - [ ] CI/CD 서비스 계정(Phase 3에 fastlane이 생성) = Firebase Admin + Cloud Functions Developer.
- [ ] **API Key 제한**: iOS API Key는 Bundle ID(`th1ngjin.MatchaMap`)로 제한. 다른 앱이 키 도용 차단.
- [ ] **2단계 인증**: Owner 계정 2FA 필수.

## 14. 자동화 / IaC

본 체크리스트의 콘솔 항목 중 가능한 것은 `firebase.json` + `firebase deploy`로 코드화한다 (Phase 2에서 server-functions 진행):

- [ ] `firebase.json` (Hosting/Functions/Firestore rules/Storage rules)
- [ ] `firestore.rules`
- [ ] `firestore.indexes.json`
- [ ] `storage.rules`
- [ ] `firebase-functions/` 디렉토리 (TS 소스)
- [ ] `.firebaserc` (프로젝트 alias)

콘솔에서만 가능한 것(Apple Provider Service ID, App Attest enforce 토글 등)은 본 체크리스트로 관리.

## 15. Phase 2 진입 게이트

다음이 모두 체크되어야 Phase 2 (server-data 스키마 작성) 시작:

- [ ] § 1, § 2, § 4(모드/리전), § 6(버킷 리전), § 7(Hosting 사이트), § 13(IAM) 완료.
- [ ] `GoogleService-Info.plist` 발급 + vault 보관.
- [ ] 결제 계정 준비 (Blaze 전환 직전 단계).

## 16. Changelog

| 일자 | 변경 | 작성자 |
|---|---|---|
| 2026-05-04 | 초안 (체크리스트 16개 섹션) | server-lead |
