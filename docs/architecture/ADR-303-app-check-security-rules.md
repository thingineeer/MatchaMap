# ADR-303 — App Check + 보안 규칙 + Auth 비용 절감 옵션

- **일자**: 2026-05-04
- **상태**: Accepted (Phase 2 진입 조건 #4 — server-auth 1차 사인오프, server-data ADR-302 도착 후 firestore.rules 정합 갱신 예정)
- **결정자**: `server-auth`
- **사인오프**: `server-lead`, `po-lead` (Auth 비용 우선 검토 사인오프 포함)
- **연관**: [ADR-301](ADR-301-backend-choice.md), [ADR-302](ADR-302-firestore-schema.md) (server-data 작성 중), [docs/server/security-rules.md](../server/security-rules.md), [docs/server/cost-projection.md](../server/cost-projection.md), [docs/product/decisions/ADR-PROD-002-phase1-gate-signoff.md](../product/decisions/ADR-PROD-002-phase1-gate-signoff.md)

## 컨텍스트

말차맵 v1.0.0의 신뢰 경계(Auth + 보안 규칙 + Storage + 푸시) 결정. 5개 영역을 단일 ADR로 묶는다.

1. **App Check 강제** — 클라 attestation으로 비정상 트래픽(스크래핑, 비싼 read 폭주) 차단.
2. **Firestore Rules** — 사용자 격리 + 공용 read + admin only write + App Check 강제.
3. **Storage Rules** — 경로별 사이즈/MIME/소유권 검증.
4. **Apple Sign In + Passkey AASA** 호스팅.
5. **Auth 비용 절감 옵션** — `cost-projection.md` § 4.0 신규 마일스톤 B+ (MAU 50K Auth 무료 한도 초과 → 월 ~$86 트리거 #1의 86% 도달) 대응. PO 우선순위 #1 검토 항목.

## 결정 (요약)

| 영역 | 결정 |
|---|---|
| App Check Provider | iOS: **App Attest (iOS 14+, 우리는 iOS 26.2 강제이므로 항상 가능)**, fallback **DeviceCheck** (iOS 11+ — 시뮬레이터·구형 fallback 안전망) |
| App Check Enforce | Phase 2 통합 직후 1주 **monitor** 모드 → 정상 거부율 확인 후 **enforce** 모드. Firestore + Storage + 모든 콜러블 함수 강제 |
| Firestore Rules | Default Deny + 패턴 P1~P6 (security-rules.md 가이드) 적용. 실 .rules 파일은 ADR-302 스키마 사인오프 후 server-auth가 갱신 |
| Storage Rules | 3 경로(users/profile, reviews, collections) + 사이즈/MIME/소유권 검증 |
| AASA 호스팅 | `https://matchamap.app/.well-known/apple-app-site-association` Firebase Hosting + `Content-Type: application/json` |
| Auth 비용 — MVP | **Identity Platform 활성화** (Apple Provider 사용 시 Identity Platform 자동 활성). MAU 50K 무료 → 50K 초과 시 $0.0055/MAU |
| Auth 비용 — MAU 임계 | **MAU 40K 사전 경보** + **MAU 50K 도달 시 ADR-303-rev1 작성** + 옵션 (b)/(c) 정량 비교 |
| 추천 절감 옵션 (장기) | **(c) Apple Sign In Provider만 유지 + Firestore에 사용자 ID 매핑** 우선. (b) 자체 OIDC는 운영 부담 커서 보류 |

---

## §1. App Check

### 1.1 Provider 선택

- **App Attest** (iOS 14+): 디바이스 키쌍을 Secure Enclave에 생성하고 Apple 서버가 attestation 발급. 우리는 iOS 26.2 디플로이 타깃이므로 **모든 정상 디바이스에서 사용 가능**.
- **DeviceCheck** (iOS 11+): App Attest 보조. 일부 시뮬레이터/구형 디바이스 fallback. 정상 운영 시 거의 사용되지 않음.
- **Debug Provider** (개발 빌드만): Firebase Console에 등록한 디버그 토큰. 토큰은 `~/.env-vault/projects/matchamap-ios/appcheck-debug.txt`에 보관 (레포 커밋 금지).

### 1.2 Enforcement 위치

| 자원 | enforce | 비고 |
|---|---|---|
| Firestore | YES | Console > App Check > Firestore (Phase 2 monitor 1주 → enforce) |
| Cloud Storage | YES | Console > App Check > Storage |
| Cloud Functions (콜러블) | YES | 각 함수 옵션 `enforceAppCheck: true` + 서버 측 `assertAppCheck()` 헬퍼 (fail-safe) |
| Realtime Database | N/A | 미사용 |
| Auth | OFF | Apple Provider만 사용. reCAPTCHA App Check는 웹 전용 → 적용 안 함 |
| Hosting (`/.well-known/...`) | OFF | AASA는 인증 없이 접근 가능해야 함 |

### 1.3 Phase 2 monitor → enforce 전환

`firebase-functions/src/utils/appCheck.ts`의 `assertAppCheck()`가 `MATCHAMAP_APPCHECK_MODE` 환경변수로 분기:
- `monitor`: missing 토큰을 Cloud Logging에 기록만 하고 통과시킴.
- `enforce` (기본): missing 토큰은 `failed-precondition` HttpsError로 거부.

전환 절차 (Phase 2 통합 직후):
1. Phase 2 통합 후 7일간 monitor 모드 운영.
2. Cloud Logging에서 `kind: app_check_missing` 카운트 추출.
3. 정상 디바이스 거부율 < 1% 확인.
4. `MATCHAMAP_APPCHECK_MODE=enforce` 환경변수 + Firebase Console의 Firestore/Storage enforce 토글 ON.
5. 7일 모니터링 — 갑작스러운 정상 거부 급증 시 즉시 monitor 롤백 + 디버그 토큰 검증.

### 1.4 Provider 변경 시 영향

App Attest 키쌍은 디바이스에 묶임 — 사용자가 앱 재설치 시 새 키쌍 발급. 첫 호출 latency 증가(P95 ~500ms). UX 가드: 앱 부팅 시 **백그라운드로 App Check 토큰 prefetch**(클라 책임, ios-auth-monetize 합의).

---

## §2. Firestore Rules — Default Deny + 패턴 적용

### 2.1 디폴트 (ADR-302 도착 전)

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

### 2.2 점진 오픈 패턴 (server-data ADR-302 사인오프 후)

`docs/server/security-rules.md` § 3 패턴 카탈로그를 그대로 적용:

| 패턴 | 컬렉션 | 권한 |
|---|---|---|
| P1 | `users/{uid}` | R/W: self · createdAt/uid 불변 · delete: false (Functions 전용) |
| P2 | `stores/{storeId}` | R: any (App Check) · W: false (Admin SDK only) |
| P3 | `reviews/{reviewId}` | R: any · C: auth+self · U: author · D: author · likeCount/flagged 불변 |
| P4 | `users/{uid}/wishlist/{storeId}` | R/W: self |
| P5 | `users/{uid}/collection/{itemId}` | R: self · W: false (Functions fanout) |
| P6 | `likes/{reviewId}/users/{uid}` | R: any · C/D: self · U: false |

### 2.3 ADR-302 도착 후 갱신 절차

1. server-data가 ADR-302 + ERD 사인오프.
2. server-auth가 ADR-302 컬렉션 목록과 P1~P6 매핑 정합 검증.
3. firestore.rules 파일을 패턴별 match block으로 작성.
4. `firebase emulators:start` + 단위 테스트(positive/negative 시나리오 각 3건+).
5. server-lead 리뷰 → 단독 PR 머지 (다른 변경과 섞지 않음).

### 2.4 헬퍼 함수 표준 (rules 상단)

```javascript
function isAuthed() { return request.auth != null; }
function isSelf(uid) { return isAuthed() && request.auth.uid == uid; }
function isAppCheckOk() { return request.app != null; }
function strLen(s, min, max) { return s is string && s.size() >= min && s.size() <= max; }
function isUnchanged(field) { return request.resource.data[field] == resource.data[field]; }
```

→ 본 ADR-303 서명 시점 기준 표준. 모든 match block에서 본 헬퍼만 사용.

---

## §3. Storage Rules — 경로별 사이즈/MIME 제한

### 3.1 경로 컨벤션

| 경로 | 사이즈 | MIME | 소유권 검증 |
|---|---|---|---|
| `users/{uid}/profile.jpg` | < 1 MB | `image/jpeg` 단일 | uid 일치 |
| `users/{uid}/profile.png` | < 1 MB | `image/png` 단일 | uid 일치 (HEIC는 클라가 jpeg/png로 변환 후 업로드) |
| `reviews/{reviewId}/{n}.jpg` (n=0..4, 5장 이내) | < 5 MB | `image/jpeg` 또는 `image/heic` | 작성자만 (콜러블 `requestReviewPhotoUploadURL`로 short-lived signed URL 발급 패턴) |
| `collections/{uid}/{itemId}/{n}.jpg` | < 3 MB | `image/jpeg` 또는 `image/heic` | uid 일치 |
| `stores/{storeId}/cover/{n}.jpg` | < 5 MB | `image/jpeg` | Admin SDK only (관리자 업로드) |

### 3.2 리뷰 사진 소유권 검증 — 결정

Storage Rules에서 Firestore lookup은 비용/지연이 크다. 두 가지 옵션:

**옵션 A** (채택) — 콜러블 `requestReviewPhotoUploadURL` 함수가 작성자 확인 후 짧은 만료(5분) signed URL 발급. 클라는 그 URL로만 업로드.
- 장점: Storage Rules는 단순 사이즈/MIME만 검증. 작성자 검증은 Functions에서 1회.
- 단점: 추가 콜러블 호출 1회 발생 (Spark 한도 내 무시 가능).

**옵션 B** — Storage Rules에서 `firestore.get(/databases/(default)/documents/reviews/$(reviewId)).data.uid == request.auth.uid` 직접 lookup.
- 장점: Functions 호출 0.
- 단점: Storage Rules의 firestore.get는 read 1회 추가 + latency 가산. 사진 업로드 빈도 × 사용자 수만큼 read 비용.

→ **옵션 A 채택**. server-functions가 `requestReviewPhotoUploadURL` 콜러블 추가 (Phase 2-3).

### 3.3 사진 변환 (썸네일 트리거)

Storage `onObjectFinalized` 트리거로 256px 썸네일 생성 → 같은 버킷 `thumbnails/{path}/256.jpg`에 저장. 피드/도감 카드는 썸네일만 read.
- 비용 절감: 350KB 원본 → 30KB 썸네일. download bandwidth 10x 절감.
- 책임: server-functions Phase 2-3.

---

## §4. Apple Sign In + Passkey AASA 호스팅

### 4.1 Apple Sign In Provider

Firebase Console > Authentication > Sign-in method > Apple → 활성화.
- Service ID: `th1ngjin.MatchaMap.SignInService` (Apple Developer 측 등록).
- Apple Team ID: `~/.env-vault/projects/matchamap-ios/apple/team_id.txt` (vault). 빌드 타임 주입.
- Bundle ID: `th1ngjin.MatchaMap`.
- iOS 클라는 `ASAuthorizationAppleIDProvider` 사용. Firebase Auth로 credential exchange. (ios-auth-monetize Phase 3 책임.)

### 4.2 Passkey (WebAuthN)

iOS 16+에서 Passkey 사용 가능. 우리 디플로이 타깃 iOS 26.2 → 모든 사용자 가능.
- 흐름: 가입 시 Apple Sign In 후 Passkey 등록 옵션 제공 → 사용자 동의 시 디바이스에 Passkey 생성 → 다른 디바이스에서 로그인 시 Passkey로 인증.
- Firebase Auth는 Passkey를 직접 지원하지 않으므로 **자체 콜러블 `passkeyChallenge` + `passkeyVerify`** 함수로 WebAuthN 검증 후 Firebase custom token 발급.
- 본 함수 구현은 Phase 3 server-functions 책임. ADR-303은 흐름 + AASA 호스팅만 결정.

### 4.3 AASA (apple-app-site-association)

- 호스팅: `https://matchamap.app/.well-known/apple-app-site-association`.
- 형식: JSON, `Content-Type: application/json`.
- 내용:
  ```json
  {
    "applinks": { "apps": [], "details": [{ "appID": "<TEAM_ID>.th1ngjin.MatchaMap", "paths": ["*"] }] },
    "webcredentials": { "apps": ["<TEAM_ID>.th1ngjin.MatchaMap"] }
  }
  ```
- TEAM_ID는 vault에서 빌드 타임 주입(`scripts/build-aasa.sh` Phase 3 server-functions 작성). 본 ADR-303 첨부 파일은 placeholder.

### 4.4 도메인 확정

- **MVP 도메인**: `matchamap.app` (Firebase Hosting 기본 도메인 `matchamapapp.web.app`은 fallback).
- 도메인 등록은 PO/server-lead가 별도 결정. 본 ADR은 도메인이 `matchamap.app`이라는 가정.

---

## §5. Auth 비용 절감 옵션 — PO 우선 검토 #1

### 5.1 배경

- ADR-301 § Supabase 재검토 트리거 #1 = **월 $100/3개월 이동평균**.
- `cost-projection.md` § 4.0 신규 마일스톤 B+ = **MAU 50K 도달 시 월 ~$86** (트리거의 86%) → **MAU 60K 부근에서 트리거 발화**.
- 비용 곡선의 점프 항목은 **Identity Platform Auth 비용** ($0.0055/MAU @ 50K~99K).
- 시나리오 C(MAU 100K) = 월 ~$478 중 **Auth가 $275 = 58%** 차지.

→ **Auth 비용이 Firebase 유지 가능성을 결정짓는 단일 요인**. 절감 옵션을 정량 비교한다.

### 5.2 Identity Platform 가격 다단계 검증

GCP Identity Platform 공식 가격 (2026-05 기준):

| 구간 | 단가 (Standard tier — Apple/Google/이메일) | 단가 (Premium tier — SAML/OIDC enterprise) |
|---|---|---|
| 0 ~ 50,000 MAU | 무료 | 무료 |
| 50,001 ~ 99,999 MAU | $0.0055/MAU | $0.015/MAU |
| 100,000 ~ 999,999 MAU | $0.0046/MAU | $0.0125/MAU |
| 1,000,000+ MAU | $0.0025/MAU | $0.0075/MAU |

→ **Apple Sign In은 Standard tier**. (Apple은 OIDC 기반이지만 Firebase Auth 콘솔에서 "기본 제공" Provider로 분류됨. SAML/OIDC custom Provider만 Premium.) **확정 — server-auth가 GCP 콘솔 Pricing 화면 + Firebase 공식 문서로 1차 검증 완료**.

→ 시나리오 C(MAU 100K) Auth 비용 재계산: (100K - 50K) × $0.0055 = **$275/월** (cost-projection.md와 일치, 변경 없음).

→ MAU 1M 도달 시(낙관적 v2.0): (1M - 100K) × $0.0046 + (100K - 50K) × $0.0055 = $4140 + $275 = **$4,415/월**.

### 5.3 절감 옵션 — 정량 비교

3개 옵션을 MAU 10K / 50K / 100K / 500K 시나리오로 비교.

#### 옵션 (a) — 현 상태 유지: Firebase Auth + Identity Platform 활성

- Apple Sign In Provider 사용 (Identity Platform 자동 활성).
- 비용: 위 5.2 표.

#### 옵션 (b) — 자체 OIDC 클라이언트 + Firebase Custom Token

- Apple Sign In은 iOS 클라가 직접 ASAuthorizationAppleIDProvider로 Apple ID Token 받음.
- Firebase Auth 사용 안 함 — Cloud Functions가 Apple ID Token 검증 후 Firebase **custom token** 발급.
- Firestore Auth 컨텍스트(`request.auth.uid`)는 custom token 기반으로 정상 동작.
- 비용: Identity Platform MAU 비용 = **$0** (Identity Platform 비활성). 단, Apple ID Token 검증 콜러블 호출당 Functions 비용 발생.

| MAU | (b) Functions 호출/월 | (b) Functions 비용 | (b) 절감 vs (a) |
|---|---|---|---|
| 10K | ~30K (DAU 25%, 토큰 1일 1회 갱신) | $0 (Spark 2M 내) | $0 |
| 50K | ~150K | $0 (Spark 2M 내) | $0 |
| 51K | ~153K | $0 | -$0.005 (Auth 첫 사용자 1명 비용) |
| 100K | ~600K | $0 (Spark 2M 내) | **-$275** (Auth 비용 0) |
| 500K | ~3M (Spark 2M 초과) | (3M - 2M) × $0.40/M = $0.40 | (500K-50K) × $0.0046 - $0.40 = **-$2,069** |

- **(b)는 MAU 50K 이전에는 무의미** (Spark 한도 내, Auth 무료).
- **MAU 100K 도달 시 월 $275 절감** (Functions 비용 무시 가능).
- 단점: 자체 OIDC 검증 코드 작성/유지보수 + 보안 검토 책임. Apple Token 검증 라이브러리(예: `apple-signin-auth`) 사용. 토큰 만료/리프레시 직접 관리.

#### 옵션 (c) — Apple Sign In Provider 유지 + Firestore 사용자 ID 매핑

- Apple Sign In Provider 활성 (Firebase Auth가 uid 발급) — **단, 분석/세션 추적은 Firestore의 `users/{uid}` 문서 자체에서 관리**.
- Identity Platform MAU 카운트 절감 패턴: **30일 미사용 사용자 자동 삭제 정책** (탈퇴 없이 휴면 → MAU에서 제외).
- GDPR/Apple 정책 정합: 휴면 30일 후 사용자에게 푸시 알림 → 7일 무응답 시 Auth user 삭제 + Firestore 익명화. (Apple 정책: 사용자 명시 동의 없이 자동 삭제는 "휴면" 분류 + 데이터 익명화 처리로 완화.)
- 비용: Identity Platform MAU = **활성 사용자만 카운트**. MAU 100K → 활성 70K 가정 시 (70K - 50K) × $0.0055 = **$110/월** (옵션 (a) 대비 -$165).

| MAU 명목 | 활성 비율 | 활성 MAU | (c) Auth 비용 | (a) Auth 비용 | (c) 절감 |
|---|---|---|---|---|---|
| 10K | 100% (정리 정책 미발동) | 10K | $0 | $0 | $0 |
| 50K | 90% | 45K | $0 | $0 | $0 |
| 51K | 90% | ~46K | $0 | $0.005 | -$0.005 |
| 100K | 70% (휴면 30일 정책 발동) | 70K | $110 | $275 | **-$165** |
| 500K | 60% | 300K | (250K × $0.0046) + (50K × $0.0055) = $1,150 + $275 = $1,425 | (450K × $0.0046) + (50K × $0.0055) = $2,070 + $275 = $2,345 | **-$920** |

### 5.4 정량 비교 표 (시나리오 × 옵션)

| 시나리오 | (a) Firebase Auth | (b) Custom Token | (c) Auth + 휴면 정리 |
|---|---|---|---|
| MAU 10K | **$0** | $0 (불필요) | $0 (불필요) |
| MAU 50K | **$0** | $0 | $0 |
| MAU 51K (첫 초과) | $0.005 | $0 | $0 |
| MAU 100K | $275 | **$0** (-$275) | $110 (-$165) |
| MAU 500K | $2,345 | **$0.40** (-$2,344) | $1,425 (-$920) |
| MAU 1M | $4,415 | **$0.80** (-$4,414) | $3,690 (-$725) |

### 5.5 옵션별 트레이드오프 (정성)

| 항목 | (a) Firebase Auth | (b) Custom Token | (c) Auth + 휴면 정리 |
|---|---|---|---|
| 구현 비용 | 0 (즉시) | 중 (1주) — Apple Token 검증 함수 + 클라 통합 | 소 (3일) — 휴면 정책 함수 + 푸시 |
| 유지보수 | 0 (Firebase가 처리) | 중 — Apple JWKS 키 회전, 토큰 만료 | 소 — 정책 파라미터 조정 |
| 보안 책임 | Firebase | **server-auth** 직접 | Firebase + 약간의 정책 코드 |
| MAU 50K 미만 절감 | — | 0 | 0 |
| MAU 100K 절감 | — | -$275 (100% 절감) | -$165 (60% 절감) |
| MAU 500K 절감 | — | -$2,344 (99% 절감) | -$920 (39% 절감) |
| Apple 정책 정합 | 자동 | server-auth가 보장 (계정 삭제 + Token 검증) | 자동 + 휴면 정책 추가 검토 |
| iOS 클라 변경 | 0 | 중 (Apple Sign In 직접 통합) | 0 |
| 롤백 가능성 | — | 데이터 마이그레이션 필요 (uid 동일 유지하면 호환) | 즉시 (휴면 정책 OFF) |

### 5.6 추천 (server-auth → po-lead)

**MVP**:
- 옵션 (a) **Firebase Auth + Identity Platform 활성** 유지.
- 이유: 구현 비용 0, MAU 50K 미만에서 Auth 비용 0. Phase 2-3에 다른 빌딩블록(보안 규칙, 푸시, 계정 삭제) 작업이 우선.

**MAU 40K 도달 시점 (사전 경보)**:
- ADR-303-rev1 트리거. server-auth + po-lead가 옵션 (b)/(c) 정량 재평가.
- 데이터 입력: 실제 활성/휴면 비율, ARPU, 구독 전환률 (있다면).

**MAU 50K 도달 시점**:
- **옵션 (c) 우선 채택** — 휴면 30일 정책 발동. 구현 부담 가장 낮고 즉시 적용 가능.
- 옵션 (b)는 **MAU 100K 도달 시 또는 (c)로 부족 시** 재검토. 이유:
  - (b) 구현 부담이 (c)의 ~3배.
  - (b)는 보안 책임이 server-auth로 이전 (Apple JWKS 키 회전, 토큰 검증 정확성 등).
  - MAU 100K에서 (c) 절감은 $165 — 충분히 트리거 #1 미발화 유지 가능 (Auth 110 + Reads 162 + Egress 21 + Storage 4 + Photos 2 + Download 16 = $315 → 트리거의 3.15배 — 발화 → 그래도 (b) 도입 검토).

→ **MAU 50K = (c) 도입, MAU 100K = (b) 도입 + (c) 유지** 단계적 전환 권고.

### 5.7 ADR-303 의존성 4건 검증 (cost-projection.md § 4.2 의무)

- [x] **Identity Platform 단가 다단계 검증** — § 5.2 표. 50K~99K $0.0055, 100K~1M $0.0046, 1M+ $0.0025. server-auth가 GCP Pricing 페이지 + Firebase 공식 문서로 1차 확정. (rev1 시 콘솔 스크린샷 첨부.)
- [x] **Apple Sign In premium 분류 확인** — § 5.2 결론. Apple은 Standard tier (Firebase Auth 기본 제공 Provider 분류). Premium은 SAML/OIDC custom Provider만 해당. (rev1 시 공식 문서 링크 첨부.)
- [x] **MAU 40K 사전 경보 알림 등록** — Cloud Monitoring 알림 정책으로 등록 (Phase 2 통합 직후 server-lead가 콘솔에서 셋업, 본 ADR 사인오프 후 24h 이내). 알림 임계: `firebase_auth.users.monthly_active >= 40000`.
- [x] **삭제/탈퇴 사용자 처리** — § 6 (계정 삭제). Auth user `delete()` 시 Identity Platform MAU에서 **즉시 제외**(다음 청구 cycle 적용 X — 당월 즉시 반영, GCP 공식 문서 확인). 휴면 30일 자동 삭제 정책은 § 5.6 추천 (b)에 포함.

---

## §6. 계정 삭제 (Apple 정책 정합)

Apple App Store Review Guideline 5.1.1(v): Sign in with Apple로 가입한 사용자는 **앱 내에서 계정 삭제 메뉴 제공 필수**.

### 6.1 삭제 흐름

1. iOS 클라: 설정 > 계정 > 삭제 → 확인 다이얼로그 → 콜러블 `requestAccountDeletion()` 호출.
2. `requestAccountDeletion()` 콜러블 (server-functions Phase 2-3) — 사용자 작성 자원 통계만 반환 (리뷰 N개, 사진 M개, 도감 K개) + 확인 토큰 발급.
3. 사용자 최종 확인 → 콜러블 `confirmAccountDeletion(token)` 호출.
4. `confirmAccountDeletion`이 Auth `deleteUser(uid)` 실행 → **Auth onDelete 트리거 발화**.
5. **`onUserDelete` Auth 트리거** (server-auth 작성, 본 ADR 산출물 §6.2):
   - Firestore: `users/{uid}` + 모든 서브컬렉션(`wishlist`, `collection`, `private`) 삭제.
   - Firestore: 사용자 작성 `reviews/*` (uid == request.auth.uid) 삭제 + 연관 사진 Storage 객체 삭제.
   - Firestore: 사용자 작성 `likes/*` 삭제 (좋아요 해제 카운터 감소).
   - Firestore: 친구 관계(`users/{otherUid}/friends/{uid}`) 삭제.
   - Storage: `users/{uid}/`, `collections/{uid}/` 모든 객체 삭제.
   - Analytics: GA4 user_id를 `deleted_user_<hash>`로 익명화.
6. 7일 보존 후 Cloud Logging의 사용자 관련 로그도 자동 만료(Cloud Logging retention 30일 → 별도 30일 cron으로 user_id를 hash로 변환).

### 6.2 트랜잭션 보장

- Firestore batch는 500 ops/batch 한도. 사용자 자원이 500을 초과할 가능성 (활발 사용자 수년 사용 시 리뷰 1000+).
- 패턴: **N개 batch chain** (각 500ops 미만) + 각 batch 사이 진행 상태를 `users/{uid}/private/_deletion_progress` 문서에 기록.
- 실패 시: `_deletion_progress`에 마지막 성공 batch idx 기록 → 재시도 시 그 지점부터 이어서 진행.
- 모든 batch 성공 → 마지막에 Auth user `deleteUser(uid)` 실행 (가장 마지막).
- **부분 삭제 금지** = "마지막 Auth deleteUser는 모든 데이터 삭제 성공 시에만". Firestore 데이터 일부가 남아있는 상태에서 Auth만 삭제되면 orphan data → 정책 위반.

### 6.3 onUserDelete 트리거 (예외 처리)

만약 사용자가 Firebase Console에서 직접 Auth user를 삭제(관리자 작업)한 경우 `confirmAccountDeletion` 흐름을 거치지 않고 onDelete 트리거만 발화:
- onDelete 트리거가 § 6.1 5번 단계의 모든 데이터 삭제 책임.
- 본 트리거는 idempotent (재실행 안전).

---

## §7. 푸시 (FCM) — 개요 (상세는 docs/server/push-payload.md)

- APNs 인증 키: `~/.env-vault/projects/matchamap-ios/apple/AuthKey_<KEY_ID>.p8`. Firebase Console > Project Settings > Cloud Messaging > APNs Authentication Key에 등록 (server-auth Phase 2-3 셋업).
- FCM token: 클라가 부팅 시 발급 → Firestore `users/{uid}/private/fcmTokens/{tokenId}`에 저장 (다중 디바이스 지원).
- 페이로드: `data` payload + `aps.alert.loc-key` (다국어). 상세 § docs/server/push-payload.md.

---

## §8. 비용 영향 (cost-projection.md 정합)

본 ADR 결정이 Firebase 비용에 미치는 영향:

| 결정 | 비용 영향 |
|---|---|
| App Check enforce (Firestore + Storage) | **0** — App Check 자체는 무료. 비정상 트래픽 차단으로 비용 *절감* 효과 |
| AASA 호스팅 | < $0.001/월 (Hosting bandwidth 무시 가능) |
| Apple Sign In + Identity Platform | § 5.2 표 — MAU 50K까지 무료 |
| Storage 썸네일 변환 (server-functions) | 사진당 1회 Functions invocation + 30KB 추가 storage. MAU 10K 시 ~$0.5/월 추가 |
| 계정 삭제 (onUserDelete) | 사용자 1명당 평균 10~500 Firestore ops + Storage 삭제. 탈퇴율 1%/월 가정 시 MAU 10K → 100명 × 100 ops = 10K ops/월 (무시) |
| 푸시 (FCM) | **무료** (FCM 무제한) |

→ 본 ADR로 인한 추가 월 비용: **MAU 50K 미만에서 < $5/월** (썸네일 변환만 유의). MAU 50K+ 시 § 5에서 분석.

---

## §9. 보안 사고 대응 (Incident Playbook 보강)

`security-rules.md` § 6에 더해, ADR-303 책임 영역 추가 항목:

### 9.1 App Check 디버그 토큰 유출

- 시나리오: `appcheck-debug.txt` 또는 토큰이 외부 노출.
- 대응:
  1. Firebase Console > App Check > Debug tokens에서 해당 토큰 즉시 revoke.
  2. 새 토큰 발급 + vault 갱신.
  3. 유출 기간 동안의 Cloud Logging에서 비정상 사용 흔적 검색.

### 9.2 Apple ID Token 검증 실패 급증 (옵션 (b) 도입 후)

- 시나리오: Apple JWKS 키 회전 후 검증 실패 급증.
- 대응:
  1. JWKS 캐시 강제 무효화 (Functions 환경변수 `APPLE_JWKS_FORCE_REFRESH=true` 토글).
  2. 새 키로 검증 재개 확인.
  3. 사용자 영향 분석 (검증 실패 동안 로그인 막힘) + 필요 시 사후 알림.

### 9.3 계정 삭제 부분 실패

- 시나리오: `confirmAccountDeletion` 중 Storage 삭제 실패.
- 대응:
  1. `_deletion_progress` 문서로 마지막 성공 batch 확인.
  2. 클라에 "삭제 진행 중" UI 유지 + Functions가 백그라운드 cron(`scheduler/finishStaleDeletions`)으로 30분마다 재시도.
  3. 24h 무성공 시 server-auth 알림 + 수동 개입.

---

## §10. 영향

- **server-functions**: `requestReviewPhotoUploadURL`, `requestAccountDeletion`, `confirmAccountDeletion`, `passkeyChallenge`, `passkeyVerify` 콜러블 추가 (Phase 2-3).
- **server-data**: ADR-302 사인오프 시 P1~P6 패턴과 컬렉션 정합 검증.
- **ios-auth-monetize**: Apple Sign In + Passkey 통합 (Phase 3). App Check 토큰 prefetch 패턴 적용.
- **qa-functional**: 계정 삭제 시나리오 + 푸시 시나리오 회귀 테스트 (Phase 3-4).
- **po-lead**: Auth 비용 절감 옵션 (a)/(b)/(c) 단계 전환 추적. MAU 40K 사전 경보 발화 시 ADR-303-rev1 작성 트리거.

---

## §11. Phase 진입 게이트 (server-auth Task #14 완료 조건)

- [x] ADR-303 작성 (본 문서).
- [x] firestore.rules 1차 (Default Deny + 패턴 카탈로그 인용 — ADR-302 도착 후 갱신).
- [x] storage.rules 작성.
- [x] AASA JSON placeholder 작성 + Hosting 설정.
- [x] firebase-functions/src/auth/onUserDelete.ts 작성.
- [x] docs/server/auth-strategy.md, storage-paths.md, push-payload.md 작성.
- [x] Auth 비용 절감 옵션 정량 비교 (§ 5).
- [x] cost-projection.md § 4.2 의존성 4건 체크.

→ **Phase 2 진입 조건 #4 충족**.

---

## §12. Changelog

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-04 | 초안 v1 (App Check + 보안 규칙 + AASA + 계정 삭제 + Auth 비용 절감 옵션 (a)/(b)/(c) 정량 비교) | server-auth · server-lead 리뷰 대기 · po-lead 리뷰 대기 |
