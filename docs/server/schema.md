# Firestore Schema — 컬렉션/문서 상세

- **작성**: `server-data` · 2026-05-04
- **상태**: Phase 2 산출물 (server-lead + po-lead 사인오프 대상)
- **상위 결정**: [ADR-302 Firestore Schema](../architecture/ADR-302-firestore-schema.md), [ADR-301 Backend Choice](../architecture/ADR-301-backend-choice.md)
- **정합 문서**: [observability.md](observability.md) (이벤트↔컬렉션), [security-rules.md](security-rules.md) (P1~P6/S1~S3 패턴), [cost-projection.md](cost-projection.md) (read 최적화)

> 본 문서는 Firestore의 **단일 진실 원천**(SSOT). iOS Domain Entity는 본 스키마를 매핑하는 형태로만 정의 — 동일 모델 이중 정의 금지.

---

## 0. 공통 규약

### 0.1 식별자 정책

| 컬렉션 | 문서 ID | 근거 |
|---|---|---|
| `users` | Firebase Auth `uid` | Auth 발급 hash. uid == doc.id == 필드 `uid` (3중 일치). |
| `stores` | **Google Place ID** (`ChIJN1t...`) | 글로벌 고유 + 외부 재참조 시 충돌 회피. 매장 등록 v1.1.0에 자체 ID prefix(`mm_`) 도입 검토. |
| `reviews` | `reviewId` (auto, ULID) | 시간 정렬 가능한 ULID. (Firestore auto ID도 가능하나 정렬성 부족.) |
| `wishlists/{uid}/items` | `storeId` | 한 사용자 × 한 매장 = 단일 doc(중복 불가, idempotent toggle). |
| `collections/{uid}/items` | `itemId` (auto, ULID) | 같은 매장의 여러 음료(말차라떼/코이차 등)를 별도 카드로 등록 가능 → storeId 키로 못씀. |
| `friendships/{uid}/edges` | `friendUid` | 양방향 두 doc 저장(`A/edges/B` + `B/edges/A`) 디노멀라이제이션. |
| `feed_events` | `eventId` (auto, ULID) | 시간순 피드 정렬 + cursor pagination. |
| `analytics_sessions` | `sessionId` (클라 생성 UUID) | 클라 세션 식별. observability §1 SSOT. |
| `analytics_events` | `eventId` (auto, ULID) | 분석 이벤트 보조(GA4 export가 SSOT, 본 컬렉션은 Functions 내부 추적용). |

### 0.2 타임스탬프 정책

- **모든 timestamp는 Firestore `Timestamp`(server)**. 클라 wall-clock 절대 신뢰 금지.
- 작성: `FieldValue.serverTimestamp()` (클라 SDK 또는 Functions Admin SDK).
- `createdAt`은 **불변** (보안 규칙 `isUnchanged('createdAt')`).
- `updatedAt`은 write 시마다 갱신.

### 0.3 디노멀라이제이션 원칙

읽기 비용이 우선. 쓰기 시 fanout으로 정합 유지. 다음 필드는 의도적으로 **여러 컬렉션에 복제**됨:

| 원본 | 복제 위치 | 이유 |
|---|---|---|
| `users.{displayName,photoURL}` | `reviews.author{displayName,photoURL}`, `feed_events.actor{displayName,photoURL}` | 리뷰/피드 표시 시 user doc 추가 read 회피. |
| `stores.{name,country,city,primaryPhoto}` | `reviews.store{name,country,city,primaryPhoto}`, `collections/{uid}/items.store{...}`, `wishlists/{uid}/items.store{...}`, `feed_events.target{...}` | 매장 카드 표시 시 store doc 추가 read 회피. |
| `users.stats.{collectionCount,reviewCount,wishlistCount}` | `users` doc 자체에 집계 필드 | 프로필 화면 single read. |
| `stores.{matchaScore,reviewCount,ratingAvg}` | `stores` doc 자체에 집계 필드 | 매장 카드/맵 핀 색상 매핑. |

**fanout 갱신 책임**: Functions 트리거(`onCreate`/`onUpdate`/`onDelete`)가 처리. 클라 직접 fanout 금지.

### 0.4 페이지네이션

- **Cursor-based** 강제. `offset`/`page` 사용 금지(스킵 비용 증가).
- 패턴: `query.orderBy(field, dir).startAfter(lastDoc).limit(N)`.
- 클라가 `lastDoc.id` 또는 `[orderField, docId]` 튜플을 다음 요청 cursor로 전달.
- 리스트 화면 기본 `limit = 20`. 더보기 시 추가 20.

### 0.5 필드 표기

- `?` = optional (필드 자체 누락 가능). 없는 것과 `null`은 동일 취급.
- `[]` = array (Firestore array). 길이 제한 명시.
- `{}` = nested map.
- `→ Functions only` = 클라 write 금지(보안 규칙). Admin SDK만.

---

## 1. `users/{uid}`

사용자 프로필 + 집계 통계. Apple/Passkey 가입 시 Functions 트리거가 doc 생성.

### 1.1 필드

| 필드 | 타입 | 필수 | 제약 | 비고 |
|---|---|---|---|---|
| `uid` | string | Y | == doc.id == auth.uid | 3중 일치 invariant. |
| `displayName` | string | Y | 1–32 chars | 가입 시 Apple displayName 또는 자동 생성("말차러버#1234"). |
| `photoURL` | string? | N | https:// or gs:// | Apple Sign In privateRelay인 경우 null → 기본 아바타. |
| `locale` | string | Y | BCP-47 (`ko-KR` 등) | 가입 시 클라 디바이스 locale. |
| `homeCountry` | string | Y | ISO-3166 alpha-2 | observability §2.2 결정 로직. 첫 30일 보정 후 영구 동결. |
| `country` | string? | N | ISO-3166 alpha-2 | 현재 위치 국가. 클라가 위치 권한 허용 시 갱신. |
| `travelMode` | bool | Y | computed | `country != homeCountry` (observability §2.1). 기본 false. |
| `cohortD0` | timestamp | Y | server, 불변 | 가입 일자 KST 자정 기준. observability §1의 user property `cohort_d0` SSOT. |
| `authMethod` | string | Y | enum: `apple`, `passkey` | 가입 시 1회, 불변. |
| `createdAt` | timestamp | Y | server, 불변 | |
| `updatedAt` | timestamp | Y | server | write 시 갱신. |
| `stats` | map | Y | — | 집계 필드. **→ Functions only**. |
| `stats.collectionCount` | int | Y | ≥ 0 | 도감 항목 수. |
| `stats.reviewCount` | int | Y | ≥ 0 | 작성한 리뷰 수. |
| `stats.wishlistCount` | int | Y | ≥ 0 | 위시리스트 수. |
| `stats.friendCount` | int | Y | ≥ 0 | 수락된 친구 수. observability `friend_count` user property SSOT. |
| `notification` | map? | N | — | FCM 토큰/설정. |
| `notification.fcmToken` | string? | N | — | iOS 디바이스 토큰. 만료 시 Functions가 정리. |
| `notification.feedEnabled` | bool? | N | default true | 친구 피드 푸시 on/off. |
| `deletedAt` | timestamp? | N | server | 탈퇴 soft-delete. 30일 후 hard delete (cost-projection §4.2 GDPR + 비용). |

### 1.2 보안 규칙 매핑

`security-rules.md` § 3.2 패턴 P1. 본인만 R/W. `createdAt`/`uid`/`stats.*`/`cohortD0`/`authMethod` 변경 차단(unchanged 검증).

### 1.3 인덱스

- 단일 필드 자동 인덱스로 충분(컬렉션 간 쿼리 없음, 사용자 lookup은 doc.id 직접).
- `users` 검색은 username 기준은 v1.1.0 (별도 `usernames/{handle}` lookup 컬렉션 도입).

### 1.4 observability 정합

- `cohortD0` ↔ user property `cohort_d0`: 가입 시 1회 set, 불변.
- `stats.friendCount` ↔ user property `friend_count`: Functions가 friendship accepted 시 ±1, 매월 첫 세션 클라가 user property로 갱신.
- `homeCountry`/`country`/`travelMode` ↔ user property `home_country`/`country`/`travel_mode`: 클라가 user property로도 set.

---

## 2. `stores/{placeId}`

매장 마스터. 문서 ID = Google Place ID. v1.0.0은 **사용자 등록 불가, 큐레이션 시드만**.

### 2.1 필드

| 필드 | 타입 | 필수 | 제약 | 비고 |
|---|---|---|---|---|
| `placeId` | string | Y | == doc.id, Google Place ID 포맷 | |
| `name` | string | Y | 1–120 chars | 다국어는 `nameI18n` 별도(아래). |
| `nameI18n` | map? | N | key: BCP-47, value: string | `{"ko":"마차하우스","ja":"抹茶ハウス"}`. v1.0.0은 ko/ja만 시드. |
| `country` | string | Y | ISO-3166 alpha-2 | 매장 국가. 디노멀(`reviews`/`wishlists`/`collections`/`feed_events`로 복제). |
| `city` | string | Y | 1–80 chars | 영문 또는 매장 국가 언어. |
| `address` | string | Y | 1–240 chars | full address. |
| `lat` | double | Y | -90 ~ 90 | |
| `lng` | double | Y | -180 ~ 180 | |
| `geohash` | string | Y | length 9 | viewport bbox 쿼리용. Functions가 lat/lng에서 자동 계산. |
| `types` | array<string> | Y | 1–8 items, enum | `cafe`, `dessert`, `tea_house`, `bakery`, `restaurant`, `omakase`. |
| `matchaScore` | double | Y | 0.0 ~ 5.0 | 큐레이터 또는 Functions 집계. 4등급 핀 색상 매핑(`designer-icon` MatchaPin). |
| `priceLevel` | int | Y | 1 ~ 4 | Google Places 호환. |
| `openingHours` | map? | N | — | 요일별 open/close. |
| `openingHours.{mon..sun}` | array<{open,close}> | N | HH:mm | 휴무 시 빈 배열. |
| `photos` | array<string> | Y | 0–10 items, gs:// or https:// | 매장 사진. `primaryPhoto`는 photos[0]가 디폴트. |
| `primaryPhoto` | string? | N | — | 카드 미리보기. 없으면 photos[0]. |
| `coverPhoto` | string? | N | — | 매장 상세 헤더(고화질). |
| `origin` | map? | N | — | **말차 원산지 메타** (po-lead 요청, designer-lead screens.md 정합). v1.0.0 MVP는 알려진 노포/브랜드만 시드 채움. 페르소나 2(로컬 도감러) "원산지/등급/색감 비교" Top 3 Need 핵심. 도감 카드 등록 시 country는 자동, region/grade는 사용자 선택 입력으로 보완. |
| `origin.region` | string? | N | enum 권장 + free string 허용 | `uji`, `nishio`, `shizuoka`, `kagoshima`, `boseong`, `hadong`, `jeju`, `other`. enum 외 값은 큐레이터 입력 허용(자유 문자열). 도감 그리드 원산지별 그룹핑의 SSOT. |
| `origin.country` | string? | N | ISO-3166 alpha-2 | 원산지 국가. 매장 country와 다를 수 있음(예: 한국 카페에서 우지 말차 사용 = `stores.country=KR`, `origin.country=JP`). |
| `origin.grade` | string? | N | enum: `ceremonial`, `premium`, `standard`, `culinary` | 등급. 사용자 입력보다 큐레이터/공급원 정보가 우선. `collections/items.grade`(사용자 도감 입력)와 별개의 매장 단위 SSOT. |
| `origin.notes` | string? | N | 0 – 200 chars | 사용자 표시용 짧은 설명("우지산 격조 등급, 마루큐 코야마엔 공급"). |
| `reviewCount` | int | Y | ≥ 0 | **→ Functions only**. 디노멀 집계. |
| `ratingAvg` | double | Y | 0.0 ~ 5.0 | **→ Functions only**. 가중 평균. |
| `ratingHistogram` | map? | N | `{"1":int,...,"5":int}` | **→ Functions only**. 평점 분포. |
| `tagsTop` | array<string> | N | 0–10 items | **→ Functions only**. 리뷰 태그 빈도 상위. |
| `verified` | bool | Y | default false | **→ Functions only**. 큐레이터 인증 매장. |
| `seedSource` | string | N | enum: `google_places`, `editor`, `partner` | 시드 출처. |
| `createdAt` | timestamp | Y | server | |
| `updatedAt` | timestamp | Y | server | |

### 2.2 보안 규칙 매핑

`security-rules.md` § 3.3 패턴 P2. 누구나 read, write는 Functions Admin SDK만.

### 2.3 인덱스

복합 인덱스(`firestore.indexes.json` 정의):

| 쿼리 | 필드 | dir |
|---|---|---|
| viewport bbox + 등급 | `country` ASC, `geohash` ASC, `matchaScore` DESC | 도시 줌 인 시 매장 핀 로딩 |
| 검색 결과 (city + score) | `city` ASC, `matchaScore` DESC | 검색 화면 정렬 |
| 타입 필터 | `country` ASC, `types` ARRAY, `matchaScore` DESC | "도쿄에서 omakase 매장" |
| 인증 매장 | `country` ASC, `verified` ASC, `matchaScore` DESC | 큐레이션 추천 |
| 원산지 필터 | `origin.region` ASC, `matchaScore` DESC | "우지산 말차 사용 매장" 도감 그리드 그룹/필터 (po-lead 요청) |

> **Geohash 전략**: Phase 2에서는 9자리 geohash prefix 매칭으로 viewport 조회. v1.1.0+에서 정밀도 부족(km 단위) 시 GeoFirestore 라이브러리 또는 S2 cell 도입 검토 (ADR-302 § viewport 쿼리 결정 참조).

### 2.4 observability 정합

- `store_view.country` ↔ `stores.country`: 매장 국가는 사용자 위치와 다를 수 있음(여행 모드 분석 핵심).
- `store_view.store_id` ↔ `stores.{placeId}` doc.id.

---

## 3. `reviews/{reviewId}`

매장 리뷰. **컬렉션 그룹 쿼리 사용** (사용자별 리뷰 + 매장별 리뷰 둘 다 같은 컬렉션에서).

### 3.1 필드

| 필드 | 타입 | 필수 | 제약 | 비고 |
|---|---|---|---|---|
| `reviewId` | string | Y | == doc.id, ULID | |
| `storeId` | string | Y | Google Place ID | `stores/{placeId}` 참조. |
| `uid` | string | Y | == author.uid | 작성자. |
| `rating` | int | Y | 1 ~ 5 | |
| `body` | string | Y | 1 – 2000 chars | |
| `photos` | array<string> | N | 0 – 4 items, gs:// | Storage 경로 (`reviews/{reviewId}/{n}.jpg`). |
| `tags` | array<string> | N | 0 – 8 items, enum | `koicha`, `usucha`, `latte`, `dessert`, `bitter`, `sweet`, `umami`, `traditional`, `modern`, `instagrammable`. |
| `drink` | string? | N | enum: `usucha`, `koicha`, `matcha_latte`, `iced_matcha`, `dessert`, `other` | 도감 자동 생성 시 사용. |
| `country` | string | Y | ISO-3166 alpha-2 | **디노멀** from `stores.country`. observability `store_view.country` 정합. |
| `author` | map | Y | — | **디노멀** from `users`. |
| `author.uid` | string | Y | == reviews.uid | |
| `author.displayName` | string | Y | 1 – 32 chars | |
| `author.photoURL` | string? | N | — | |
| `store` | map | Y | — | **디노멀** from `stores`. |
| `store.placeId` | string | Y | == reviews.storeId | |
| `store.name` | string | Y | — | |
| `store.city` | string | Y | — | |
| `store.country` | string | Y | == reviews.country | |
| `store.primaryPhoto` | string? | N | — | |
| `likeCount` | int | Y | ≥ 0, default 0 | **→ Functions only**. P6 패턴. |
| `flagged` | bool | Y | default false | **→ Functions only**. 모더레이션 신고. |
| `flagCount` | int | Y | ≥ 0, default 0 | **→ Functions only**. |
| `createdAt` | timestamp | Y | server, 불변 | |
| `updatedAt` | timestamp | Y | server | |
| `deletedAt` | timestamp? | N | server | soft-delete. |

### 3.2 보안 규칙 매핑

`security-rules.md` § 3.4 패턴 P3. 누구나 read, 작성자만 create/update/delete. `likeCount`/`flagged`/`flagCount` 클라 변경 차단.

### 3.3 인덱스

| 쿼리 | 필드 | dir |
|---|---|---|
| 매장별 최신 리뷰 | `storeId` ASC, `createdAt` DESC | 매장 상세 화면 |
| 매장별 평점 정렬 | `storeId` ASC, `rating` DESC, `createdAt` DESC | "별점 높은 순" |
| 사용자 리뷰 | `uid` ASC, `createdAt` DESC | 프로필 화면 (collection group OK) |
| 모더레이션 큐 | `flagged` ASC, `flagCount` DESC | 운영 어드민 (Functions) |

### 3.4 observability 정합

- 보조 이벤트 `review_submit` (observability §3.10) 발화 = 본 리뷰 doc create 직후 클라 또는 Functions 측. 카운트 증분은 Functions가 `users.stats.reviewCount` + `stores.reviewCount`/`ratingAvg`/`ratingHistogram` 갱신.

---

## 4. `wishlists/{uid}/items/{storeId}`

사용자 위시리스트. **doc.id = storeId** = idempotent toggle.

### 4.1 필드

| 필드 | 타입 | 필수 | 제약 | 비고 |
|---|---|---|---|---|
| `storeId` | string | Y | == doc.id, Google Place ID | |
| `uid` | string | Y | == 부모 컬렉션 path uid | invariant. |
| `note` | string? | N | 0 – 200 chars | "다음 도쿄 출장 때". |
| `country` | string | Y | ISO-3166 alpha-2 | **디노멀** from `stores.country`. 국가별 그룹 쿼리. |
| `store` | map | Y | — | **디노멀** from `stores` (placeId/name/city/country/primaryPhoto/matchaScore). |
| `addedAt` | timestamp | Y | server | |

### 4.2 보안 규칙 매핑

`security-rules.md` § 3.5 패턴 P4. 본인만 R/W (`isSelf(uid)`). doc.id는 storeId 그대로(다른 매장으로 변경 불가는 create 시 검증).

### 4.3 인덱스

| 쿼리 | 필드 | dir |
|---|---|---|
| 국가별 위시리스트 | `country` ASC, `addedAt` DESC | "위시리스트 — 일본 5곳" 그룹 화면 |
| 최신 추가 | `addedAt` DESC | 기본 정렬 |

서브컬렉션이므로 부모 path(`wishlists/{uid}/items`)에 자동 한정. uid 컬럼은 보안 규칙 invariant 검증용.

### 4.4 fanout

- 위시리스트 추가/삭제 시 Functions가 `users.stats.wishlistCount` ±1.
- `feed_events` 발화 안 함 (위시는 사적 의도. 친구에 노출 X).

---

## 5. `collections/{uid}/items/{itemId}`

사용자 도감. **같은 매장의 여러 음료를 별도 카드로 등록 가능** → doc.id = ULID(스토어 ID 아님).

### 5.1 필드

| 필드 | 타입 | 필수 | 제약 | 비고 |
|---|---|---|---|---|
| `itemId` | string | Y | == doc.id, ULID | |
| `uid` | string | Y | == 부모 path uid | invariant. |
| `storeId` | string | Y | Google Place ID | |
| `drink` | string | Y | enum: `usucha`, `koicha`, `matcha_latte`, `iced_matcha`, `matcha_dessert`, `other` | |
| `grade` | string? | N | enum: `ceremonial`, `premium`, `cooking`, `unknown` | 사용자 입력. |
| `originRegion` | string? | N | enum: `uji`, `nishio`, `kagoshima`, `shizuoka`, `boseong`, `hadong`, `other`, `unknown` | 산지. |
| `colorHex` | string? | N | `#RRGGBB` | 사용자 추출 색감(시그니처 카드). designer-lead 도감 카드 사양 참조. |
| `note` | string? | N | 0 – 500 chars | 메모. |
| `photos` | array<string> | N | 0 – 3 items, gs:// | Storage `users/{uid}/collection/{itemId}/{n}.jpg`. |
| `country` | string | Y | ISO-3166 alpha-2 | **디노멀** from `stores.country`. |
| `store` | map | Y | — | **디노멀** from `stores` (placeId/name/city/country/primaryPhoto). |
| `viaReview` | bool | Y | default false | true = 리뷰 작성 시 자동 등록. observability `store_collection_added.via_review` 정합. |
| `linkedReviewId` | string? | N | reviews.reviewId | viaReview=true일 때 연결. |
| `visitedAt` | timestamp | Y | server (또는 클라 입력 — 도감은 과거 시음 추가 허용) | 시음 일자. |
| `createdAt` | timestamp | Y | server, 불변 | doc 생성 시각(분석용). |
| `updatedAt` | timestamp | Y | server | |

> **`visitedAt` 예외**: 도감은 "지난 출장 때 시음" 등 과거 입력 허용. 클라 입력값 OK이나 `createdAt`은 서버 강제. 분석 시 도감 등록률 7일 윈도우는 `createdAt` 기준(observability §3.4 `time_since_view_min`).

### 5.2 보안 규칙 매핑

`security-rules.md` § 3.6 패턴 P5. read는 본인, write는 Functions만 — 클라는 콜러블 `addCollectionItem`/`updateCollectionItem`/`deleteCollectionItem` 호출. **이유**: 도감 등록 시 4개 컬렉션 fanout 필요(`collections` create + `users.stats.collectionCount` ±1 + `stores`(미사용) + `feed_events` create). 트랜잭션을 클라에 맡기지 않음.

### 5.3 인덱스

| 쿼리 | 필드 | dir |
|---|---|---|
| 시간순 도감 | `visitedAt` DESC | 기본 그리드 |
| 국가별 도감 | `country` ASC, `visitedAt` DESC | 미니 세계지도 그룹 |
| 음료 종류별 | `drink` ASC, `visitedAt` DESC | 필터 |
| 등급별 | `grade` ASC, `visitedAt` DESC | "Ceremonial 등급만" |

### 5.4 observability 정합 — 도감 등록률 SSOT

`store_collection_added` 이벤트 ↔ 본 doc create:
- `store_id` = 본 doc.`storeId`
- `via_review` = 본 doc.`viaReview`
- `country` = 본 doc.`country`
- `time_since_view_min` = 본 doc.`createdAt` − 가장 최근 동일 (uid, storeId)의 `store_view` event_timestamp

도감 등록률 = (이 doc create) / (`store_view` 고유 (uid, storeId)) — observability §4 매트릭스 정합.

### 5.5 fanout

도감 추가 시 Functions(`onAddCollectionItem`):
1. `collections/{uid}/items/{itemId}` create.
2. `users/{uid}.stats.collectionCount` += 1.
3. `feed_events` create (audience=`friends`, type=`collection`, target=storeId, actor=uid).
4. `analytics_events` audit log (선택).

---

## 6. `friendships/{uid}/edges/{friendUid}`

친구 그래프. **양방향 두 doc 저장**(A→B + B→A). 디노멀라이제이션으로 친구 목록 read 비용 ↓.

### 6.1 필드

| 필드 | 타입 | 필수 | 제약 | 비고 |
|---|---|---|---|---|
| `friendUid` | string | Y | == doc.id | 상대방 uid. |
| `uid` | string | Y | == 부모 path uid | 본인 uid. invariant. |
| `status` | string | Y | enum: `pending_outgoing`, `pending_incoming`, `accepted`, `blocked` | 상태머신. |
| `friend` | map | Y | — | **디노멀** from `users/{friendUid}`. |
| `friend.uid` | string | Y | == friendUid | |
| `friend.displayName` | string | Y | — | |
| `friend.photoURL` | string? | N | — | |
| `friend.country` | string? | N | — | |
| `requestedAt` | timestamp | Y | server | 요청 시각. |
| `acceptedAt` | timestamp? | N | server | 수락 시각(status=accepted일 때). |
| `addMethod` | string | Y | enum: `qr`, `username`, `share_link`, `address_book` | observability `friend_added.add_method` 정합. v1.0.0은 `qr`만. |

### 6.2 양방향 doc 정합 (Functions 책임)

- 사용자 A가 B에 친구 요청 → Functions:
  - `friendships/A/edges/B` = `{status: pending_outgoing, ...}`
  - `friendships/B/edges/A` = `{status: pending_incoming, ...}`
- B가 수락 → Functions:
  - 두 doc `status=accepted`, `acceptedAt=now`
  - `users/A.stats.friendCount` += 1, `users/B.stats.friendCount` += 1
- 차단/삭제도 동일 패턴.

> **fanout-on-write vs fanout-on-read 결정** (ADR-302 § fanout): 친구 ≤ 500이면 fanout-on-write, > 500이면 fanout-on-read 하이브리드. v1.0.0은 친구 평균 5–15명(ICP 페르소나 3) → 단순 fanout-on-write 채택.

### 6.3 보안 규칙

서브컬렉션 소유자 read만(`isSelf(uid)`). write는 Functions Admin SDK만(콜러블 `requestFriend`/`acceptFriend`/`removeFriend`).

### 6.4 인덱스

| 쿼리 | 필드 | dir |
|---|---|---|
| 수락된 친구 목록 | `status` ASC, `acceptedAt` DESC | 친구 화면 |
| 받은 요청 | `status` ASC, `requestedAt` DESC | "친구 요청 N건" |

부모 path 한정으로 status만으로 충분(uid는 path).

---

## 7. `feed_events/{eventId}`

친구 피드 이벤트. fanout-on-write 결과 doc(친구 ≤ 500). 친구 수 ≥ 500이면 fanout-on-read 하이브리드(ADR-302 § fanout).

### 7.1 필드

| 필드 | 타입 | 필수 | 제약 | 비고 |
|---|---|---|---|---|
| `eventId` | string | Y | == doc.id, ULID | |
| `actorUid` | string | Y | — | 행동 주체 uid. |
| `audienceUids` | array<string> | Y | 0 – 500 items | **fanout-on-write 결과**. 본인 + 수락 친구. read 시 `array-contains` 쿼리. |
| `type` | string | Y | enum: `collection`, `review`, `checkin`, `friend_added` | event 종류. |
| `targetType` | string | Y | enum: `store`, `review`, `collection_item`, `user` | target 종류. |
| `targetId` | string | Y | placeId / reviewId / itemId / uid | |
| `actor` | map | Y | — | **디노멀** from `users` (uid/displayName/photoURL). |
| `target` | map | Y | — | **디노멀** target (store map 또는 user map). |
| `payload` | map? | N | type-specific | type=`review`일 때 `{rating, body_excerpt, photos[0]}`, type=`collection`일 때 `{drink, grade, colorHex}`. |
| `country` | string? | N | ISO-3166 alpha-2 | 매장 country (피드 필터 분석용). |
| `visibility` | string | Y | enum: `friends`, `public` | v1.0.0은 friends 전용. public은 v1.1.0(인플루언서 공개 피드). |
| `createdAt` | timestamp | Y | server | 피드 정렬 키. |

### 7.2 fanout 결정

- **fanout-on-write** (디폴트, 친구 ≤ 500):
  - 도감 추가/리뷰/친구 수락 시 Functions가 `feed_events` doc 1건 create + `audienceUids` = `[actorUid, ...acceptedFriends]` (본인 자기 피드도 포함).
  - 클라 read는 `where('audienceUids', 'array-contains', myUid).orderBy('createdAt','desc').limit(20)`.
- **fanout-on-read 하이브리드** (친구 > 500, v1.x.x 트리거):
  - `feed_events` 컬렉션은 actor 단위 doc만 1건 (audienceUids 미적용).
  - 클라 read는 친구 N명에 대해 N개 쿼리 병렬 + 클라 머지.
  - 친구 ≤ 500은 fanout 비용 ≪ N 병렬 read 비용. 친구 ≥ 500은 역전.
- 임계 모니터링: `users.stats.friendCount` p99 추적. 500 도달 시 ADR-302-rev1.

### 7.3 보안 규칙

read = `request.auth.uid in audienceUids`. write = Functions Admin SDK만.

### 7.4 인덱스

| 쿼리 | 필드 | dir |
|---|---|---|
| 내 피드 (audience-based) | `audienceUids` ARRAY, `createdAt` DESC | 피드 화면 |
| 사용자별 활동 | `actorUid` ASC, `createdAt` DESC | 프로필 활동 탭 (자기 + 친구만 보이도록 클라/규칙 처리) |

### 7.5 retention

- 피드 이벤트 90일 후 자동 삭제 (Cloud Scheduler + Functions). 비용 절감 + 사용자 기대(피드는 최근만).
- 도감/리뷰 본체 doc은 영구 보관(피드 이벤트는 derived).

### 7.6 observability 정합

- type=`collection` event 발화 = `store_collection_added` analytics 이벤트와 1:1 (Functions가 둘 다 발화).
- type=`review` event 발화 = `review_submit` analytics 이벤트와 1:1.

---

## 8. `analytics/sessions/{sessionId}` (선택, GA4 보조)

> **상태**: GA4 export가 분석 SSOT. 본 컬렉션은 Functions 내부 추적 + 짧은 윈도우 디버깅용. v1.0.0은 **선택 도입** — Phase 3 BigQuery export 활성화 시 본 컬렉션 deprecate 검토.

### 8.1 필드

| 필드 | 타입 | 필수 | 제약 | 비고 |
|---|---|---|---|---|
| `sessionId` | string | Y | == doc.id, UUID | observability §1 SSOT. |
| `uid` | string? | N | — | 인증 시. |
| `country` | string? | N | — | user property snapshot. |
| `homeCountry` | string? | N | — | |
| `travelMode` | bool? | N | — | |
| `locale` | string? | N | — | |
| `appVersion` | string | Y | — | |
| `buildNumber` | string | Y | YYMMDD_HHMM | |
| `startedAt` | timestamp | Y | server | |
| `endedAt` | timestamp? | N | server | 30분 무활동 또는 백그라운드 후 갱신. |
| `eventCount` | int | Y | ≥ 0 | 본 세션 이벤트 수. |

보안: read = self, write = Functions only (콜러블 `recordSession`).

---

## 9. `analytics/events/{eventId}` (선택)

> **상태**: GA4 export가 SSOT. 본 컬렉션은 디버그/실시간 모니터링용 임시 미러. **30일 후 자동 삭제** (Cloud Scheduler).

| 필드 | 타입 | 필수 | 제약 |
|---|---|---|---|
| `eventId` | string | Y | == doc.id, ULID |
| `eventName` | string | Y | observability §3 카탈로그 |
| `uid` | string? | N | — |
| `sessionId` | string? | N | — |
| `params` | map | Y | observability §3 이벤트별 정의 |
| `userProperties` | map | Y | observability §1 |
| `serverTs` | timestamp | Y | server (= `event_server_ts` SSOT) |
| `clientTs` | timestamp? | N | 디바이스 시각 (감사용) |

---

## 10. 컬렉션 그룹 쿼리 (Collection Group Queries)

다음 쿼리는 **컬렉션 그룹**(같은 이름의 모든 서브컬렉션 검색)을 사용:

| 쿼리 | 컬렉션 그룹 | 인덱스 |
|---|---|---|
| 사용자별 리뷰 (프로필 활동) | `reviews` (단일 최상위) | uid + createdAt 인덱스 |
| 매장별 위시리스트 카운트 (집계용) | `items` (`wishlists/*/items`) | storeId + addedAt — Functions 집계. |
| 매장별 도감 카운트 (집계용) | `items` (`collections/*/items`) | storeId + visitedAt — Functions 집계. |

> Functions가 위 쿼리를 사용 시 `firestore.indexes.json`에 `queryScope: COLLECTION_GROUP` 인덱스 명시.

---

## 11. 변경 영향 매트릭스

스키마 변경 시 다음 산출물 동시 갱신 필요:

| 변경 종류 | 갱신 대상 |
|---|---|
| 필드 추가(optional) | 본 schema.md, ADR-302 changelog, iOS Domain Entity 매핑 |
| 필드 추가(required) | 위 + migrations/{version}.md (backfill Function), security-rules.md |
| 필드 삭제 | 위 + 30일 dual-read 기간 + Functions 삭제 |
| 컬렉션 추가 | 위 + erd.md 갱신 + firestore.indexes.json + security-rules.md 새 패턴 |
| 인덱스 추가 | firestore.indexes.json + 본 schema.md § 인덱스 |

---

## 12. Open Items

| ID | 항목 | 책임 | 마감 |
|---|---|---|---|
| SCH-1 | 매장 viewport 쿼리 — geohash 9자리 vs S2 cell 정밀도 비교 | server-data + ios-map | Phase 3 |
| SCH-2 | username/handle 도입(친구 추가 username 검색) | server-data | v1.1.0 |
| SCH-3 | feed_events 90일 자동 삭제 Cloud Scheduler 설정 | server-functions | Phase 3 |
| SCH-4 | analytics_events 컬렉션 v1.0.0 도입 여부 최종 결정 (BigQuery export 비용과 비교) | server-lead | Phase 3 |
| SCH-5 | matchaScore 계산식 (큐레이터 입력 vs 가중평균) | server-data + po-growth | Phase 3 |
| SCH-6 | 친구 ≥ 500 fanout 임계 알림 모니터링 | server-functions | Phase 3 |

---

## 13. Changelog

| 일자 | 변경 | 작성자 |
|---|---|---|
| 2026-05-04 | 초안 (10 컬렉션 + 컬렉션 그룹 + 변경 영향 매트릭스) | server-data |
