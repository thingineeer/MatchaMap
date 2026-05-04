# 보안 규칙 가이드 — Firestore + Storage + App Check

- **작성**: `server-lead` · 2026-05-04
- **상태**: Phase 1 가이드라인 (실제 `firestore.rules` / `storage.rules`는 Phase 2에서 `server-data`/`server-auth`가 작성, server-lead 리뷰)
- **참조**: ADR-301, [docs/server/CLAUDE.md](CLAUDE.md), Phase 2의 ADR-302/303

> 본 문서는 *원칙 + 패턴 + 합의된 권한 모델*만 담는다. 실제 rules 파일의 줄 단위 코드는 server-data 스키마 사인오프 후 작성.

## 1. 절대 원칙

1. **Default Deny**: 모든 컬렉션/버킷은 `if false`가 디폴트. 명시적으로 허용한 패턴만 통과.
2. **App Check 강제**: 모든 콜러블 함수 + Firestore/Storage 클라이언트 SDK 호출은 App Check 토큰 보유 필수. (Phase 2-3, server-auth 책임)
3. **사용자 격리**: 사용자 소유 데이터는 `request.auth.uid == resource.data.uid` 또는 doc ID == uid.
4. **신뢰 경계**: 클라가 보낸 값 중 인증·권한·집계 필드(예: `likeCount`, `verified`)는 절대 신뢰하지 않음. Cloud Functions에서만 갱신.
5. **데이터 검증**: 규칙에서 타입/길이/enum 검증을 1차 방어선으로. Functions에서 비즈니스 검증.
6. **읽기도 권한 검사**: write만 보호하고 read는 풀어두는 안티패턴 금지. 사용자 개인 데이터는 read도 본인만.

## 2. 권한 모델 (ASCII)

```
┌──────────────────────────────────────────────────────────────────────┐
│                         Auth State (Firebase Auth)                    │
│   • Anonymous (X — MVP에선 미사용)                                    │
│   • Apple Sign In  → uid                                              │
│   • Passkey (custom token via Functions) → uid                        │
└──────────────────────┬───────────────────────────────────────────────┘
                       │
                       ▼
              ┌───────────────────┐
              │  request.auth.uid │
              └────────┬──────────┘
                       │
       ┌───────────────┼───────────────────────────────────────┐
       ▼               ▼                                       ▼
  ┌─────────┐    ┌──────────┐                          ┌──────────────┐
  │ users/  │    │ stores/  │                          │ reviews/     │
  │ {uid}   │    │ {storeId}│                          │ {reviewId}   │
  ├─────────┤    ├──────────┤                          ├──────────────┤
  │ R: self │    │ R: any   │                          │ R: any       │
  │ W: self │    │ W: admin │                          │ C: auth+self │
  │   - 검증│    │  (Func)  │                          │ U: author    │
  │   필드  │    │ create:  │                          │ D: author    │
  │   only  │    │  Func   │                           │ likeCount: ✗ │
  └─────────┘    └──────────┘                          └──────────────┘
       │
       ├──→ users/{uid}/wishlist/{storeId}   ─ R/W: self
       ├──→ users/{uid}/collection/{itemId}  ─ R: self, W: Func
       └──→ users/{uid}/private/...          ─ R/W: self
                                                        │
                                                        ▼
                                              ┌──────────────────┐
                                              │ Storage          │
                                              ├──────────────────┤
                                              │ users/{uid}/avatar.jpg   R:auth W:self  ≤2MB image/jpeg|png  │
                                              │ reviews/{reviewId}/{n}.jpg R:auth W:author ≤5MB image/heic|jpeg │
                                              │ stores/{storeId}/cover/{n}.jpg R:any W:admin only         │
                                              └──────────────────┘

R = read, W = write, C = create, U = update, D = delete
admin = Cloud Functions runtime (Admin SDK, 규칙 우회) — 클라이언트는 절대 admin 권한 없음
```

## 3. Firestore Rules — 패턴 카탈로그

### 3.1 헬퍼 함수 (rules 상단에 정의)

```javascript
// 의사코드 — 실제는 Phase 2에서 server-data가 작성
function isAuthed() { return request.auth != null; }
function isSelf(uid) { return isAuthed() && request.auth.uid == uid; }
function isAppCheckOk() { return request.app != null; }   // App Check enforcement on
function strLen(s, min, max) { return s is string && s.size() >= min && s.size() <= max; }
function isUnchanged(field) {
  return request.resource.data[field] == resource.data[field];
}
```

### 3.2 패턴 P1 — 사용자 본인 문서

```
match /users/{uid} {
  allow read:   if isSelf(uid) && isAppCheckOk();
  allow create: if isSelf(uid) && isAppCheckOk()
                 && request.resource.data.keys().hasOnly(['displayName','locale','createdAt'])
                 && strLen(request.resource.data.displayName, 1, 32);
  allow update: if isSelf(uid) && isAppCheckOk()
                 && isUnchanged('createdAt')
                 && isUnchanged('uid');
  allow delete: if false;  // 탈퇴는 Functions로
}
```

### 3.3 패턴 P2 — 매장(공개 read, 관리자 write)

```
match /stores/{storeId} {
  allow read:   if isAppCheckOk();
  allow write:  if false;  // Functions Admin SDK만
}
```

→ 매장 등록은 추후 Functions 콜러블 `submitStore`로 받고 모더레이션 후 admin이 write.

### 3.4 패턴 P3 — 리뷰(작성자만 update/delete)

```
match /reviews/{reviewId} {
  allow read:   if isAppCheckOk();
  allow create: if isAuthed() && isAppCheckOk()
                 && request.resource.data.uid == request.auth.uid
                 && strLen(request.resource.data.body, 1, 2000)
                 && request.resource.data.rating is int
                 && request.resource.data.rating >= 1
                 && request.resource.data.rating <= 5
                 && request.resource.data.likeCount == 0       // 클라가 0으로만 생성
                 && request.resource.data.flagged == false;
  allow update: if isAuthed() && isAppCheckOk()
                 && resource.data.uid == request.auth.uid
                 && isUnchanged('uid')
                 && isUnchanged('storeId')
                 && isUnchanged('createdAt')
                 && isUnchanged('likeCount')                   // 좋아요는 Functions만
                 && isUnchanged('flagged');                    // 모더레이션은 Functions만
  allow delete: if isAuthed() && isAppCheckOk()
                 && resource.data.uid == request.auth.uid;
}
```

### 3.5 패턴 P4 — 위시리스트(서브컬렉션, 본인 R/W)

```
match /users/{uid}/wishlist/{storeId} {
  allow read, write: if isSelf(uid) && isAppCheckOk();
}
```

### 3.6 패턴 P5 — 도감(read는 본인, write는 Functions)

```
match /users/{uid}/collection/{itemId} {
  allow read:  if isSelf(uid) && isAppCheckOk();
  allow write: if false;  // Functions가 리뷰 작성 시 fanout
}
```

### 3.7 패턴 P6 — 좋아요 토글(분리 컬렉션)

좋아요 카운터의 race condition을 피하기 위해 클라는 `likes/{reviewId}/users/{uid}` 분리 컬렉션에 마커 doc만 쓰고, Cloud Function이 `reviews.likeCount`를 증감.

```
match /likes/{reviewId}/users/{uid} {
  allow read:   if isAppCheckOk();
  allow create, delete: if isSelf(uid) && isAppCheckOk();
  allow update: if false;
}
```

## 4. Storage Rules — 패턴 카탈로그

[storage-paths.md](storage-paths.md) (server-auth 작성 예정)와 합의된 경로 컨벤션:

### 4.1 패턴 S1 — 사용자 아바타

```
match /users/{uid}/avatar.{ext} {
  allow read:  if isAuthed();
  allow write: if isSelf(uid)
                && request.resource.size < 2 * 1024 * 1024
                && request.resource.contentType.matches('image/(jpeg|png|heic)')
                && (ext == 'jpg' || ext == 'png' || ext == 'heic');
}
```

### 4.2 패턴 S2 — 리뷰 사진(작성자 업로드, 누구나 read)

```
match /reviews/{reviewId}/{photoIdx} {
  allow read:  if isAuthed();
  allow write: if isAuthed()
                && request.resource.size < 5 * 1024 * 1024
                && request.resource.contentType.matches('image/(jpeg|heic)')
                // 추가 검증: reviewId의 작성자가 request.auth.uid인지
                // → Storage Rules는 Firestore lookup이 비용 큼 → Functions 콜러블 'requestReviewPhotoUploadURL'로 짧은 만료 signed URL 발급 패턴 검토
                ;
}
```

### 4.3 패턴 S3 — 매장 커버 이미지(관리자만 write)

```
match /stores/{storeId}/cover/{filename} {
  allow read:  if true;   // 비로그인도 매장 카드 미리보기
  allow write: if false;  // Admin SDK만
}
```

### 4.4 사이즈/MIME 제한 요약

| 경로 | 최대 크기 | MIME |
|---|---|---|
| users/{uid}/avatar | 2 MB | image/jpeg, image/png, image/heic |
| reviews/{reviewId}/{n} | 5 MB | image/jpeg, image/heic |
| stores/{storeId}/cover/{n} | 5 MB | image/jpeg (admin) |

## 5. App Check 강제 — 검증 위치

App Check는 클라가 정상 앱(서명된 IPA)에서 호출한다는 attestation을 제공.

### 5.1 강제 ON 대상

- **Firestore**: `enforce()` 활성화 (Firebase Console > App Check > Firestore).
- **Cloud Storage**: `enforce()` 활성화.
- **Cloud Functions(콜러블)**: 함수 옵션에 `enforceAppCheck: true`.
- **Realtime DB**: 미사용 (off).
- **Authentication**: 일부 Provider(Apple)에 대해 reCAPTCHA App Check 통합 — Phase 2-3에서 server-auth가 결정.

### 5.2 콜러블 함수 코드 예 (server-functions가 Phase 2에 작성)

```ts
// firebase-functions/src/reviews/submit.ts (예시)
import { onCall } from "firebase-functions/v2/https";

export const submitReview = onCall(
  {
    region: "asia-northeast3",
    enforceAppCheck: true,             // ← 강제
    maxInstances: 50,
  },
  async (req) => {
    if (!req.auth) throw new HttpsError("unauthenticated", "...");
    if (!req.app)  throw new HttpsError("failed-precondition", "appcheck"); // 안전망
    // ...
  }
);
```

### 5.3 Provider 설정

- **iOS**: App Attest (iOS 14+, 우리는 iOS 26.2 타깃이므로 항상 가능). DeviceCheck는 fallback. Phase 2에서 ios-auth-monetize가 SDK 통합.
- **디버그 빌드**: Debug Provider 토큰을 Firebase Console에 등록(시뮬레이터/내부 테스트). 토큰은 `~/.env-vault/projects/matchamap-ios/appcheck-debug.txt`에 보관 — 레포 커밋 금지.

## 6. 위반 대응 (Incident Playbook)

### 6.1 의심스러운 트래픽 감지 시

1. Cloud Monitoring에서 비정상 reads/writes 스파이크 확인.
2. App Check enforcement metrics: 비정상 거부율 급증 = 정상(공격 차단). 정상 클라 거부 급증 = App Check 디버그 토큰 만료/잘못 등록.
3. 1차 대응: 의심 컬렉션 lock-down (`allow read, write: if false;`) 후 재배포.
4. 2차: Functions에서 IP/uid 단위 rate limit 추가.
5. 3차: PO에 보고 + ADR-301-incident-N 작성.

### 6.2 Rules 배포 사고

- **Rules 배포는 server-auth + server-lead 2인 리뷰 후 머지** (CLAUDE.md § 3 협업 규칙).
- `firestore.rules` 변경은 단독 PR로 분리(다른 변경과 섞지 않음).
- 배포 전 `firebase emulators:start`로 시뮬레이션 + 단위 테스트(Phase 2에 server-data/auth가 추가).

## 7. 권한 모델 합의 사항 (Phase 2 사인오프 대상)

본 가이드의 패턴 P1~P6, S1~S3는 **Phase 2 시작 시점에 server-data/server-auth/ios-lead 합의** 필수. 변경 시 ADR-303에 기록.

## 8. Changelog

| 일자 | 변경 | 작성자 |
|---|---|---|
| 2026-05-04 | 초안 (패턴 카탈로그 + 권한 다이어그램 + App Check 위치) | server-lead |
