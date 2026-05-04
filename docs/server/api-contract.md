# API Contract — Cloud Functions 콜러블/트리거 명세

- **작성**: `server-functions` · 2026-05-04
- **상태**: Phase 2 산출물. server-lead + ios-lead 사인오프 대기.
- **소유**: `firebase-functions/` 코드와 본 문서가 1:1 정합. 한 쪽만 변경 금지.
- **리전**: 모든 함수 `asia-northeast3` (ADR-301).
- **Auth**: 모든 콜러블 = App Check + Firebase Auth 토큰 필수.

> 본 문서는 iOS 클라이언트(`Data/Remote/...`)와 본 서버(`firebase-functions/src/...`)
> 사이의 **단일 진실 원천(SSOT)**. 변경 시 server-functions + ios-lead 양측 PR 동시 머지.

## 0. 공통 규약

### 0.1 인증/인가

| 항목 | 강제 |
|---|---|
| App Check 토큰 | 모든 콜러블 필수. 미첨부 시 `failed-precondition` (코드 `APP_CHECK_FAILED`). |
| Auth 토큰 | 모든 콜러블 필수. 익명 호출 거부. Provider = `apple.com` 또는 `passkey`만. |
| ID 토큰 발급자 | Firebase Auth 표준. `iss=https://securetoken.google.com/<projectId>`. |

### 0.2 에러 코드 enum (ErrorCodes.ts와 1:1)

| code | HTTP gRPC status | 의미 |
|---|---|---|
| `APP_CHECK_FAILED` | failed-precondition | App Check 토큰 누락/만료 |
| `UNAUTHENTICATED` | unauthenticated | Auth 토큰 없음/만료 |
| `PERMISSION_DENIED` | permission-denied | 본인 자원 아님 |
| `INVALID_ARGUMENT` | invalid-argument | 페이로드 스키마 위반 |
| `RESOURCE_NOT_FOUND` | not-found | 영수증/매장 등 미존재 |
| `RESOURCE_EXHAUSTED` | resource-exhausted | 한도 초과 (보상형 일일/배치 한도) |
| `REWARDED_AD_INVALID_SIGNATURE` | not-found | SSV 영수증 미존재(혹은 무효) |
| `REWARDED_AD_REPLAY` | failed-precondition | 영수증을 다른 uid가 이미 소비 |
| `REWARDED_AD_QUOTA_EXCEEDED` | resource-exhausted | 일일 보상 광고 한도 |
| `COLLECTION_SLOT_ALREADY_UNLOCKED` | already-exists | (예약) 같은 슬롯 중복 해제 |
| `MODERATION_REJECTED` | failed-precondition | 모더레이션 거부 |
| `MODERATION_PENDING` | unavailable | 모더레이션 진행 중 |
| `INTERNAL` | internal | 서버 내부 오류 |

### 0.3 응답 포맷

콜러블 정상 응답: 함수별 typed payload.

콜러블 에러 응답:
```json
{
  "error": {
    "code": "failed-precondition",
    "message": "App Check verification failed.",
    "details": { "code": "APP_CHECK_FAILED" }
  }
}
```

iOS 클라(`FirebaseFunctions.HTTPSCallableResult`)에서 `error.details.code`를 분기점으로 사용.

### 0.4 타임아웃 / 재시도

- 콜러블 타임아웃 30s. 클라 측은 `URLSession.timeoutIntervalForRequest = 35s`로.
- 백그라운드 트리거 540s. 5xx 자동 재시도는 비활성(`retry: false`) — at-most-once.
- 콜러블 클라 재시도는 idempotent 함수만(`verifyRewardedAd`는 idempotent). 비idempotent
  함수는 클라가 재시도 금지.

---

## 1. `verifyRewardedAd` — 콜러블

### 1.1 시그니처

```ts
interface VerifyRewardedAdRequest {
  transactionId: string;       // AdMob SSV에서 발급된 unique id
  adUnitId: string;            // 광고 단위 ID
  rewardType: 'collection_slot';
  rewardAmount: number;        // ≥ 1
}

interface VerifyRewardedAdResponse {
  ok: true;
  collectionSlotsUnlocked: number;   // 호출 후 사용자 누적 슬롯 수
  remainingDailyRewards: number;     // 오늘 남은 보상형 광고 시청 가능 횟수
}

verifyRewardedAd(req: Request<VerifyRewardedAdRequest>): Promise<VerifyRewardedAdResponse>
```

### 1.2 호출 권한

- App Check 필수.
- Auth 필수 (자기 자신만 슬롯 해제).

### 1.3 흐름

1. 클라 — AdMob `onUserEarnedReward` 콜백 → 본 콜러블 호출.
2. 서버 — `rewardedReceipts/{transactionId}` 영수증 조회.
3. 영수증 미존재 → `not-found` (코드 `REWARDED_AD_INVALID_SIGNATURE`).
4. 다른 uid 소비 → `failed-precondition` (코드 `REWARDED_AD_REPLAY`).
5. 동일 uid 재호출 → idempotent 성공 응답.
6. 일일 한도 초과 → `resource-exhausted` (코드 `REWARDED_AD_QUOTA_EXCEEDED`).
7. 트랜잭션: 영수증 consume + `users/{uid}.collectionSlotsUnlocked++` + 일일 카운터 ++.

### 1.4 에러 케이스

| 시나리오 | code | grpc status |
|---|---|---|
| App Check 누락 | `APP_CHECK_FAILED` | failed-precondition |
| 미인증 | `UNAUTHENTICATED` | unauthenticated |
| 페이로드 불량 | `INVALID_ARGUMENT` | invalid-argument |
| 영수증 미존재 | `REWARDED_AD_INVALID_SIGNATURE` | not-found |
| 다른 uid 소비 | `REWARDED_AD_REPLAY` | failed-precondition |
| 일일 한도(5회) | `REWARDED_AD_QUOTA_EXCEEDED` | resource-exhausted |
| 트랜잭션 실패 | `INTERNAL` | internal |

### 1.5 예시

요청:
```json
{
  "transactionId": "ssv_2026-05-04T10:00:00Z_abc123",
  "adUnitId": "ca-app-pub-XXXX/REWARDED_COLLECTION",
  "rewardType": "collection_slot",
  "rewardAmount": 1
}
```

성공:
```json
{ "ok": true, "collectionSlotsUnlocked": 7, "remainingDailyRewards": 4 }
```

한도 초과:
```json
{
  "error": {
    "code": "resource-exhausted",
    "message": "Daily rewarded ad limit reached.",
    "details": { "code": "REWARDED_AD_QUOTA_EXCEEDED" }
  }
}
```

### 1.6 일일 한도

- KST 자정 컷오프.
- `users/{uid}/rewardedQuota/{YYYYMMDD}.count`가 SSOT. 한도 5회.
- 한도 변경 시 `monetization.md` + 본 문서 동시 갱신.

---

## 2. `mergeStoreSearch` — 콜러블

### 2.1 시그니처

```ts
interface MergeStoreSearchRequest {
  query: string;                 // 1~100자
  viewport: {
    northEast: { lat: number; lng: number };
    southWest: { lat: number; lng: number };
  };
  locale: string;                // BCP-47 (ko-KR)
  maxResults?: number;           // 디폴트 20, 최대 50
}

interface MergeStoreSearchResponse {
  results: SearchResult[];
  source: { firstParty: number; places: number; cached: number };
}

interface SearchResult {
  storeId: string | null;        // 자사 매장 ID (없으면 null)
  placeId: string | null;        // Google Place ID (없으면 null)
  name: string;
  lat: number;
  lng: number;
  country: string;               // ISO-3166 alpha-2
  rating?: number;               // 0.0 ~ 5.0
  isFirstParty: boolean;
}
```

### 2.2 호출 권한

App Check + Auth 필수.

### 2.3 정책

- 자사 매장(`stores`) 우선.
- Places 결과는 `placesCache/{placeId}` (TTL 24h) 캐시.
- 단일 호출당 Places API 외부 호출 ≤ 1회 (비용 보호).
- Phase 2 산출물: 자사 매장만. Places 통합은 Phase 3.

### 2.4 에러

| 시나리오 | code |
|---|---|
| viewport 경계 비정상 (NE.lat ≤ SW.lat 등) | `INVALID_ARGUMENT` |
| query 길이 위반 | `INVALID_ARGUMENT` |
| Places API 오류(Phase 3) | `INTERNAL` (또는 부분 성공으로 first-party만 반환) |

---

## 3. `fanoutFeedEvent` — Firestore 트리거 (백그라운드)

### 3.1 트리거

```
onDocumentCreated('feedEvents/{eventId}')
```

### 3.2 입력 (`feedEvents/{eventId}`)

```ts
interface FeedEventDoc {
  authorUid: string;
  kind: 'review_submitted' | 'collection_added';
  storeId: string;
  refId: string;             // reviewId 또는 collectionId
  createdAt: Timestamp;
  country: string;           // 매장 국가
  fanoutStatus: 'pending';   // 본 함수가 'done'/'partial'/'failed'로 갱신
}
```

### 3.3 출력 (`users/{friendUid}/feed/{eventId}`)

```ts
interface FeedItem {
  authorUid: string;
  kind: 'review_submitted' | 'collection_added';
  storeId: string;
  refId: string;
  createdAt: Timestamp;
  country: string;
}
```

### 3.4 정책

- 친구 ≤ 500: 단일 batch fanout.
- 친구 > 500: 첫 500명만 fanout, `fanoutStatus: 'partial'` 마킹. v1.1.0에 분할 batch 도입.
- 본인 피드에는 fanout하지 않음.
- 작성자가 친구 0명일 경우: `fanoutStatus: 'done'`, count 0.
- 모더레이션 거부 시 `checkReviewContent`가 `fanoutStatus: 'invalidated'` 마킹.

### 3.5 멱등성

- 동일 `eventId`에 대해 트리거가 중복 발화되어도 batch는 `set(merge: false)`로 항상 동일 결과.
- 단, 한 friend 대상 doc은 idempotent (동일 payload).

---

## 4. `checkReviewContent` — Firestore 트리거 (백그라운드)

### 4.1 트리거

```
onDocumentCreated('reviews/{reviewId}')
```

### 4.2 흐름

1. 텍스트 모더레이션: 길이 검사 (Phase 2) → Perspective API (Phase 4).
2. 결과 → `reviews/{reviewId}` 업데이트:
   - `moderationStatus`: `'approved' | 'rejected' | 'needs_review'`
   - `moderationScores`: `Record<string, number>`
   - `moderationCheckedAt`: `Timestamp`
3. `rejected`인 경우 `feedEvents`에서 `refId == reviewId` 조회 → `fanoutStatus: 'invalidated'`.

### 4.3 정책

- 사용자에게는 즉시 표시(낙관적 UI). 거부 시 클라가 토스트 + 화면에서 제거.
- 사진 모더레이션은 별도 `onObjectFinalized` (Phase 4).

---

## 5. `aggregatePopularStores` — 스케줄러

### 5.1 시그니처

```
schedule: 'every 1 hours'
timeZone: 'Asia/Seoul'
```

### 5.2 동작

- 직전 24h 윈도우.
- 6개 국가 × top 50 매장 집계.
- 점수: `(collection_added × 2) + (review_submitted × 3) + (rating_avg × 1.5)`.
- 결과 → `aggregations/popularStores/byCountry/{country}`.

### 5.3 출력 스키마

```ts
interface PopularStoresDoc {
  country: string;
  top: { storeId: string; score: number }[];   // length ≤ 50
  computedAt: Timestamp;
  windowHours: 24;
}
```

### 5.4 클라 사용

- iOS Map 화면 "지금 핫한 말차" 카루셀 — 클라가 직접 read (App Check만 필요, 함수 호출 X).
- 검색 default sort 보조.

---

## 6. `onUserCreated` — Auth blocking trigger

### 6.1 트리거

```
beforeUserCreated()
```

### 6.2 동작

- `users/{uid}` 문서 시드 (server-data ADR-302 스키마):
  ```ts
  {
    uid,
    authProvider: 'apple' | 'passkey' | 'unknown',
    createdAt: serverTimestamp(),
    friendCount: 0,
    collectionSlotsUnlocked: 0,
    debugUser: false,
  }
  ```

### 6.3 실패 정책

- blocking trigger에서 throw 시 가입 거부 → 사용자 경험 악화.
- 본 함수는 throw하지 않고 로그만 기록. 가입은 항상 성공.
- 후속 시드 보정: 첫 콜러블 호출 시 누락된 `users/{uid}` 자동 생성 (각 콜러블에 fallback 가드).

---

## 7. 향후 추가 예정 (Phase 3+)

| 함수 | 종류 | 설명 |
|---|---|---|
| `verifyAdMobSsvCallback` | HTTPS | AdMob → 서버 SSV callback 1차 처리 (signature 검증 + receipt 작성) |
| `onObjectFinalized` (storage) | Storage trigger | 사진 SafeSearch + EXIF 제거 |
| `expireOldFeedEvents` | Scheduler | 90일 지난 feedEvents 삭제 (사용자 피드 무한 증가 방지) |
| `resolveCountry` | Callable | 클라 위치 측위 실패 시 IP geo 백업 (observability.md § 2.1) |
| `redeemPasskeyChallenge` | Callable | Passkey AASA + WebAuthn 챌린지 검증 (server-auth ADR-303) |

---

## 8. 협업 합의

| 항목 | 책임 | 합의 시점 |
|---|---|---|
| feedEvents 작성 트리거 (클라 직접 vs 서버) | server-functions ↔ ios-social-collection | Phase 2 통합 |
| AdMob SSV callback URL + transactionId 포맷 | server-functions ↔ ios-auth-monetize | Phase 3 |
| App Check enforce 시점 | server-auth | Phase 2 통합 직후 1주 |
| Places API 비용 영향 | server-lead ↔ po-growth | Phase 3 |

---

## 9. Changelog

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-04 | 초안 (6 함수 + 공통 규약) | server-functions (server-lead + ios-lead 사인오프 대기) |
