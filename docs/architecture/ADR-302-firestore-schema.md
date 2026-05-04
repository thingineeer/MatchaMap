# ADR-302 — Firestore 데이터 모델 (스키마 결정 근거)

- **일자**: 2026-05-04
- **상태**: Accepted (Phase 2)
- **결정자**: `server-data`
- **사인오프**: `server-lead`, `po-lead` (대기)
- **리뷰어**: `server-auth`, `server-functions`, `ios-lead`, `ios-store`, `ios-social-collection`, `ios-map`
- **상위 결정**: [ADR-301 — 백엔드 Firebase](ADR-301-backend-choice.md) v2
- **SSOT 산출물**:
  - [docs/server/schema.md](../server/schema.md) — 컬렉션/필드 단일 진실 원천
  - [docs/server/erd.md](../server/erd.md) — 엔티티 관계도
  - [firestore.indexes.json](../../firestore.indexes.json) — 복합 인덱스
  - [docs/server/migrations/v1.0.0.md](../server/migrations/v1.0.0.md) — 부트스트랩 + Backfill 패턴 템플릿

> 본 ADR은 **결정 사유서**. 컬렉션·필드 디테일은 [schema.md](../server/schema.md)가 SSOT. 충돌 시 schema.md 우선이며 본 ADR을 보강한다.

---

## 컨텍스트

ADR-301에서 Firebase / Firestore Native Mode / `asia-northeast3` 채택 확정. v1.0.0 9개 모듈(PRD §3)을 위한 데이터 모델이 필요하며, 모델은:

1. **PRD §4 측정 지표**(D1/D7 retention, 도감 등록률, 친구 1+ 비율)를 효율적으로 산출 가능해야 한다.
2. **observability.md §3 이벤트 카탈로그**(`store_view`, `store_collection_added`, `friend_added` 등)와 1:1 정합되어야 한다.
3. **cost-projection.md** 시나리오 B(MAU 10K, 월 ~$17)를 유지하기 위한 **read 비용 최적화**가 필요하다 (LBS 앱 평균 1 DAU당 일 122 reads).
4. **iOS Domain Entity와 1:1 매핑** 가능해야 하고, 동일 모델을 클라/서버에서 이중 정의하지 않는다 (server-data agent 정의 § 협업 룰).

---

## 결정 (요약)

| # | 결정 | 핵심 이유 |
|---|---|---|
| D1 | 매장 ID = **Google Place ID** | 글로벌 고유 + 외부 재참조 충돌 회피. v1.1.0 UGC 매장은 `mm_` prefix로 분기. |
| D2 | **디노멀라이제이션 적극** (read 비용 우선) | LBS 앱은 read 폭증. 1 review = 1 read로 author + store 정보 모두 포함. fanout 책임은 Functions. |
| D3 | **fanout-on-write** (친구 ≤ 500) → fanout-on-read 하이브리드 (> 500) | v1.0.0 친구 평균 5–15명(ICP 페르소나 3). 단일 임계 모니터링으로 자연 전환. |
| D4 | **서버 timestamp 강제** (`FieldValue.serverTimestamp()`) | 클라 시계 조작 방지. observability `event_server_ts` SSOT 정합. |
| D5 | **Cursor-based 페이지네이션** 강제 (`startAfter` + `limit`, 디폴트 20) | offset 스킵 비용 회피. 친구 피드/리뷰/도감 모든 리스트 화면 적용. |
| D6 | **9-char Geohash** viewport 쿼리 (v1.0.0) | 첫 출시는 도시 단위 zoom 충분. v1.1.0+ 정밀도 부족 시 S2 cell/GeoFirestore 검토. |
| D7 | **`stores.origin` 메타** 도입 (po-lead 요청, designer-lead 정합) | 페르소나 2(로컬 도감러) "원산지/등급/색감" Top 3 Need 핵심 SSOT. |

---

## 결정 근거 (상세)

### D1 — 매장 ID = Google Place ID

#### 옵션
- (A) Google Place ID 그대로 doc.id (`ChIJN1t...`).
- (B) 자체 ID (`mm_<ulid>`) + 외래키로 `googlePlaceId` 필드.
- (C) 하이브리드: Place ID 우선, 미존재 시 자체 ID.

#### 결정: A 채택 + v1.1.0 UGC는 (C) 하이브리드.

**근거**:
1. v1.0.0은 **사용자 매장 등록 비범위** (PRD §9). 모든 매장은 큐레이터 시드 = Google Place 기반.
2. Google Place ID는 영구 식별자. 매장 폐업 시에도 ID는 살아있음(`business_status`만 변경).
3. Maps SDK 통합 시 클라 측 → Firestore 매장 lookup이 단일 키로 가능. 해시맵 변환 비용 0.
4. 외부 공유 카드 OG 이미지(launch-plan.md §4 그로스 루프)에 Place ID URL 직접 사용 가능.

#### 트레이드오프
- 매장 등록 v1.1.0+ 시 Place ID 미존재 케이스 처리 필요 → `mm_<ulid>` prefix로 자체 발급. 코드 비용 < ID 마이그레이션 비용.

---

### D2 — 디노멀라이제이션 적극

#### 옵션
- (A) 정규화 우선: 리뷰 카드 = 1 review + 1 user + 1 store = 3 reads.
- (B) 디노멀 적극: 리뷰 doc에 `author{}` + `store{}` 스냅샷 저장 = 1 read.
- (C) GraphQL 게이트웨이로 클라 측 join.

#### 결정: B 채택.

**근거**:
1. cost-projection.md §3 시나리오 B(MAU 10K) 일 305K reads → 정규화 시 3배 = 915K reads → 월 비용 $50 (실측 예측). 디노멀로 1/3 절감.
2. PRD §4 가드레일 "도시 줌 P95 ≤ 600ms"(시나리오 비기능 §6) — read 1회 < 100ms vs read 3회 + join > 250ms. 정규화 시 P95 위반.
3. fanout 갱신은 **드문 이벤트** (사용자 displayName 변경 ≤ 1회/월/사용자). 갱신 비용 << 평상시 read 절감.

#### 트레이드오프 + 완화
- **디노멀 drift**: 사용자/매장 doc 변경 시 모든 복제 필드 fanout 필요. → Functions `onUpdate` 트리거가 책임. cost-projection.md §5 절감 레버 재계산 작업(`recomputeStoreAggregates` 매시 정각)이 drift 보정.
- **Schema 변경 비용 ↑**: 새 디노멀 필드 추가 시 backfill Function 필요. → migrations/v1.0.0.md §5 Backfill 패턴 표준화로 비용 정형화.

#### 디노멀 필드 명시
schema.md §0.3 매트릭스에 모든 디노멀 필드 등록. 변경 시 §11 영향 매트릭스로 동시 갱신.

---

### D3 — fanout-on-write (친구 ≤ 500) + fanout-on-read 하이브리드 (> 500)

#### 옵션
- (A) 항상 fanout-on-write: `feed_events.audienceUids[]` 배열에 모든 수락 친구 + 본인 포함.
- (B) 항상 fanout-on-read: actor 단위 doc 1건만, 클라가 친구 N명 병렬 쿼리 → 머지.
- (C) 하이브리드: 친구 ≤ N이면 (A), 초과 시 (B).

#### 결정: C 채택 (임계 N=500).

**근거**:
1. v1.0.0 친구 평균 5–15명(ICP 페르소나 3). 99%+ 사용자가 100 미만 → fanout-on-write 비용은 발화당 ≤ 16 writes(본인+친구).
2. fanout-on-read는 N개 병렬 쿼리 = N reads × M 친구 = O(N×M). 친구 수가 적을 때는 O(M) write의 fanout-on-write가 절대 우위.
3. 임계 N=500은 Firestore array 권장 한계(arrayContains ≤ 1MB doc) + Functions batch ≤ 500 정합.

#### 임계 모니터링 (필수)
- `users.stats.friendCount` p99 추적 (Cloud Monitoring).
- 500 도달 시 ADR-302-rev1 작성 → fanout-on-read 모드 추가 (audienceUids 미설정 doc + 클라 N개 병렬 쿼리 폴백).
- v1.0.0은 단일 모드(fanout-on-write)로 시작.

#### 트레이드오프
- 디노멀 drift와 동일 — 친구 displayName/photoURL 변경 시 그 친구가 actor인 모든 feed_events doc의 audienceUids 측 친구 정보 갱신은 미반영(actor 정보만 갱신). 피드 카드는 **actor 정보만 표시**(audience 측 친구 정보 노출 안 함)이므로 영향 없음.

---

### D4 — 서버 timestamp 강제

모든 `createdAt`/`updatedAt`/`requestedAt`/`acceptedAt`/`addedAt` 등은 `FieldValue.serverTimestamp()` 사용. 클라 wall-clock 신뢰 금지.

**근거**:
- observability.md §0 원칙 1: "사용자/세션/이벤트의 시간 기준은 서버 수신 시각(`event_server_ts`)".
- 시계 조작 사용자가 도감 등록 시점을 조작하여 H1 가설(travel_mode 도감 등록률) 데이터 오염 차단.
- 분석 SQL의 시간 윈도우 정합(7d 도감 윈도우, D1/D7 코호트 윈도우)이 일관됨.

**예외**: `collections/items.visitedAt`은 클라 입력 허용 — 도감은 "지난 출장 시음 추가" 케이스가 있어 과거 입력 OK. 단 `createdAt`은 서버 강제, 분석은 `createdAt` 기준 (schema.md §5.1 본문 명시).

---

### D5 — Cursor-based 페이지네이션

- 모든 리스트 쿼리는 `query.orderBy(field, dir).startAfter(lastDoc).limit(N)` 강제.
- 디폴트 limit = 20 (피드/리뷰/도감/위시리스트).
- offset/page 파라미터 사용 금지.

**근거**:
- offset 사용 시 Firestore가 스킵된 문서도 read로 카운트(read 비용 ↑).
- LBS 앱 페이드 스크롤은 cursor가 표준. 사용자가 임의 페이지 점프 안 함.
- iOS Domain UseCase 인터페이스 통일 — 모든 PaginatedQuery는 `cursor: PaginationCursor?` 파라미터 받음.

---

### D6 — 9-char Geohash viewport 쿼리

#### 옵션
- (A) 9-char geohash prefix 매칭 (정밀도 ~5m, 단순 `>=`/`<=` 쿼리로 가능).
- (B) S2 cell library (정밀도 cell level 가변, GeoFirestore 외부 의존).
- (C) lat/lng 직접 (Firestore 인덱스로 단일 정렬만 가능 — 이중 부등호 불가).

#### 결정: A 채택 (v1.0.0).

**근거**:
1. (C) 사용 불가 (Firestore 단일 부등호 제약).
2. (A) 9자리 = 5m 정밀도 → 도시 단위 viewport 충분. 단순 인덱스(`country` ASC + `geohash` ASC + `matchaScore` DESC).
3. (B) GeoFirestore 추가 의존 + 학습 곡선. v1.1.0+ 정밀도 부족 발생 시 도입 ADR-302-rev2.

#### 트리거 (v1.1.0 ADR-302-rev2)
- 사용자 zoom level이 거리 ≤ 100m가 자주 발생(P50) — 5m geohash로는 불충분.
- 또는 동일 geohash prefix에 매장 100건+ 밀집(코헝야 거리, 시부야).

---

### D7 — `stores.origin` 메타 도입 (po-lead 요청 반영)

#### 컨텍스트
- po-lead 메시지 (2026-05-04): designer-lead screens.md 검토 중 페르소나 2(로컬 도감러) "메모리 페이지(등급/원산지/색감)" Top 3 Need 충족용 필드 부재 발견.
- KR market-research §7 "사용자가 *진짜 우지/등급* 필터를 원함" 가설(KR 시장조사) 직결.

#### 결정: 채택. `stores.origin` nested map 추가 (schema.md §2.1).

**필드 구조**:
```
origin: {
  region: string?    enum ('uji','nishio','shizuoka','kagoshima','boseong','hadong','jeju','other') + free string
  country: string?   ISO-3166 alpha-2  // 매장 country와 다를 수 있음
  grade: string?     enum ('ceremonial','premium','standard','culinary')
  notes: string?     0-200 chars
}
```

**근거**:
1. 페르소나 2 Top 3 Need 직접 충족.
2. 매장 단위 SSOT — 모든 매장의 도감 카드 등록 시 동일 매장은 동일 origin 표시(사용자별 입력 불일치 차단).
3. v1.0.0 MVP는 **알려진 노포/브랜드만 시드 채움** — 모든 매장 강제 X. 큐레이터/공급원 정보 우위, 사용자 입력은 도감 카드 단위(`collections/items.{grade,originRegion}`)로 보완.

**trade-off**:
- `collections/items.{grade,originRegion}`(사용자 입력) vs `stores.origin.{grade,region}`(매장 SSOT) **이중 존재** → 의도된 분리. 매장 = 공급원 정보, 도감 카드 = 사용자 *그날 시음한 그 잔*의 메타. 사용자가 "오늘은 일반 등급으로 시음"한 카드는 매장 SSOT의 ceremonial과 다를 수 있음. 분석 시 두 필드 모두 활용.

**인덱스**:
- `origin.region` ASC + `matchaScore` DESC (전역 원산지 필터)
- `country` ASC + `origin.region` ASC + `matchaScore` DESC ("KR 카페 중 우지산 사용 매장")

#### 시드 정책
- v1.0.0: 알려진 KR/JP 노포만 큐레이터 입력. ~15-20% 매장이 origin 채워짐 추정.
- v1.0.x: 사용자 제보 → 큐레이터 검수 후 채움 흐름 (Phase 4).
- v1.1.0: 사용자 매장 등록 시 origin 선택 입력 UI.

---

## observability.md 정합 (PRD §4 측정 지표 산출)

본 스키마가 PRD §4 지표를 산출 가능함을 입증:

| PRD 지표 | observability 이벤트 | Firestore 정합 |
|---|---|---|
| **D1/D7 retention** | `auth_session_started`(is_first_session=true) → `session_start` | `users.cohortD0` ↔ user property `cohort_d0` SSOT (schema.md §1.4). |
| **도감 등록률 (전체 + travel_mode)** | `store_view` → `store_collection_added` 7d 윈도우 | `collections/items` doc create = `store_collection_added` 1:1 (schema.md §5.4). `country`/`viaReview`/`createdAt` 모두 정합. 인덱스 `storeId` ASC + `createdAt` DESC (collection group)로 7d 윈도우 join 효율. |
| **친구 1+ 비율** | `friend_added` + `friend_count` 스냅샷 | `users.stats.friendCount` SSOT, Functions가 `friendships` accepted 시 ±1 → user property `friend_count` 갱신 (schema.md §1.4). |
| **AdMob ARPU** | `ad_impression` 보조 + AdMob 콘솔 SSOT | Firestore 비저장. user_property `country`로 시장별 분리. |
| **평균 평점** | App Store Connect | Firestore 비저장. |
| **가드레일: 인터스티셜 빈도** | `ad_impression.placement_session_idx` | Firestore 비저장. |

도감 등록률 SQL 효율 검증: observability §5.2 참조. `views`/`adds` 양쪽이 `(uid, store_id, ts)` 키로 7d window join — 인덱스 `storeId+createdAt`이 `adds` 측 cursor 제공. **5줄 SQL로 산출 가능**(observability §0 원칙 6).

---

## iOS Domain Entity 매핑 정책

- **단일 진실**: schema.md = server SSOT. iOS `Domain/Entities/`는 본 스키마의 *projection*만 정의(타입 매핑).
- **이중 정의 금지**: 클라가 새 필드 추가 시 server-data 컨센스 필요. 클라 단독 모델 추가 차단.
- **DTO ↔ Entity 변환**: `Data/` 모듈의 DTO는 Firestore JSON과 1:1, Entity는 Domain 타입(`Date`, `URL`, enum 등). `Data/Mappers/` 책임.
- **Phase 3 정합 작업**: `ios-store`/`ios-social-collection`/`ios-map`이 Phase 3에서 Entity 작성 시 본 schema.md 인용 필수. 변경 시 server-data SendMessage 합의.

---

## 보안 규칙 영향 (server-auth ADR-303 의존)

본 스키마는 [security-rules.md](../server/security-rules.md) 패턴 P1~P6 / S1~S3을 100% 충족하는 형태로 설계됨. 신규/변경 사항:

| 컬렉션 | 패턴 | server-auth 작성 시 정합 항목 |
|---|---|---|
| `users` | P1 | `cohortD0` / `authMethod` / `homeCountry`(첫 30일 보정 외 immutable) / `stats.*` 변경 차단. |
| `stores` | P2 | `origin` 필드는 클라 read 가능, write Functions only. |
| `reviews` | P3 | `author{denorm}`/`store{denorm}` 클라가 작성 시 일관성 검증 필요(또는 Functions가 onCreate 시 덮어쓰기). |
| `wishlists/{uid}/items/{storeId}` | P4 | doc.id가 storeId임을 create 시 검증 (`request.resource.id == request.resource.data.storeId`). |
| `collections/{uid}/items/{itemId}` | P5 | 클라 직접 write 차단 — 콜러블 `addCollectionItem` 사용. fanout 정합. |
| `friendships/{uid}/edges/{friendUid}` | (신규) | read self만, write Functions only. ADR-303에 추가 필요. |
| `feed_events` | (신규) | read = `request.auth.uid in resource.data.audienceUids`, write Functions only. ADR-303에 추가 필요. |
| `likes/{reviewId}/users/{uid}` | P6 | 변경 없음. |

> **server-auth 액션**: ADR-302 도착 직후 firestore.rules에 `friendships`/`feed_events` 패턴 추가 + 위 정합 검증.

---

## Cloud Functions fanout 함수 (server-functions 의존)

본 스키마가 요구하는 Functions(`server-functions` Phase 2 작성):

| 트리거 | 책임 |
|---|---|
| `onCreateUser` (Auth 트리거) | `users/{uid}` doc 생성 + `cohortD0` set + `homeCountry` 디바이스 locale로 초기화. |
| `onUpdateUser.displayName/photoURL` | 디노멀 fanout: `reviews`/`feed_events`/`friendships/*/edges/{me}`. |
| `onUpdateStore.{name,primaryPhoto,origin}` | 디노멀 fanout: `reviews`/`wishlists/*/items/{placeId}`/`collections/*/items where storeId==X`/`feed_events`. |
| `addCollectionItem` (callable) | `collections/items` create + `users.stats.collectionCount` ±1 + `feed_events` create + `analytics_events` audit. |
| `requestFriend`/`acceptFriend`/`removeFriend` (callable) | 양방향 doc 정합 + `users.stats.friendCount` ±1 + `feed_events` create. |
| `submitReview` (callable) | `reviews` create + `stores.{reviewCount,ratingAvg,ratingHistogram}` 갱신 + `users.stats.reviewCount` ±1 + (옵션) viaReview=true 시 `addCollectionItem` 자동 fanout + `feed_events`. |
| `cleanupFeedEvents` (scheduled) | 90일 retention. |
| `recomputeStoreAggregates` (scheduled) | 매시 정각, 디노멀 drift 보정. |

> **server-functions 액션**: 본 표를 ADR/api-contract.md 기반으로 함수 시그니처 + 입출력 + 에러 코드 정의.

---

## v1.0.0 비범위 (별도 ADR로 이연)

| 항목 | 이연 위치 | 이유 |
|---|---|---|
| 사용자 매장 등록(`mm_` prefix) | v1.1.0 / ADR-302-rev1 | PRD §9 비범위. |
| `usernames/{handle}` lookup | v1.1.0 / SCH-2 | 친구 추가 method=`username`은 v1.1.0+. |
| GeoFirestore / S2 cell | v1.1.0+ / ADR-302-rev2 | 트리거 발화 시 (D6 결정 근거 참조). |
| 글로벌 read replica | v1.2.0 / ADR-304 (ADR-301 § Supabase 트리거 정합) | US/EU MAU 10K+ 또는 P95 800ms+. |
| 매장 viewport 쿼리 클라 캐시 (NSCache 30s) | Phase 3 / ios-map | cost-projection §5 절감 레버 #1. |
| BigQuery export 활성화 (analytics_events deprecate 검토) | Phase 3 / OBS-2 | 비용 영향 추정 후. |

---

## 결과 / 영향

- **iOS**: Phase 3에 Domain Entity가 본 스키마 매핑 작성. `ios-store`/`ios-social-collection`/`ios-map`이 server-data 합의 후 시작.
- **server-auth**: 본 ADR 사인오프 직후 `firestore.rules` 갱신 (`friendships`, `feed_events` 패턴 추가). storage.rules는 변경 없음.
- **server-functions**: `seedStores.ts` + 위 § Functions 표 함수 작성. api-contract.md 정합 갱신.
- **server-lead**: cost-projection.md §3 read 가정 검증 — 디노멀 적용 후 1 매장 상세 진입 reads = 11 → **2 reads로 감소** (1 store list query + 1 store detail = 매장 doc 1 + reviews 페이지 1, author/store 모두 디노멀). 시나리오 B 월 비용 재추정 가능 (절감 효과).

---

## Open Items (Phase 3+ 이연)

[schema.md §12 Open Items](../server/schema.md#12-open-items) SCH-1 ~ SCH-6 참조.

추가:
- **OPEN-302-1**: cost-projection.md §3 reads 가정을 디노멀 절감으로 재계산 (서버 리드 책임).
- **OPEN-302-2**: `stores.origin` 시드 큐레이션 가이드라인 작성 (po-growth + 디자이너).

---

## Changelog

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-04 | 초안 (D1~D7 결정 + observability/security/functions 정합) — `stores.origin` po-lead 요청 반영 | server-data (server-lead + po-lead 사인오프 대기) |
| 2026-05-04 | **server-lead 사인오프 완료**. observability 정합 4건(users.friend_count / stores.country / reviews.{rating,body,photos} 디노멀 / collections.itemId 카드 매핑) 모두 통과. OPEN-302-1 해결: cost-projection.md v3에 디노멀 절감 반영(시나리오 B 월 $16.55 → $13.79, 17% 절감). | server-lead |
