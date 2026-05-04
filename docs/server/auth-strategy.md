# Auth Strategy — Apple Sign In + Passkey

- **작성**: `server-auth` · 2026-05-04
- **상태**: Phase 2 — ADR-303 산출물
- **상위 결정**: [ADR-303](../architecture/ADR-303-app-check-security-rules.md), [ADR-301](../architecture/ADR-301-backend-choice.md)
- **iOS 페어링**: `ios-auth-monetize` (Phase 3)

## 1. 결정 요약

| 항목 | 결정 |
|---|---|
| Provider | **Apple Sign In** (1차) + **Passkey** (선택, iOS 16+) |
| 이메일/비밀번호 | **사용 안 함** (PRD § 비범위) |
| 익명 로그인 | **사용 안 함** (App Check 회피 위험) |
| 토큰 저장소 | iOS Keychain (Firebase Auth SDK 자동 처리) |
| 다중 디바이스 | Apple ID 동일 시 자동 동기화 + Passkey iCloud Keychain 공유 |
| 세션 만료 | Firebase Auth ID Token 1시간 자동 갱신 (refresh token 영구) |
| AASA 도메인 | `https://matchamap.app/.well-known/apple-app-site-association` |

## 2. Apple Sign In Provider

### 2.1 Firebase Console 셋업 (server-auth Phase 2 작업)

1. Firebase Console > **Authentication** > Sign-in method > **Apple** → Enable.
2. Service ID: `th1ngjin.MatchaMap.SignInService` (Apple Developer 측 등록 후 입력).
3. Apple Team ID: vault에서 빌드 타임 주입 (`~/.env-vault/projects/matchamap-ios/apple/team_id.txt`).
4. Key ID: Apple Developer Account에서 Sign in with Apple 키 발급 후 입력.
5. Private Key (.p8): vault에서 로드 → 콘솔 paste (절대 레포 커밋 금지).
6. Authorized domains: `matchamap.app`, `matchamapapp.web.app`, `matchamapapp.firebaseapp.com`.

### 2.2 Apple Developer Portal 셋업

1. **App ID** `th1ngjin.MatchaMap` → Capabilities → Sign In with Apple **체크**.
2. **Service ID** `th1ngjin.MatchaMap.SignInService` 신규 생성 → Sign In with Apple **체크** + Configure:
   - Primary App ID: `th1ngjin.MatchaMap`.
   - Domains and Subdomains: `matchamap.app`.
   - Return URLs: `https://matchamapapp.firebaseapp.com/__/auth/handler`.
3. **Key** 생성 → Sign In with Apple **체크** → Configure → Primary App ID = `th1ngjin.MatchaMap` → 키 다운로드 (.p8) → vault에 저장.

### 2.3 iOS 클라 흐름 (ios-auth-monetize Phase 3)

```swift
// 의사코드 — 실제 구현은 ios-auth-monetize 책임
let request = ASAuthorizationAppleIDProvider().createRequest()
request.requestedScopes = [.fullName, .email]
request.nonce = sha256(rawNonce)  // CSRF 방지

let controller = ASAuthorizationController(authorizationRequests: [request])
controller.delegate = self
controller.performRequests()

// Authorization 성공 시
let credential = appleIDCredential
let firebaseCredential = OAuthProvider.credential(
  withProviderID: "apple.com",
  idToken: credential.identityToken,
  rawNonce: rawNonce
)
Auth.auth().signIn(with: firebaseCredential) { authResult, error in
  // authResult.user.uid → Firestore users/{uid} 문서 트리거(onCreateUser server-functions)
}
```

### 2.4 Apple Private Email Relay 처리

- Apple Sign In 사용자가 "Hide My Email" 옵션 선택 시 Firebase는 `<random>@privaterelay.appleid.com` 형태의 이메일 받음.
- 본 이메일은 Firebase Auth user.email에 저장되지만 **사용 금지** — 푸시는 FCM token 기반, 마케팅 메일은 미수행.
- `users/{uid}.photoURL`은 Apple 자동 발급 X (Apple Sign In은 photo 미포함). 디폴트 아바타 사용.

### 2.5 첫 로그인 vs 재로그인

- 첫 로그인: `ASAuthorizationAppleIDCredential`이 fullName + email 1회만 제공 (Apple 정책).
  → 클라가 Firestore `users/{uid}` 생성 시 `displayName`을 fullName.givenName + familyName 조합으로 set.
  → 이후 로그인에서는 fullName이 nil이므로 첫 회 set이 critical (`onCreateUser` Functions가 backup으로 `displayName="말차러버#<random4>"` 폴백).
- 재로그인: idToken만 받아 Firebase Auth 재발급. `users/{uid}` 변경 없음.

## 3. Passkey (WebAuthN)

### 3.1 흐름 (iOS 16+)

iOS 26.2 디플로이 타깃이므로 모든 사용자 가능.

1. **등록 (가입 직후 Apple Sign In 후)**:
   - 클라가 콜러블 `passkeyChallenge()` 호출 (server-functions Phase 3) → 서버가 challenge 생성 + `users/{uid}/private/passkeyChallenge` 저장 (5분 TTL).
   - iOS `ASAuthorizationPlatformPublicKeyCredentialProvider`로 Passkey 생성 (Secure Enclave + iCloud Keychain 동기화).
   - 클라가 `passkeyVerify(attestation)` 콜러블에 attestation 전송 → 서버가 검증 후 `users/{uid}/private/passkeyCredentials/{credentialId}`에 저장.
2. **로그인 (다른 디바이스 또는 재설치 후)**:
   - 클라가 `passkeyChallenge()` 호출 → challenge 받음.
   - iOS Passkey 인증 시트 표시 (Face ID/Touch ID).
   - 클라가 `passkeyVerify(assertion)` 호출 → 서버가 challenge + attestation 정합 검증 → Firebase **custom token** 발급 → `Auth.auth().signIn(withCustomToken:)`.

### 3.2 Firebase Auth 통합 — Custom Token 발급

Firebase Auth는 Passkey를 직접 지원하지 않음. **Functions가 WebAuthN 검증 후 custom token을 발급**하여 Firebase Auth 컨텍스트에 진입.

```ts
// firebase-functions/src/auth/passkeyVerify.ts (Phase 3 server-functions 작성 — 개요)
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { CALLABLE_DEFAULTS } from '../utils/region';
import { auth as adminAuth } from '../utils/admin';
// import * as fido2 from 'fido2-lib';  // WebAuthN 검증 라이브러리

export const passkeyVerify = onCall(CALLABLE_DEFAULTS, async (req) => {
  // 1) challenge 검증 (Firestore에서 5분 TTL doc fetch)
  // 2) WebAuthN attestation/assertion 서명 검증
  // 3) credential 저장 또는 lookup
  // 4) Firebase custom token 발급
  const customToken = await adminAuth().createCustomToken(uid, { passkey: true });
  return { customToken };
});
```

> 본 함수의 실제 구현은 `server-functions` Phase 3 책임. ADR-303은 흐름 + 보안 정책만 결정.

### 3.3 Passkey AASA 도메인

- `https://matchamap.app/.well-known/apple-app-site-association`의 `webcredentials.apps`에 `<TEAM_ID>.th1ngjin.MatchaMap` 포함 필수.
- 도메인 캐시는 iOS swcd가 ~24h 갱신. 변경 시 사용자 디바이스에서 즉시 반영 안 됨에 주의.

### 3.4 Passkey 미지원 디바이스 fallback

- iOS 16 미만은 디플로이 타깃에 의해 차단되므로 fallback 불필요.
- iCloud Keychain off 사용자: Passkey 등록 시도 시 시스템 다이얼로그가 활성화 안내. 사용자가 거부하면 Apple Sign In만 사용 (Passkey 등록 옵션은 설정에서 추후 다시 가능).

## 4. 세션 유지 + 다중 디바이스

### 4.1 토큰 정책

- **ID Token**: 1시간 만료 → Firebase Auth SDK가 자동 갱신.
- **Refresh Token**: 영구 (사용자가 명시 로그아웃 또는 계정 삭제 시까지).
- **Custom Token (Passkey)**: 1시간 발급, refresh는 Apple/Passkey 재인증 필요 — UX는 Apple Sign In 흐름에 위임 (재로그인 시 Apple 1탭).

### 4.2 다중 디바이스 동기화

- **Apple ID 동일** 시: Firebase는 동일 uid 발급 (Apple ID가 unique key) → `users/{uid}` 자동 공유.
- **Passkey iCloud Keychain**: iOS가 자동 동기화. 새 디바이스에서 Apple Sign In 로그인 후 Passkey도 즉시 사용 가능.
- **FCM 토큰 다중**: `users/{uid}/fcmTokens/{tokenId}`에 디바이스별 토큰 저장 (schema.md §1.1 + push-payload.md). 푸시 발송 시 모든 토큰에 fanout.

## 5. 보안 정책

### 5.1 nonce + CSRF 방지

- Apple Sign In 요청 시 `request.nonce = sha256(rawNonce)` 강제.
- 서버 측 `signIn` 호출 시 rawNonce 일치 검증 (Firebase SDK가 자동).

### 5.2 Apple ID Token 검증 (옵션 (b) 도입 시)

- Apple JWKS 키는 ~6개월마다 회전. Functions가 `https://appleid.apple.com/auth/keys`를 캐시 (24h TTL) + 검증 실패 시 강제 refresh.
- 검증 실패 급증 감지 시 환경변수 `APPLE_JWKS_FORCE_REFRESH=true`로 즉시 갱신 (ADR-303 §9.2).

### 5.3 sign-out 정책

- iOS 클라 sign-out → Firebase Auth `signOut()` 호출 → ID/Refresh Token 즉시 무효화.
- FCM 토큰은 별도 정리 — `users/{uid}/fcmTokens/{currentDeviceTokenId}` 삭제 (클라가 sign-out 직전 호출).
- Apple Sign In credential은 OS 레벨에서 유지 — 같은 Apple ID로 재로그인은 1탭.

## 6. 계정 삭제 (ADR-303 §6 정합)

- 삭제 메뉴: 설정 > 계정 > **계정 삭제**.
- 흐름: 콜러블 `requestAccountDeletion()` (확인 토큰) → `confirmAccountDeletion(token)` → Auth `deleteUser(uid)` → onUserDelete 트리거가 모든 데이터 삭제.
- Apple 정책 정합: Apple Developer가 계정 삭제 메뉴를 review 시 검증. 메뉴 위치는 PRD §3 / handoff-mapping.md "설정" 화면에 정의.

## 7. 비용 (ADR-303 §5 인용)

- MVP: Identity Platform 활성 (Apple Provider 자동 활성). MAU 50K까지 무료.
- MAU 50K 초과: $0.0055/MAU (Standard tier — Apple Sign In은 standard 분류).
- 절감 옵션 (옵션 (b)/(c)): ADR-303 §5.6 참조.

## 8. 인시던트 대응 (Playbook)

| 시나리오 | 1차 대응 | 에스컬레이션 |
|---|---|---|
| Apple Sign In Provider 응답 실패 | Apple Status Page 확인 + iOS 클라 retry 정책 | Apple Developer 지원 티켓 |
| AASA 404 | Hosting 배포 검증 + curl 응답 확인 | server-auth Slack |
| Passkey 등록 실패 | 디바이스 iCloud Keychain 상태 확인 | 사용자 에 안내 메시지 |
| Token 검증 실패 급증 | Apple JWKS 강제 refresh + Cloud Logging 분석 | server-auth + server-lead |
| 계정 삭제 부분 실패 | `_deletion_progress` 진단 + scheduler/finishStaleDeletions 가속 | server-auth |

## 9. 후속 작업 (Phase 3+)

- [ ] Passkey 등록/검증 콜러블 실 구현 (server-functions Phase 3).
- [ ] iOS 클라 ASAuthorizationController 통합 (ios-auth-monetize Phase 3).
- [ ] AASA 빌드 타임 Team ID 치환 스크립트 (`scripts/build-aasa.sh`).
- [ ] 휴면 30일 자동 익명화 정책 (ADR-303 §5.6 옵션 (c) — MAU 40K 도달 시 활성화).
- [ ] Apple Sign In 익명 + 통계 분리 — observability §1 user property `auth_method` 채움.
