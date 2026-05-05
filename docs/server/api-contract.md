# API Contract — Cloud Functions 콜러블/트리거 명세

- **작성**: `server-functions` · 2026-05-04
- **상태**: Phase 2 산출물. server-lead + ios-lead 사인오프 대기.
- **소유**: `firebase-functions/` 코드와 본 문서가 1:1 정합. 한 쪽만 변경 금지.
- **리전**: 모든 함수 `asia-northeast3` (ADR-301).
- **Auth**: 모든 콜러블 = App Check + Firebase Auth 토큰 필수.
- **상위 결정**: [ADR-301 백엔드](../architecture/ADR-301-backend-choice.md), [ADR-302 Firestore 스키마](../architecture/ADR-302-firestore-schema.md).
- **정합 문서**: [schema.md](schema.md) (컬렉션 SSOT), [observability.md](observability.md) (이벤트 매핑), [security-rules.md](security-rules.md).

> 본 문서는 iOS 클라이언트(`Data/Remote/...`)와 본 서버(`firebase-functions/src/...`)
> 사이의 **단일 진실 원천(SSOT)**. 변경 시 server-functions + ios-lead 양측 PR 동시 머지.

---

## 0. 공통 규약

### 0.1 인증/인가

| 항목 | 강제 |
|---|---|
| App Check 토큰 | 모든 콜러블 필수. 미첨부 시 `failed-precondition` (코드 `APP_CHECK_FAILED`). |
| Auth 토큰 | 모든 콜러블 필수. 익명 호출 거부. Provider = `apple.com` 또는 `passkey`만. |
| ID 토큰 발급자 | Firebase Auth 표준. `iss=https://securetoken.google.com/<projectId>`. |

### 0.2 시간/페이지네이션 (ADR-302 D4 + D5)

- **모든 timestamp는 `FieldValue.serverTimestamp()`** — 클라 wall-clock 신뢰 금지.
- **예외**: `collections/items.visitedAt`은 클라 입력 허용 (도감은 과거 시음 추가 케이스).
- **Cursor-based 페이지네이션** — 모든 리스트 응답은 `nextCursor: string | null`. offset/page 파라미터 사용 금지.
- **디폴트 limit = 20**, 최대 50.

### 0.3 에러 코드 enum (`utils/errors.ts`와 1:1)

| code | gRPC status | 의미 |
|---|---|---|
| `APP_CHECK_FAILED` | failed-precondition | App Check 토큰 누락/만료 |
| `UNAUTHENTICATED` | unauthenticated | Auth 토큰 없음/만료 |
| `PERMISSION_DENIED` | permission-denied | 본인 자원 아님 또는 상태 불일치 |
| `INVALID_ARGUMENT` | invalid-argument | 페이로드 스키마 위반 |
| `RESOURCE_NOT_FOUND` | not-found | 매장/사용자/영수증/요청 미존재 |
| `RESOURCE_EXHAUSTED` | resource-exhausted | 한도 초과 |
| `REWARDED_AD_INVALID_SIGNATURE` | not-found | SSV 영수증 미존재/무효 |
| `REWARDED_AD_REPLAY` | failed-precondition | 영수증을 다른 uid가 이미 소비 |
| `REWARDED_AD_QUOTA_EXCEEDED` | resource-exhausted | 일일 보상 광고 한도 |
| `MODERATION_REJECTED` | failed-precondition | 모더레이션 거부 |
| `MODERATION_PENDING` | unavailable | 모더레이션 진행 중 |
| `INTERNAL` | internal | 서버 내부 오류 |

### 0.4 응답 포맷

콜러블 정상 응답: 함수별 typed payload (HTTPSCallableResult.data).

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

### 0.5 타임아웃 / 재시도

- 콜러블 타임아웃 30s. 클라 측은 `URLSession.timeoutIntervalForRequest = 35s`로.
- 백그라운드 트리거 540s. at-most-once (`retry: false`).
- 클라 재시도는 idempotent 함수만(`verifyRewardedAd`, `requestFriend`, `removeFriend`).
- 비idempotent 함수(`addCollectionItem`, `submitReview`, `acceptFriend`)는 클라가 재시도 금지.

---

## 1. 도메인 콜러블 — 트랜잭션 fanout

### 1.1 `addCollectionItem`

도감 항목 추가. schema.md §5.5 fanout SSOT.

```ts
interface AddCollectionItemRequest {
  storeId: string;                 // Google Place ID
  drink: 'usucha' | 'koicha' | 'matcha_latte' | 'iced_matcha' | 'matcha_dessert' | 'other';
  grade?: 'ceremonial' | 'premium' | 'standard' | 'culinary' | 'unknown';   // v1.1
  originRegion?: 'uji' | 'nishio' | 'kagoshima' | 'shizuoka' | 'boseong'    // v1.1: jeju 추가 (9종)
              | 'hadong' | 'jeju' | 'other' | 'unknown';
  colorTier?: 'matchaSoft' | 'matchaPale' | 'matcha' | 'deepMatcha' | 'deep'; // v1.1
  note?: string;
  photos?: string[];               // 0~3 items, gs:// 경로
  visitedAt?: number;              // epoch ms (과거 시음 입력 허용)
  viaReview?: boolean;             // 디폴트 false
  linkedReviewId?: string;
}

interface AddCollectionItemResponse {
  itemId: string;                  // ULID
  collectionCount: number;         // 갱신 후 사용자 누적
}
```

**v1.1 enum 변경**:
- `grade`: `cooking` 제거 → `standard` + `culinary` 분리. 클라가 `cooking`을 보내면 `INVALID_ARGUMENT`.
- `originRegion`: `jeju` 추가 (9종).
- `colorTier`: 신규. 클라는 enum만 입력. **`colorHex`는 직접 입력 금지** — 서버가 design-system.md § 1.5.1 매핑으로 자동 채움. 클라가 `colorHex` 직접 보내면 무시(향후 strict mode에서 거부 예정).

**fanout 트랜잭션 (모두 같은 transaction)**:
1. `collections/{uid}/items/{itemId}` create (디노멀 store + colorTier + colorHex(서버 자동) + viaReview/linkedReviewId).
2. `users/{uid}.stats.collectionCount += 1`.
3. `feed_events/{eventId}` create with `audienceUids = [uid, ...accepted_friends ≤ 500]`.

**오류**:
- 매장 미존재 → `RESOURCE_NOT_FOUND`.
- viaReview=true & linkedReviewId 미제공 → `INVALID_ARGUMENT`.
- `grade`/`originRegion`/`colorTier` enum 위반 → `INVALID_ARGUMENT`.

**observability**: 본 doc create = `store_collection_added` 이벤트 SSOT (observability §3.4). 클라가 콜러블 응답 후 analytics 발화.

### 1.2 `submitReview`

리뷰 작성. schema.md §3 + (옵션) §5 도감 자동 생성.

```ts
interface SubmitReviewRequest {
  storeId: string;
  rating: 1 | 2 | 3 | 4 | 5;
  body: string;                    // 1~2000 chars
  photos?: string[];               // 0~4 items
  tags?: string[];                 // 0~8 items, schema §3 enum
  drink?: 'usucha' | 'koicha' | 'matcha_latte' | 'iced_matcha' | 'dessert' | 'other';
  viaReview?: boolean;             // 디폴트 true: 도감 자동 생성
}

interface SubmitReviewResponse {
  reviewId: string;
  collectionItemId?: string;       // viaReview=true일 때만
}
```

**fanout 트랜잭션**:
1. `reviews/{reviewId}` create (디노멀 author + store, moderationStatus='pending').
2. `users/{uid}.stats.reviewCount += 1`.
3. `stores/{storeId}.{reviewCount, ratingAvg, ratingHistogram[rating]}` 갱신.
4. (viaReview) `collections/{uid}/items/{itemId}` create.
5. `feed_events/{eventId}` create with audienceUids.

**moderation**: `reviews` doc create는 즉시. `checkReviewContent` 백그라운드 트리거가 비동기 검사. 거부 시 `feed_events.fanoutStatus='invalidated'`.

### 1.3 `requestFriend` / `acceptFriend` / `removeFriend`

schema.md §6 양방향 doc 정합 + friendCount fanout.

```ts
// 1.3.1 requestFriend
interface RequestFriendRequest {
  targetUid: string;
  addMethod: 'qr';                 // v1.0.0은 qr만
}
interface OkResponse { ok: true }

// 1.3.2 acceptFriend
interface AcceptFriendRequest {
  requesterUid: string;
}

// 1.3.3 removeFriend
interface RemoveFriendRequest {
  otherUid: string;
}
```

**상태 전이**:
- `requestFriend(target)`: `friendships/{me}/edges/{target}=pending_outgoing` + `friendships/{target}/edges/{me}=pending_incoming`. idempotent.
- `acceptFriend(requester)`: 두 edge → `accepted` + `acceptedAt=now` + 양쪽 friendCount += 1 + 양쪽 `feed_events` (type=`friend_added`) fanout.
- `removeFriend(other)`: 두 edge 삭제 + (accepted였다면) 양쪽 friendCount -= 1.

**오류**:
- 자기 자신 / 미존재 사용자 → `INVALID_ARGUMENT` 또는 `RESOURCE_NOT_FOUND`.
- pending 상태가 아닌 acceptFriend → `PERMISSION_DENIED`.

---

## 2. 비도메인 콜러블

### 2.1 `verifyRewardedAd`

AdMob 보상형 광고 SSV 영수증 검증 + 도감 슬롯 해제.

```ts
interface VerifyRewardedAdRequest {
  transactionId: string;            // AdMob SSV 발급
  adUnitId: string;
  rewardType: 'collection_slot';
  rewardAmount: number;             // ≥ 1
}

interface VerifyRewardedAdResponse {
  ok: true;
  collectionSlotsUnlocked: number;
  remainingDailyRewards: number;
}
```

**흐름**:
1. AdMob → SSV callback HTTPS 함수 → `rewardedReceipts/{transactionId}` 작성 (Phase 3).
2. 클라 `onUserEarnedReward` → 본 콜러블.
3. 트랜잭션: 영수증 consume + `users.collectionSlotsUnlocked += rewardAmount` + `users/{uid}/rewardedQuota/{YYYYMMDD}.count++`.

**일일 한도**: 사용자당 **5회** (KST 자정 컷오프). 변경 시 monetization.md + 본 문서 동시 갱신.

**idempotent**: 동일 (uid, transactionId) 재호출 OK.

**에러**:
| 시나리오 | code | gRPC status |
|---|---|---|
| 영수증 미존재 | `REWARDED_AD_INVALID_SIGNATURE` | not-found |
| 다른 uid 소비 | `REWARDED_AD_REPLAY` | failed-precondition |
| 일일 한도(5회) | `REWARDED_AD_QUOTA_EXCEEDED` | resource-exhausted |

### 2.2 `mergeStoreSearch`

자사 매장 + Google Places 머지 검색.

```ts
interface MergeStoreSearchRequest {
  query: string;                    // 1~100 chars
  viewport: {
    northEast: { lat: number; lng: number };
    southWest: { lat: number; lng: number };
  };
  locale: string;                   // BCP-47
  maxResults?: number;              // 디폴트 20, 최대 50
  cursor?: string;                  // ADR-302 D5
  minPinTier?: 'S' | 'A' | 'B' | 'C';  // v1.2: viewport 디클러스터링 ("S만"/"A 이상")
}

interface MergeStoreSearchResponse {
  results: SearchResult[];
  nextCursor: string | null;
  source: { firstParty: number; places: number; cached: number };
}

interface SearchResult {
  storeId: string | null;           // 자사 매장 ID
  placeId: string | null;
  name: string;
  lat: number;
  lng: number;
  country: string;
  pinTier?: 'S' | 'A' | 'B' | 'C';  // v1.2 — 서버 derive (utils/pinTier.ts)
  rating?: number;
  isFirstParty: boolean;
}
```

**`pinTier` derive 정책 (ADR-302 v1.2)**:
- `S` = `verified && matchaScore ≥ 4.5`
- `A` = `verified && 4.0 ≤ matchaScore < 4.5`
- `B` = `(3.0 ≤ matchaScore < 4.0)` 또는 `(verified && matchaScore < 4.0)`
- `C` = `!verified && matchaScore < 3.0`
- 트리거: `onCreate stores`, `onUpdate stores.{matchaScore,verified}`, `recomputeStoreAggregates` (idempotent skip).

**Phase 2**: 자사 매장만 검색. Places 통합은 Phase 3 (ios-store 합의 후).

**비용 보호**: Places API 외부 호출 ≤ 1회/콜러블. `placesCache/{placeId}` TTL 24h (Phase 3).

---

## 3. Firestore 트리거 (백그라운드)

### 3.1 `onUserCreated` — Auth blocking

```
beforeUserCreated()
```

users/{uid} 시드 생성 (schema §1):
```ts
{
  uid, displayName, photoURL,
  locale: 'ko-KR',                  // 클라가 첫 호출에 갱신
  homeCountry: 'KR',                // 클라가 첫 호출에 갱신
  travelMode: false,
  cohortD0: <KST midnight>,         // observability cohort_d0 SSOT
  authMethod: 'apple' | 'passkey',
  createdAt, updatedAt,
  stats: { collectionCount: 0, reviewCount: 0, wishlistCount: 0, friendCount: 0 }
}
```

**실패 시 가입 차단 안 함** (throw 금지).

### 3.2 `fanoutFeedEvent`

```
onDocumentCreated('feed_events/{eventId}')
```

본 트리거는 fanout *수행*하지 않음 — 콜러블이 audienceUids를 채워 doc create한다.
본 트리거의 역할:
- audienceUids ≥ 400: WARN 로그 (ADR-302 § fanout 임계 모니터링, schema §12 SCH-6).
- audienceUids > 500: 정책 위반, 별도 알림.
- analytics audit (선택).

### 3.3 `onUpdateUser` — 디노멀 fanout

```
onDocumentUpdated('users/{uid}')
```

`displayName` / `photoURL` 변경 시:
- `reviews where uid==X` → `author.{displayName, photoURL}`
- `feed_events where actorUid==X` → `actor.{displayName, photoURL}`
- `friendships/*/edges/{X}` → `friend.{displayName, photoURL}`

paginate 500/iter, 최대 25,000 docs/run.

### 3.4 `onUpdateStore` — 디노멀 fanout

```
onDocumentUpdated('stores/{placeId}')
```

`name` / `primaryPhoto` 변경 시:
- `reviews where storeId==X` → `store.{name, city, country, primaryPhoto}`
- `wishlists/*/items where storeId==X` (collection group) → `store.{...}`
- `collections/*/items where storeId==X` (collection group) → `store.{...}`
- `feed_events where targetId==X` → `target.{...}`

`origin` 변경: 현재 디노멀 안 됨 → no-op + audit 로그. server-data와 합의 후 보강.

### 3.5 `onCreateStorePinTier` / `onUpdateStorePinTier` — pinTier derive (v1.2)

```
onDocumentCreated('stores/{placeId}')
onDocumentUpdated('stores/{placeId}')
```

`stores.matchaScore` 또는 `verified` 변경 시 `pinTier` 자동 derive (위 § 2.2 derive 정책).
Idempotent skip — 동일 input → 동일 output, 무한 루프 방지. `recomputeStoreAggregates` 매시
정각도 동일 derive 로직 직접 적용.

### 3.6 `onWriteFcmToken` — 부모 user `notification.lastTokenAt` 갱신 (v1.3)

```
onDocumentWritten('users/{uid}/fcmTokens/{tokenId}')
```

토큰 create/update 시 부모 user doc의 `notification.lastTokenAt`을 max로 갱신. delete는 no-op.
schema.md §1A 정합.

### 3.7 `checkReviewContent` — 모더레이션

```
onDocumentCreated('reviews/{reviewId}')
```

Phase 2: 길이 검증만. Phase 4: Perspective API 통합.

결과 `reviews.{moderationStatus, moderationScores, moderationCheckedAt}` 갱신. 거부 시 `feed_events`에서 `targetId==reviewId` → `fanoutStatus='invalidated'`.

---

## 4. 스케줄러

### 4.1 `aggregatePopularStores`

| 항목 | 값 |
|---|---|
| schedule | `every 1 hours` (KST) |
| 출력 | `aggregations/popularStores/byCountry/{country}` |
| 내용 | top 50 매장 ID + 점수 |
| 점수 | `(collection_added × 2) + (review_submitted × 3) + (rating_avg × 1.5)` |
| 윈도우 | 직전 24h |

iOS Map "지금 핫한 말차" 카루셀 — 클라가 직접 read (App Check만 필요).

### 4.2 `cleanupFeedEvents`

| 항목 | 값 |
|---|---|
| schedule | `every day 03:00` (KST) |
| 대상 | `feed_events.createdAt < now - 90d` |
| 동작 | 500/iter 삭제, 최대 25,000/run |

schema §7.5 + SCH-3.

### 4.3 `cleanupAnalyticsEvents`

| 항목 | 값 |
|---|---|
| schedule | `every day 04:00` (KST) |
| 대상 | `analytics/events/items.serverTs < now - 30d` |

schema §9. GA4 export가 SSOT, 본 컬렉션은 보조.

### 4.4 `recomputeStoreAggregates`

| 항목 | 값 |
|---|---|
| schedule | `every 1 hours` (KST) |
| 동작 | 직전 1h 활성 매장(`reviews.createdAt > 1h ago`의 distinct storeId)에 대해 reviewCount/ratingAvg/ratingHistogram 재계산 |

cost-projection §5 절감 레버 — 디노멀 drift 보정.

### 4.5 `cleanupStaleFcmTokens` (v1.3)

| 항목 | 값 |
|---|---|
| schedule | `30 4 * * *` (KST) |
| 대상 | collection_group `fcmTokens.lastSeenAt < now - 60d` |
| 동작 | 400/iter 삭제 |

schema §1A 정합.

### 4.6 `purgeDeletedUsers`

| 항목 | 값 |
|---|---|
| schedule | `every day 02:00` (KST) |
| 대상 | `users.deletedAt < now - 30d`, 100/run |
| 동작 | 사용자 서브컬렉션 일괄 삭제 + reviews soft-delete + Auth.deleteUser |

cost-projection §4.2 GDPR + 비용. 처음 deletedAt set은 사용자 탈퇴 시점(클라 요청).

---

## 4.7 헬퍼 함수 (v1.3)

### `sendNotificationToUser(uid, payload)` — push 발송

콜러블 X. Functions 내부에서만 import. push-payload.md (server-auth)와 정합.

```ts
interface PushPayload {
  notification?: { title?: string; body?: string };
  data?: Record<string, string>;
  category: 'friend_request' | 'friend_accepted' | 'feed_collection' | 'feed_review' | 'system';
}
interface SendResult { delivered: number; failed: number; pruned: number }

sendNotificationToUser(uid: string, payload: PushPayload): Promise<SendResult>
```

흐름:
1. `users/{uid}/fcmTokens` where `pushPermission ∈ ['granted','provisional']` read.
2. admin SDK `sendEachForMulticast`.
3. 401/404 응답 토큰 doc 삭제 (만료/디바이스 분리). pruned count 반환.
4. `lastSeenAt` 갱신 X (push 수신 ≠ 앱 활성).

호출자: `acceptFriend` (양쪽 알림), `submitReview` / `addCollectionItem` (친구 fanout 알림),
기타 시스템 알림 콜러블/트리거.

---

## 5. 향후 추가 (Phase 3+)

| 함수 | 종류 | 설명 |
|---|---|---|
| `verifyAdMobSsvCallback` | HTTPS | AdMob → 서버 SSV callback (signature 검증 + receipt 작성) |
| `onObjectFinalized` | Storage trigger | 사진 SafeSearch + EXIF 제거 |
| `resolveCountry` | Callable | IP geo 백업 (observability §2.1) |
| `redeemPasskeyChallenge` | Callable | Passkey AASA + WebAuthn 챌린지 검증 (server-auth ADR-303) |
| `fullScanRecomputeStoreAggregates` | Scheduled (일 1회) | 비활성 매장 풀 스캔 보정 |

---

## 6. 협업 합의 (Phase 2 → 3 게이트)

| 항목 | 책임 | 합의 시점 |
|---|---|---|
| AdMob SSV callback URL + transactionId 포맷 | server-functions ↔ ios-auth-monetize | Phase 3 |
| App Check enforce 시점 | server-auth | Phase 2 통합 직후 1주 |
| Places API 비용 영향 | server-lead ↔ po-growth | Phase 3 |
| `onUpdateStore` origin 디노멀 추가 여부 | server-data ↔ server-functions | Phase 3 |
| feed_events `targetId` 인덱스 (디노멀 fanout 효율) | server-data | Phase 3 |
| 사용자 탈퇴 콜러블(`requestUserDeletion`) | server-functions ↔ ios-auth-monetize | Phase 3 |

---

## 7. iOS 클라 정합 매트릭스

iOS `Data/Remote/RemoteFunctions.swift`가 본 문서의 typed payload와 1:1 매핑:

| 콜러블 | iOS 메서드 | 응답 변환 |
|---|---|---|
| `addCollectionItem` | `RemoteCollections.add(...)` | `Domain.CollectionItem.ID` |
| `submitReview` | `RemoteReviews.submit(...)` | `Domain.Review.ID` (+ optional CollectionItem.ID) |
| `requestFriend` | `RemoteFriends.request(...)` | `Void` |
| `acceptFriend` | `RemoteFriends.accept(...)` | `Void` |
| `removeFriend` | `RemoteFriends.remove(...)` | `Void` |
| `verifyRewardedAd` | `RemoteAds.verify(...)` | `Domain.RewardResult` |
| `mergeStoreSearch` | `RemoteSearch.merge(...)` | `Domain.SearchPage` (cursor-based) |

ErrorCodes는 iOS `Domain/Error.swift`의 enum으로 매핑. 추가/변경 시 양측 PR 동시 머지.

---

## 8. Changelog

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-04 | 초안 (콜러블 6 + 트리거 5 + 스케줄러 5 + 공통 규약). server-data ADR-302 정합: addCollectionItem/submitReview/friend* 콜러블, audienceUids 모델, 디노멀 fanout(onUpdateUser/onUpdateStore), cleanup/recompute/purge 스케줄러, cursor 페이지네이션. | server-functions (server-lead + ios-lead 사인오프 대기) |
| 2026-05-04 | ADR-302 v1.1/v1.2/v1.3 정합 보강: addCollectionItem enum 검증(grade `cooking`→`standard|culinary`, originRegion 9종+jeju, colorTier 5단계 enum→colorHex 자동) + design-system.md § 1.5.1 SSOT 인용; mergeStoreSearch `minPinTier` 필터; pinTier derive 트리거 2종(onCreate/onUpdateStorePinTier) + recomputeStoreAggregates 통합; fcmTokens 60d cleanup 스케줄러 + onWriteFcmToken 트리거 + sendNotificationToUser 헬퍼. | server-functions |
