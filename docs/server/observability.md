# Observability — 이벤트 스키마 + 지표 매핑

- **작성**: `server-lead` · 2026-05-04
- **상태**: Phase 1 산출물 (po-lead 사인오프 대기)
- **단일 진실 원천(SSOT)**: 본 문서의 이벤트 스키마는 [ADR-PROD-001 § 지표 정의](../product/decisions/ADR-PROD-001-hypothesis-framework.md#지표-정의-prd-§4와-일치-조작-가능-정의)의 공식 수식을 1:1로 충족하기 위해 작성된다. 두 문서가 충돌하면 ADR-PROD-001이 우선이며, 본 문서를 보강한다.

> **목적**: PRD §4의 측정 지표(D1/D7 retention, 도감 등록률, AdMob ARPU, 친구 1+, 평균 평점)를 *실측 가능*하게 만든다. 모든 이벤트는 Firebase Analytics(자동 수집 일부 + 우리가 정의한 커스텀)와 BigQuery export(Phase 3 활성화)를 단일 분석 파이프라인으로 사용한다.

## 0. 원칙

1. **단일 진실 원천**: 사용자/세션/이벤트의 시간 기준은 **클라 wall-clock**이 아닌 **서버 수신 시각(`event_server_ts`)**. 클라 시계 조작 방지.
2. **이벤트 명명**: `snake_case`. 도메인 prefix(`store_`, `review_`, `auth_`, `wishlist_`, `collection_`, `friend_`, `ad_`).
3. **PII 제로**: 이벤트 파라미터에 이메일/전화/실명 절대 금지. uid는 Firebase Auth 발급 hash.
4. **타입 강제**: 파라미터는 정의된 타입만(string/int/double/bool). 새 파라미터 추가 시 본 문서 갱신 + server-lead 리뷰.
5. **유저 프로퍼티**(`country`, `home_country`, `locale`, `app_version`, `travel_mode`)는 user-scoped로 한 번 set, 세션 변경 시 갱신.
6. **이벤트 설계는 "분석 SQL이 5줄 안에 짤 수 있는가"가 통과 기준**. 두 단계 join이 필요하면 이벤트 분리/병합 재검토.

## 1. 글로벌 유저 프로퍼티 (User Properties)

Firebase Analytics `setUserProperty`로 한 번 등록 + 변경 시 갱신.

| 키 | 타입 | 설명 | 갱신 시점 |
|---|---|---|---|
| `country` | string ISO-3166 alpha-2 | 사용자의 *현재* 위치 국가 (CLLocation reverse geocode) | 앱 시작 + 위치 권한 허용 직후 |
| `home_country` | string ISO-3166 alpha-2 | 사용자의 *기본* 국가 (가입 시 디바이스 locale 또는 첫 30일 다수 위치) | 가입 시 1회 + 첫 30일 보정 |
| `locale` | string BCP-47 (ko-KR) | 앱 표시 언어 | 앱 시작 시 |
| `app_version` | string | CFBundleShortVersionString | 앱 시작 시 |
| `build_number` | string | CFBundleVersion (YYMMDD_HHMM) | 앱 시작 시 |
| `travel_mode` | bool | `country != home_country` (§2 여행 모드 판별 참조) | 앱 시작 + 위치 갱신 시 |
| `friend_count` | int | 현재 친구 수 (월간 첫 세션 스냅샷용) | 친구 수 변경 시 |
| `auth_method` | string enum: `apple`, `passkey` | 가입 방식 | 가입 시 1회 |
| `cohort_d0` | string YYYY-MM-DD KST | 첫 `auth_session_started` 일자 (코호트 키) | 가입 시 1회, 불변 |

> **중요**: `cohort_d0` user property가 D1/D7 retention 코호트의 **분모 SSOT**다. ADR-PROD-001 § D1/D7 정의의 "코호트 일자 D0"가 본 필드를 인용한다.

## 2. 여행 모드(`travel_mode`) 판별 — 정책

ADR-PROD-001의 H1 가설(travel_mode=true 도감 등록률 ≥ 50%)이 본 필드의 정확도에 직접 의존. 잘못된 판별은 H1 결과를 왜곡한다.

### 2.1 판별 알고리즘 (클라이언트 1차 + 서버 백업)

```
function computeTravelMode(user) -> bool:
  current = currentCountry()        // CLLocationManager + reverseGeocode (iOS)
  home    = user.home_country       // 가입 시 device locale 기반 + 30일 보정
  if current == nil OR home == nil: return false           // 정보 부족 시 false 디폴트
  return current != home
```

- **클라이언트가 1차 판별**: iOS `CLLocationManager`로 좌표 → `CLGeocoder.reverseGeocodeLocation`로 ISO 국가 코드. 사용자가 위치 권한 거부 시 `country = nil` → `travel_mode=false` 디폴트.
- **서버 IP geolocation 백업**: 콜러블 함수 `resolveCountry`가 요청 IP를 GCP `cloud.google.com/_/geolocate` 또는 MaxMind GeoLite2 조회. **다음 조건에서만 활성**:
  1. 클라가 위치 권한 거부 또는 좌표 측위 실패 60초 이상 지속
  2. 클라 보고 country와 IP geo country가 4시간 이상 일치하지 않음 → 클라값을 **유지**하되 `country_source=conflict` 부속 필드로 기록(분석 단계에서 노이즈 필터)
- **서버 IP geo는 분석 보정 보조 신호**. 사용자 경험에 영향 주는 결정(예: 도감 잠금 해제)은 클라 값 사용.

### 2.2 `home_country` 결정 로직

가입 시점:
1. 가입 직후 device locale region (`Locale.current.regionCode`) → 첫 `home_country`.
2. 첫 30일 동안 일별 첫 좌표의 국가가 70% 이상 단일이면 그 국가로 **보정 1회만**. 이후 영구 동결.
3. 명시적 변경 UI는 v1.1.0에서 도입(설정 > 기본 국가 변경). MVP에선 자동 결정만.

### 2.3 결론

> **여행 모드 판별 = 클라이언트 우선 + 서버 IP geo 백업.** 서버 백업은 분석 데이터 품질용으로만, UX 결정에는 사용 안 함.

## 3. 이벤트 카탈로그

각 이벤트의 컬럼:
- **이벤트명**: `snake_case`.
- **트리거**: 어디서/언제 발화.
- **필수 파라미터**: 누락 시 invalid.
- **선택 파라미터**.
- **수식 매핑**: ADR-PROD-001 § 지표 정의의 어느 분자/분모에 사용되는지.

### 3.1 `session_start` (자동 수집)

- **출처**: Firebase Analytics 자동 수집(`session_start`). 별도 코드 불필요. Firebase 기본 세션 정의(앱 포그라운드 + 30분 무활동 시 신규 세션).
- **유저 프로퍼티 자동 첨부**: `country`, `home_country`, `locale`, `app_version`, `travel_mode`, `friend_count`(스냅샷).
- **수식 매핑**:
  - **D1/D7 retention 분자** (ADR-PROD-001 § D1/D7): `[D0+24h, D0+48h)`, `[D0+7d, D0+8d)` 윈도우 내 본 이벤트 발생 = 잔존.
  - **MAU 분모** (AdMob ARPU): 그 달 1회 이상 본 이벤트 발생한 고유 user_id.
  - **친구 1+ 비율 분모**: MAU와 동일.

### 3.2 `auth_session_started` (커스텀)

- **출처**: 클라 `FirebaseAuth` 로그인 성공 직후 1회 (애플 또는 passkey 콜백 onSuccess).
- **필수 파라미터**:
  - `auth_method`: `apple` | `passkey`
  - `is_first_session`: bool (Firestore `users/{uid}.createdAt`이 본 이벤트 발생일과 동일하면 true)
- **수식 매핑**:
  - **코호트 D0**: 사용자의 `is_first_session=true`인 첫 본 이벤트의 KST 일자 = `cohort_d0` user property 값. ADR-PROD-001 § D1/D7 정의의 "첫 `auth_session_started`"가 본 이벤트.
  - **D1/D7 분모**: `cohort_d0` 기준 코호트 사용자 집합.

### 3.3 `store_view` (커스텀)

- **출처**: 매장 상세 화면이 *완전히 표시된 직후* (스크린뷰가 아닌 명시적 dwell ≥ 1.5초로 봇/우발 클릭 제외).
- **필수 파라미터**:
  - `store_id`: string (Firestore `stores/{id}`)
  - `country`: string (매장 국가, 매장 doc에서 복제 — 클라 위치와 다를 수 있음)
  - `entry_source`: enum: `map_pin`, `map_cluster`, `search`, `wishlist`, `feed`, `collection`, `deeplink`, `share`
  - `distance_m`: int (사용자 현재 위치 ↔ 매장 위치 미터, 측위 실패 시 -1)
- **선택 파라미터**:
  - `dwell_ms`: int (페이지 이탈 시점에 보강 — Phase 2에서 dwell-time 측정 도입 시)
- **수식 매핑**:
  - **도감 등록률 분모** (ADR-PROD-001 § 도감 등록률): 고유 (user_id, store_id) 쌍의 분모. user_id는 자동 첨부.

### 3.4 `store_collection_added` (커스텀)

- **출처**: 도감 등록 액션 성공 직후(서버 Functions가 fanout 완료 ack).
- **필수 파라미터**:
  - `store_id`: string
  - `via_review`: bool (리뷰 작성 + 도감 자동 추가인 경우 true, 명시적 도감 버튼이면 false)
  - `country`: string (매장 국가)
  - `time_since_view_min`: int (해당 매장의 가장 최근 `store_view` 이후 분 단위, 7일 윈도우 매칭에 사용)
- **수식 매핑**:
  - **도감 등록률 분자**: 같은 (user_id, store_id) 쌍이 `store_view` 이후 7일 이내 본 이벤트 1회 이상 발생. `time_since_view_min ≤ 10080` (7d×24h×60m) 필터.
  - **H1 가설(travel_mode=true 도감 등록률 ≥ 50%)**: user property `travel_mode=true`로 세그먼트.

### 3.5 `friend_added` (커스텀)

- **출처**: 친구 추가 액션 성공 직후 (요청자 측에서 발화, 수락된 시점에 양쪽 모두 1건 발화).
- **필수 파라미터**:
  - `friend_count_after`: int (내 친구 수, after)
  - `add_method`: enum: `qr`, `username`, `share_link`, `address_book` (후자 셋은 v1.1.0+)
- **수식 매핑**:
  - **친구 1+ 비율 분자 보조**: 본 이벤트로 `friend_count` user property 갱신 트리거.
  - **H2 가설(친구 ≥ 1 D7 ≥ 0인 D7 × 2)**: user property `friend_count` 첫 세션 스냅샷으로 분리.

### 3.6 `friend_count` 스냅샷 (user property)

- **출처**: 매월 첫 `session_start` 시 클라가 Firestore `users/{uid}.friendCount` 읽어 user property 갱신.
- **수식 매핑**:
  - **친구 1+ 비율 분자** (ADR-PROD-001): 그 달의 첫 `session_start` 시점 기준 `friend_count ≥ 1` 인 사용자.

### 3.7 `ad_impression` (커스텀)

- **출처**: AdMob 광고가 *실제로 노출*된 시점 (`GADBannerViewDelegate.bannerViewDidRecordImpression`, 인터스티셜은 `presentFromRootViewController` 직후).
- **필수 파라미터**:
  - `slot_type`: enum: `banner_map`, `interstitial_store_detail`, `rewarded_collection_unlock`
  - `ad_unit_id`: string (AdMob 단위 ID)
  - `format`: enum: `banner`, `interstitial`, `rewarded`
  - `placement_session_idx`: int (현재 세션에서 본 슬롯의 N번째 노출 — 가드레일 검증)
- **수식 매핑**:
  - **AdMob ARPU 보조**: 본 이벤트의 슬롯별 카운트 × eCPM 추정으로 *검증용 보조*. 공식 ARPU는 AdMob 콘솔 결산이 SSOT (ADR-PROD-001 § AdMob ARPU).
  - **가드레일** (PRD §4): `placement_session_idx`가 인터스티셜 슬롯에서 세션당 ≤ 1을 위반하면 알림.

### 3.8 `ad_click` / `ad_reward` (커스텀)

- 광고 클릭 / 보상형 완료 발화. 슬롯 효율 분석용. PRD §4 직접 매핑은 없지만 단가 진단 + monetization.md 후속.

### 3.9 `att_prompt` (커스텀)

- **출처**: ATT 권한 다이얼로그 결과 직후 1회.
- **필수 파라미터**:
  - `result`: enum: `granted`, `denied`, `restricted`, `not_determined`
  - `prompt_trigger_seconds_since_first_open`: int (PRD §6 "첫 사용 60초 후" 규칙 검증)
- **수식 매핑**:
  - **PRD §4 가드레일**: ATT 동의율 ≥ 35% (`granted` / total prompts).

### 3.10 성장 루프 이벤트 (5종) — `growth-loops.md` 정합

> [docs/product/growth-loops.md](../product/growth-loops.md)의 5개 루프를 측정하기 위한 이벤트. po-lead 사인오프 2026-05-04. 본 5종은 **PRD §4 + H1~H4 가설 + H5/H10 신규 가설** 검증의 핵심 신호.

#### 3.10.1 `card_share_initiated` (커스텀, 루프1 P0)

- **출처**: 사용자가 매장 카드 공유 액션을 *시작*한 시점 (iOS `UIActivityViewController` present 직전). 공유 *완료* 시점이 아닌 *시도* — 공유 의도 신호 측정이 목적.
- **필수 파라미터**:
  - `card_id`: string (Firestore `cards/{id}` 또는 `stores/{storeId}/cards/{cardId}` 경로)
  - `store_id`: string (해당 카드의 매장)
  - `channel`: enum: `instagram`, `kakao`, `imessage`, `copy`, `other`
  - `country`: string (사용자 현재 country)
- **선택 파라미터**:
  - `share_completed`: bool (iOS `UIActivityViewController.completionHandler`로 후속 갱신, default null)
- **수식 매핑**:
  - **루프1 — 카드 공유율 (≥ 25%)**: 분모 = 카드 생성 수 (= `store_collection_added` 카운트), 분자 = 본 이벤트 고유 (user_id, card_id) 쌍.
  - **H5 가설(카드 공유율 25% / 클릭→가입 8% / 신규 중 공유 30%)** 검증의 분자.

#### 3.10.2 `wishlist_match_created` (커스텀, 루프2 P0)

- **출처**: Cloud Function이 두 사용자의 위시리스트 교집합을 발견하여 *마커 doc을 생성한 시점* (서버 발화 — 클라가 아닌 Functions). 푸시 알림은 본 이벤트와 별개.
- **필수 파라미터**:
  - `user_id`: string (분석 대상 사용자, Functions가 user_pseudo_id를 매핑)
  - `friend_uid`: string (해시된 친구 식별자 — 분석용 hash, PII 0)
  - `store_id`: string
  - `country`: string (매장 국가)
- **수식 매핑**:
  - **루프2 — 위시 교집합 매장 평균 ≥ 3개 (친구≥1 사용자)**: 분모 = `friend_count ≥ 1` 사용자, 분자 = 본 이벤트 고유 (user_id, store_id) 쌍 카운트 / 사용자.
  - **H2 가설(친구≥1 D7 ≥ 비친구 D7 × 2)** 보강: 본 이벤트 발생 사용자의 D7을 별도 segment로 추적.

#### 3.10.3 `review_submitted` (커스텀, 루프3 P0)

> § 3.10의 보조 이벤트 `review_submit`을 정식 이벤트로 격상. 향후 `review_submit`은 **deprecated** — 본 이벤트가 SSOT.

- **출처**: 리뷰 작성 액션 성공 직후 (Functions `submitReview` ack). 클라 + Functions 양쪽 동일 이벤트지만 SSOT는 Functions 발화.
- **필수 파라미터**:
  - `review_id`: string (Firestore `reviews/{id}`)
  - `store_id`: string
  - `rating`: int (1~5)
  - `has_photo`: bool (1장 이상 첨부 여부)
  - `body_len`: int (글 본문 글자 수)
  - `country`: string (매장 국가)
- **수식 매핑**:
  - **루프3 — 사용자 평균 리뷰 수 ≥ 1.2**: 분모 = 사용자(고유 user_id), 분자 = 본 이벤트 카운트.
  - **모더레이션 가드레일**: `body_len < 5` OR `rating in {1,5}` AND `has_photo == false` 케이스를 자동 review queue에 (Functions 처리, 본 문서 측정 대상은 아님).

#### 3.10.4 `rewarded_ad_completed` (커스텀, 루프4 P1)

> § 3.8 `ad_reward`를 본 이름으로 **정식 격상** (이름 표준화). `ad_reward`는 deprecated 예정.

- **출처**: AdMob 보상형 광고 시청 *완료* 콜백 (`GADRewardedAd userDidEarnReward`). 시청 *시작*은 § 3.7 `ad_impression`에서 측정.
- **필수 파라미터**:
  - `ad_unit_id`: string (AdMob 단위 ID)
  - `card_id`: string (잠금 해제 대상 카드 ID, 도감 한도 해제 컨텍스트)
  - `reward_type`: enum: `card_unlock`, `collection_slot`, `other`
- **수식 매핑**:
  - **루프4 — 보상형 광고 시청 / DAU ≥ 0.15**: 분모 = 일 DAU(=`session_start` 1회+ user_id), 분자 = 본 이벤트 고유 user_id (일별).
  - **루프4 — 광고 시청자 D7 retention ≥ 22% (시청 안한 사용자 대비 +5pp)**: 본 이벤트 발생 코호트 vs 비발생 코호트 D7 retention 분리.
  - **H10 가설(보상형 시청자 D7 +5pp)** 검증의 핵심 분자.

#### 3.10.5 `city_collection_progress_viewed` (커스텀, 루프5 P1)

- **출처**: 미니 세계지도 또는 도시 도감 진척도 카드가 화면에 *완전히 표시되고 dwell ≥ 1.0초* (스크롤 fly-by 제외).
- **필수 파라미터**:
  - `city`: string (ISO city code 또는 정규화된 도시명, e.g. "tokyo", "seoul")
  - `count`: int (해당 도시에서 사용자가 수집한 카드 수)
  - `total_in_city`: int (해당 도시의 우리가 보유한 매장 수 = 분모)
  - `view_source`: enum: `mini_world_map`, `city_card`, `wishlist`
- **수식 매핑**:
  - **루프5 — 미니 세계지도 클릭률 ≥ 35%**: 분모 = 본 이벤트 `view_source == 'mini_world_map'` 카운트, 분자 = 본 이벤트 후 30초 이내 `store_view` 발생 케이스 (세션 내 매칭).
  - **루프5 — 평균 사용자 도시 카드 수 ≥ 1.8**: 본 이벤트의 `count` 평균(고유 user_id × city 쌍).
  - **H1 가설(travel_mode 도감 등록률 ≥ 50%)** 보강: `travel_mode=true` 사용자 세그먼트의 본 이벤트 빈도.

### 3.11 보조 이벤트 (분석 깊이용, PRD §4 직접 매핑 없음)

| 이벤트 | 트리거 | 용도 |
|---|---|---|
| `wishlist_toggle` | 위시리스트 ±1 | 의도 신호 |
| `search_submit` | 검색 실행 | 검색 의존도 |
| `app_open_universal_link` | 딥링크 진입 | 공유 루프 (§ 3.10.1과 매칭하여 클릭→가입 전환 측정) |
| `permission_request` | 위치/푸시 권한 결과 | 가드레일 |
| `crash` | Crashlytics 자동 (별도 파이프라인) | 크래시-프리 세션 ≥ 99.5% (PRD §4 가드레일) |
| ~~`review_submit`~~ | deprecated → § 3.10.3 `review_submitted`로 통합 | — |
| ~~`ad_reward`~~ | deprecated → § 3.10.4 `rewarded_ad_completed`로 통합 | — |

## 4. PRD §4 → 이벤트 1:1 매핑 매트릭스

### 4.1 PRD §4 지표 (출시 후 30일 목표)

| PRD §4 지표 | ADR-PROD-001 공식 정의 인용 | 분모 이벤트 | 분자 이벤트 | 세그먼트 user prop |
|---|---|---|---|---|
| D1 retention | § D1/D7 Retention | `auth_session_started`(is_first_session=true) | `session_start` in `[D0+24h, D0+48h)` | `country`, `locale`, `travel_mode` |
| D7 retention | § D1/D7 Retention | 동상 | `session_start` in `[D0+7d, D0+8d)` | 동상 |
| 도감 등록률 (전체) | § 도감 등록률 | `store_view` 고유 (uid, store_id) | `store_collection_added` 7d 윈도우 매칭 | — |
| 도감 등록률 (travel_mode) | § 도감 등록률 + H1 | 동상 + `travel_mode=true` | 동상 + `travel_mode=true` | `travel_mode` |
| 친구 ≥ 1 비율 | § 친구 1+ 사용자 비율 | 그 달 MAU = `session_start` 1회+ user_id | 그 달 첫 `session_start` 시 `friend_count ≥ 1` | — |
| AdMob ARPU | § AdMob ARPU | MAU(위와 동일) | AdMob 콘솔 결산 (SSOT, 이벤트 아님) | `country` (시장별 가드레일) |
| 평균 평점 | § 평균 평점 | App Store Connect | App Store Connect | `country` |
| **가드레일**: 크래시-프리 세션 | PRD §4 | 세션 수 | 크래시 발생 세션 | — |
| **가드레일**: ATT 동의율 | PRD §4 | `att_prompt` 전체 | `att_prompt.result == granted` | `country` |
| **가드레일**: 인터스티셜 빈도 | PRD §4 | 세션 수 | `ad_impression.slot_type == interstitial_*` & `placement_session_idx > 1` | — |

### 4.2 성장 루프 메트릭 → 이벤트 매핑 (growth-loops.md 정합)

| 루프 / 메트릭 | 목표 (D+30) | 분모 이벤트 | 분자 이벤트 | 매핑 가설 |
|---|---|---|---|---|
| 루프1 — 카드 공유율 | ≥ 25% | `store_collection_added` (= 카드 생성) | `card_share_initiated` 고유 (user_id, card_id) | H5 |
| 루프1 — 외부 클릭→가입 전환 | ≥ 8% | `app_open_universal_link` 카운트 (utm_source=card_share) | 신규 `auth_session_started`(is_first_session=true) 후속 매칭 | H5 |
| 루프1 — 신규 가입 중 공유 비중 | ≥ 30% | 신규 `auth_session_started` 전체 | 위 분자 (utm_source=card_share) | H5 |
| 루프2 — 위시 교집합 매장 평균 (친구≥1) | ≥ 3개 | `friend_count ≥ 1` 사용자 | `wishlist_match_created` 고유 (user_id, store_id) 카운트 / 사용자 | H2 보강 |
| 루프2 — 그룹 컬렉션 활성화율 | ≥ 40% | 그룹 도감 생성 사용자 | 30일 내 그룹 도감 카드 추가 1회+ 사용자 | H2 보강 |
| 루프3 — 사용자 평균 리뷰 수 | ≥ 1.2 | 고유 user_id (활성 사용자) | `review_submitted` 카운트 | H11 후보 |
| 루프4 — 보상형 시청 / DAU | ≥ 0.15 | DAU (`session_start` 1회+) | `rewarded_ad_completed` 고유 user_id (일별) | H10 |
| 루프4 — 시청자 D7 retention | ≥ 22% (+5pp) | `rewarded_ad_completed` 발생 코호트 | 코호트 D7 `session_start` | H10 |
| 루프5 — 미니 세계지도 클릭률 | ≥ 35% | `city_collection_progress_viewed` (view_source=mini_world_map) | 본 이벤트 후 30초 이내 `store_view` | H1 보강 |
| 루프5 — 평균 사용자 도시 카드 수 | ≥ 1.8 | 활성 사용자 | `city_collection_progress_viewed.count` 평균 | H1 보강 |

### 4.3 가설 → 이벤트 매핑 (PRD §5 + growth-loops.md § 가설 매핑)

| 가설 ID | 가설 | 검증 이벤트 |
|---|---|---|
| H1 | 여행 + 도감 = 강한 수집욕 (travel_mode 도감 50%) | `store_view` × `store_collection_added` × user_prop `travel_mode` + 보강 `city_collection_progress_viewed` |
| H2 | 친구 피드 = 리텐션 드라이버 (friend≥1 D7 × 2) | `session_start` 코호트 × user_prop `friend_count` 첫 세션 스냅샷 + 보강 `wishlist_match_created` |
| H3 | AdMob ARPU 글로벌 ≥ $0.05/MAU | MAU + AdMob 콘솔 결산 |
| H4 | KR 비치헤드 우위 (KR D7 ≥ JP D7 + 5pp) | `session_start` × user_prop `country` |
| **H4'** (신규, ADR-PROD-003) | US 출시 D+30 코호트 D7 ≥ 17% & ARPU ≥ $0.18/MAU | `auth_session_started`(is_first_session=true, country=US, cohort_d0 ∈ [US 출시일, +7d)) + AdMob 콘솔 country=US 분리 |
| **H5** (신규, P0) | 카드 공유 루프 (공유율 25% / 클릭→가입 8% / 신규 중 공유 30%) | `card_share_initiated` + `app_open_universal_link.utm_source=card_share` + `auth_session_started` 매칭 |
| **H6** (신규, ADR-PROD-003 GTM) | US ASA CAC ≤ 업계 벤치 × 0.8 | Apple Search Ads 콘솔 CAC SSOT + Firebase `app_install_referrer.asa_keyword_id` 매칭 |
| **H10** (신규, P1) | 보상형 시청자 D7 +5pp | `rewarded_ad_completed` 코호트 vs 비발생 코호트 D7 |
| H11 (후보) | 베스트 카드 SEO 자연 트래픽 ≥ 30% 신규 가입 | `review_submitted` × `app_open_universal_link.utm_source` |

#### H4' 정의 (US 출시 D+30 코호트)

- **분모**: `auth_session_started` events with `is_first_session=true` AND user_property `country='US'` AND `cohort_d0` ∈ [US 출시일, US 출시일 + 7d).
  - US 출시일 = ADR-PROD-003에 따라 KR/JP D0의 D+30. PRD §11에 절대 일자 기록.
- **분자 (D7)**: 위 분모 사용자 중 `[cohort_d0 + 7d, cohort_d0 + 8d)` 윈도우에 `session_start` 1회+.
- **분자 (ARPU)**: AdMob 콘솔 country=US 매출 / 그 달 country=US MAU.
- **목표**: D7 ≥ 17% AND ARPU ≥ $0.18/MAU.
- **세그먼트**: 추가로 `travel_mode` 분리 권장 (US 자국 사용자만 vs 여행자).

#### H6 정의 (US ASA CAC)

- **분모**: Apple Search Ads 콘솔 US 캠페인 광고비(USD/월).
- **분자**: 같은 기간 ASA *attributed installs* SSOT (ASA 콘솔).
- **CAC** = 분모 / 분자.
- **업계 벤치 × 0.8** = po-growth가 ADR-PROD-003에 정량 명시 (벤치 출처 + 0.8 배수 근거 인용).
- **Firebase 측 검증 보조**: `app_install_referrer` 이벤트(Phase 2-3 ios-auth-monetize 추가) — `asa_keyword_id` 또는 `attribution_token` 파라미터로 ASA 트래픽 분리. SSOT는 ASA 콘솔, Firebase는 검증 보조.
- **신규 Open Item**: OBS-7 — `app_install_referrer` 이벤트 정의 + ASA 토큰 파라미터 (server-functions + ios-auth-monetize Phase 2 합의).

### 4.4 SSOT 정리 (단일 진실 원천)

- **모든 D1/D7/MAU 정의**: ADR-PROD-001 § 지표 정의.
- **AdMob ARPU 분자**: AdMob 콘솔 결산 (이벤트 아님).
- **App Store 평점**: App Store Connect (이벤트 아님).
- **나머지 지표**: 본 문서의 이벤트가 SSOT.
- **deprecated 이벤트**: `review_submit` → `review_submitted`, `ad_reward` → `rewarded_ad_completed`. 이행 시점 = Phase 2 클라 통합 시 단일 컷오버(dual-write 없음, 클라 첫 빌드부터 신 이벤트만).

## 5. BigQuery 분석 SQL 스니펫 (검증용)

> Phase 3에 BigQuery export 활성화 후 실측에 사용. 스키마는 GA4 export 표준 + 본 문서 커스텀 파라미터.

### 5.1 D7 retention by country × travel_mode

```sql
-- pseudo-SQL (ga4 export)
WITH cohort AS (
  SELECT user_pseudo_id,
         DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Seoul') AS d0,
         (SELECT value.string_value FROM UNNEST(user_properties) WHERE key='country') AS country,
         (SELECT value.string_value FROM UNNEST(user_properties) WHERE key='travel_mode') AS travel_mode
  FROM `matchamapapp.analytics_*.events_*`
  WHERE event_name = 'auth_session_started'
    AND (SELECT value.int_value FROM UNNEST(event_params) WHERE key='is_first_session') = 1
),
returned AS (
  SELECT DISTINCT s.user_pseudo_id, c.d0, c.country, c.travel_mode
  FROM cohort c
  JOIN `matchamapapp.analytics_*.events_*` s
    ON s.user_pseudo_id = c.user_pseudo_id
   AND s.event_name = 'session_start'
   AND DATE(TIMESTAMP_MICROS(s.event_timestamp), 'Asia/Seoul')
       BETWEEN DATE_ADD(c.d0, INTERVAL 7 DAY) AND DATE_ADD(c.d0, INTERVAL 7 DAY)
)
SELECT country, travel_mode,
       COUNT(DISTINCT r.user_pseudo_id) / COUNT(DISTINCT c.user_pseudo_id) AS d7_retention
FROM cohort c LEFT JOIN returned r USING(user_pseudo_id, d0, country, travel_mode)
GROUP BY country, travel_mode;
```

### 5.2 도감 등록률 (travel_mode 세그먼트, H1 검증)

```sql
WITH views AS (
  SELECT user_pseudo_id,
         (SELECT value.string_value FROM UNNEST(event_params) WHERE key='store_id') AS store_id,
         TIMESTAMP_MICROS(event_timestamp) AS view_ts,
         (SELECT value.string_value FROM UNNEST(user_properties) WHERE key='travel_mode') AS travel_mode
  FROM `matchamapapp.analytics_*.events_*`
  WHERE event_name = 'store_view'
),
adds AS (
  SELECT user_pseudo_id,
         (SELECT value.string_value FROM UNNEST(event_params) WHERE key='store_id') AS store_id,
         TIMESTAMP_MICROS(event_timestamp) AS add_ts
  FROM `matchamapapp.analytics_*.events_*`
  WHERE event_name = 'store_collection_added'
)
SELECT v.travel_mode,
       COUNT(DISTINCT IF(a.add_ts BETWEEN v.view_ts AND TIMESTAMP_ADD(v.view_ts, INTERVAL 7 DAY),
                         CONCAT(v.user_pseudo_id, '|', v.store_id), NULL)) AS numerator,
       COUNT(DISTINCT CONCAT(v.user_pseudo_id, '|', v.store_id)) AS denominator,
       SAFE_DIVIDE(numerator, denominator) AS collection_add_rate
FROM views v
LEFT JOIN adds a ON v.user_pseudo_id = a.user_pseudo_id AND v.store_id = a.store_id
GROUP BY v.travel_mode;
```

### 5.3 카드 공유율 (루프1, H5 검증)

```sql
WITH cards_created AS (
  SELECT user_pseudo_id,
         (SELECT value.string_value FROM UNNEST(event_params) WHERE key='store_id') AS store_id
  FROM `matchamapapp.analytics_*.events_*`
  WHERE event_name = 'store_collection_added'
),
cards_shared AS (
  SELECT user_pseudo_id,
         (SELECT value.string_value FROM UNNEST(event_params) WHERE key='card_id') AS card_id,
         (SELECT value.string_value FROM UNNEST(event_params) WHERE key='channel') AS channel
  FROM `matchamapapp.analytics_*.events_*`
  WHERE event_name = 'card_share_initiated'
)
SELECT COUNT(DISTINCT s.user_pseudo_id || '|' || s.card_id) AS shared,
       COUNT(DISTINCT c.user_pseudo_id || '|' || c.store_id) AS created,
       SAFE_DIVIDE(shared, created) AS share_rate
FROM cards_created c
LEFT JOIN cards_shared s ON s.user_pseudo_id = c.user_pseudo_id;
-- 목표 ≥ 0.25
```

### 5.4 보상형 광고 시청자 D7 retention 비교 (루프4, H10 검증)

```sql
WITH cohort AS (
  SELECT user_pseudo_id,
         DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Seoul') AS d0
  FROM `matchamapapp.analytics_*.events_*`
  WHERE event_name = 'auth_session_started'
    AND (SELECT value.int_value FROM UNNEST(event_params) WHERE key='is_first_session') = 1
),
watched_rewarded AS (
  SELECT DISTINCT user_pseudo_id, DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Seoul') AS watch_d
  FROM `matchamapapp.analytics_*.events_*`
  WHERE event_name = 'rewarded_ad_completed'
),
returned_d7 AS (
  SELECT DISTINCT s.user_pseudo_id, c.d0
  FROM cohort c
  JOIN `matchamapapp.analytics_*.events_*` s
    ON s.user_pseudo_id = c.user_pseudo_id
   AND s.event_name = 'session_start'
   AND DATE(TIMESTAMP_MICROS(s.event_timestamp), 'Asia/Seoul')
       BETWEEN DATE_ADD(c.d0, INTERVAL 7 DAY) AND DATE_ADD(c.d0, INTERVAL 7 DAY)
)
SELECT
  CASE WHEN w.user_pseudo_id IS NOT NULL THEN 'watched' ELSE 'not_watched' END AS segment,
  SAFE_DIVIDE(COUNT(DISTINCT r.user_pseudo_id), COUNT(DISTINCT c.user_pseudo_id)) AS d7_retention
FROM cohort c
LEFT JOIN watched_rewarded w ON w.user_pseudo_id = c.user_pseudo_id AND w.watch_d <= DATE_ADD(c.d0, INTERVAL 7 DAY)
LEFT JOIN returned_d7 r ON r.user_pseudo_id = c.user_pseudo_id
GROUP BY segment;
-- 목표: watched.d7 ≥ not_watched.d7 + 0.05
```

## 6. 데이터 거버넌스

- **DebugView**: 디버그 빌드는 `-FIRDebugEnabled` 런 인수로 Firebase Console DebugView에서 실시간 검증.
- **Sandbox 격리**: 테스트 사용자(`debug_user=true` user property)는 분석 쿼리에서 제외 — 모든 SQL의 WHERE에 `(debug_user IS NULL OR debug_user='false')`.
- **이벤트 변경 시 절차**:
  1. 본 문서 PR로 갱신.
  2. po-lead + server-lead 사인오프.
  3. iOS 클라 코드 변경 + Functions 변경 + BigQuery 분석 쿼리 갱신.
  4. 1주 dual-write(구/신 둘 다) → 신만 사용.
- **이벤트 retention**: GA4 14개월 디폴트 → BigQuery export로 영구 보관.

## 7. 모니터링 알림 (Cloud Monitoring)

### 7.1 가드레일 알림

| 지표 | 임계 | 액션 |
|---|---|---|
| `event_count('crash')` 일별 | 직전 7일 평균 × 3 초과 | qa-lead + ios-lead Slack |
| ATT 동의율 (`att_prompt.granted/total`) | 일별 < 30% (가드레일 35%의 5pp 사전 경보) | po-lead 보고 |
| 인터스티셜 슬롯 `placement_session_idx > 1` 비율 | > 5% | po-growth + ios-auth-monetize 회의 |
| `auth_session_started` 일별 | 직전 7일 평균 × 0.5 미만 | po-lead + ios-lead 인시던트 |

### 7.2 성장 루프 사전 경보

| 지표 | 임계 | 액션 |
|---|---|---|
| 카드 공유율 (루프1) | 7일 이동평균 < 15% (목표 25%의 60%) | po-growth + designer-lead OG 카피 검토 |
| 위시 교집합 평균 (루프2) | 친구≥1 사용자 평균 < 1.5개 (목표 3의 50%) | po-growth + ios-social-collection 친구 추천 알고리즘 검토 |
| 보상형 시청 / DAU (루프4) | 7일 이동평균 < 0.08 (목표 0.15의 53%) | ios-auth-monetize 슬롯 노출 위치/타이밍 재조정 |

## 8. Phase 2 진입 게이트

- [x] PRD §4 모든 지표가 본 문서의 분자/분모 이벤트로 매핑됨 — § 4.1.
- [x] H1~H4 가설이 본 문서의 이벤트로 검증 가능 — § 4.3.
- [x] **H5/H10 신규 가설 + 성장 루프 5종**도 본 문서의 이벤트로 검증 가능 — § 3.10, § 4.2, § 5.3, § 5.4.
- [ ] po-lead 사인오프 (성장 루프 5종 통합 후).
- [ ] iOS 클라(ios-lead/ios-store/ios-social-collection)가 본 이벤트를 구현 가능한지 확인 (Phase 2 시작 시 ios-lead와 합의).
- [ ] server-functions가 `wishlist_match_created` 서버 발화 + `review_submitted` Functions ack 패턴 구현 (Phase 2-3).

## 9. Open Items

| ID | 항목 | 책임 | 마감 |
|---|---|---|---|
| OBS-1 | `dwell_ms` 측정 SDK 도입 검토 (§ 3.3 store_view + § 3.10.5 city_collection_progress_viewed dwell ≥ 1.0초 판정) | ios-lead | Phase 2 |
| OBS-5 | `wishlist_match_created` 서버 발화 Functions 구현 (위시리스트 onWrite 트리거 → 친구별 교집합 fanout) | server-functions | Phase 2-3 |
| OBS-6 | `app_open_universal_link.utm_source=card_share` 매핑 — H5 클릭→가입 8% 측정에 필수. 딥링크 페이로드에 utm 파라미터 포함 | ios-auth-monetize + server-functions | Phase 2 |
| OBS-7 | `app_install_referrer` 이벤트 + ASA `attribution_token` / `asa_keyword_id` 파라미터 — H6 US ASA CAC 검증 보조 | ios-auth-monetize + server-functions | Phase 2-3 (US 출시 D+30 이전) |
| OBS-2 | BigQuery export 활성화 + 비용 영향 추정 | server-lead | Phase 3 |
| OBS-3 | ATT 거부 사용자에게 광고 노출 정책 (가드레일 외 정책) | po-growth + ios-auth-monetize | Phase 2 |
| OBS-4 | `country_source=conflict` 케이스 분석 자동화 | server-lead | Phase 3 |

## 10. Changelog

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-04 | 초안 (PRD §4 + ADR-PROD-001 § 지표 정의 1:1 매핑) | server-lead (po-lead 사인오프 대기) |
| 2026-05-04 | v2: 성장 루프 5종(`card_share_initiated`/`wishlist_match_created`/`review_submitted`/`rewarded_ad_completed`/`city_collection_progress_viewed`) § 3.10 정식 카탈로그 + § 4.2 매핑 매트릭스 + § 4.3 H5/H10 신규 가설 매핑 + § 5.3/§ 5.4 BigQuery SQL + § 7.2 사전 경보. `review_submit`/`ad_reward` deprecated 명시. | server-lead (po-lead 사인오프 대기) |
| 2026-05-04 | v3: § 4.3에 H4'(US D+30 코호트) + H6(US ASA CAC) 신규 매핑 추가, 정량 분모/분자 정의 + § 9에 OBS-7(app_install_referrer + ASA token) 등록. ADR-PROD-003 출시 시퀀스 정합. | server-lead (po-lead 사인오프 대기) |
