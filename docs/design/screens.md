# Screens — 9 Modules · States · Wireframes

> PRD §3의 9개 모듈을 모두 화면 단위로 분해한 와이어프레임 + 상태(빈/로딩/에러/성공) 명세.
> 정전(canon) 시안: `_handoff/matchamap/project/MatchaMap v2.html` + `mm-screens-v2.jsx` (13 baseline 화면).
> SwiftUI 매핑은 `handoff-mapping.md`, 컴포넌트 정의는 `components.md`, 토큰은 `design-system.md` 참조.

소유: `designer-lead` · 사인오프: `po-lead` · 검수: `qa-functional`.

---

## 0. 페르소나 → 화면 시나리오 매핑 (po-growth icp.md 정합)

PRD §2 / `docs/product/icp.md` 3 페르소나에 따라 핵심 사용 시나리오. 각 화면 시안은 *해당 페르소나의 JTBD*를 우선 만족해야 함.

### 0.1 P1 · 여행자 매니아 — Critical Path

`낯선 도시 도착 → 5분 안에 진짜 매장 발견 → 시음 → 도감 등록`

핵심 화면 (시나리오 순서):
1. 04 World → 도시 검색 입력 ("도쿄") + locale 칩 "🇯🇵 일본"
2. 05 City Map → 도시 줌 + 정렬 "거리순" + 등급 필터 S만
3. 06 Map Preview → S 등급 매장 핀 탭 → floating 카드 + 길찾기 CTA
4. 07 Store Detail → 매장 상세 + 영업시간 + 주소
5. 10 ReviewWrite → 시음 후 도감 자동 등록 + 리뷰

UI 가드:
- **위치 권한 거부 시 fallback 필수** (04b) — 출장지 도착 전 검색 케이스 지원.
- **여행 모드 인디케이터**: 04 World에서 *현재 위치 외 도시 핀 검색*도 1차 시민. icp.md 페르소나1 Top Need 2 "여행 모드".
- **카테고리 정확도 필터**: 05 City Map의 칩에 "말차 전문 / 차 전문 / 일반 카페" 분류 chip 추가 검토 → po-growth + ios-store 합의.

### 0.2 P2 · 로컬 도감러 — Critical Path

`동네 매장 시음 → 도감 카드 등록 → 컬렉션 그리드 자랑 → 친구에게 공유`

핵심 화면:
1. 04 World 또는 05 City → 동네 매장 핀
2. 07 Store Detail → 매장 정보
3. 10 ReviewWrite → 평점 + 사진 + 태그
4. C1 Collection Grid → 카드 자동 등록 확인
5. C2 Memory Card Detail → 등급/원산지/색감 카드
6. 11 Feed → 친구에게 공유 (좋아요/댓글)

UI 가드:
- **C1 Grid 47/200 통계**: 미등록 카드 lock 시각화 → 도전 과제 동기부여(Top Need 3).
- **C2 카드 색감 슬라이더**: 5단계 색 (matchaSoft → deep) — icp.md 페르소나2 Sub-Job "색감 비교".
- **공유 카드 UX**: 도감 카드 단독 캡쳐 가능한 share sheet (instagram story 비율 9:16). v1.1 이연 가능, MVP 우선순위 결정 → po-lead.

### 0.3 P3 · 공유러 — Critical Path

`친구 피드 → 친구 매장 발견 → 위시리스트 추가 → 본인 방문 후 공유 → 친구가 댓글`

핵심 화면:
1. 11 Feed → 친구 매장 게시물
2. 07 Store Detail → 친구가 다녀온 매장 진입 + 위시 추가 (북마크)
3. 12 Wishlist → 국가별 그룹 + 친구 메모
4. (방문 후) 10 ReviewWrite → 본인 시음
5. 11 Feed → 본인 게시물 → 친구 좋아요/댓글

UI 가드:
- **친구 메모(rose italic) 시각 우선순위**: 12 Wishlist row에서 "{친구이름} 추천" 메모는 매장 이름 다음으로 잘 보이게.
- **바이럴 진입점**: 도감 카드/리뷰 deeplink 공유 (ASO + Instagram story embed). v1.1 검토.

### 0.4 페르소나별 화면 우선순위 매트릭스

| 화면 | P1 여행자 | P2 도감러 | P3 공유러 | MVP 필수 |
|---|---|---|---|---|
| 01 Splash | ● | ● | ● | YES |
| 02 Login | ● | ● | ● | YES |
| 03 Location | ● | ◐ | ◐ | YES |
| 04 World | ●● | ◐ | ◐ | YES |
| 05 City | ●● | ● | ◐ | YES |
| 06 Preview | ●● | ● | ◐ | YES |
| 07 Detail | ●● | ●● | ●● | YES |
| 08 Reviews | ◐ | ●● | ● | YES |
| 09 Search | ●● | ● | ◐ | YES |
| 10 Write | ◐ | ●● | ● | YES |
| 11 Feed | ◐ | ● | ●● | YES |
| 12 Wishlist | ● | ● | ●● | YES |
| 13 Profile | ◐ | ●● | ● | YES |
| C1 Grid | ◐ | ●● | ● | YES |
| C2 Card | ◐ | ●● | ◐ | YES |
| C3 Locked | ◐ | ●● | ◐ | v1.0 OR v1.1 |

(●● 핵심 / ● 자주 사용 / ◐ 부수)

---

## 1. 모듈 → 화면 매트릭스

| # | 모듈 | 담당 iOS | 화면 (canon ID 우선) | 추가 (canon 미포함) |
|---|---|---|---|---|
| 1 | Onboarding | ios-auth-monetize | 01 Splash · 02 Login · 03 Location | 03b Notification opt-in (선택) |
| 2 | Map | ios-map | 04 World · 05 City · 06 Preview | 04b Permission denied · 04c Empty(매장 0) |
| 3 | Store | ios-store | 07 Detail · 08 Reviews · 09 Search | 07b Closed banner · 09b Empty search · 09c No results |
| 4 | Review | ios-store | 10 ReviewWrite | 10b Photo permission · 10c Posting/Failed |
| 5 | Collection | ios-social-collection | (canon 미포함) | C1 Grid · C2 Card detail · C3 Locked card |
| 6 | Social | ios-social-collection | 11 Feed | F1 Story viewer · F2 Friend search · F3 Notification list |
| 7 | Wishlist | ios-social-collection | 12 Wishlist | 12b Empty · 12c Friend wishlist import |
| 8 | Profile | ios-social-collection | 13 Profile | 13b Edit · 13c Settings · 13d Friends list |
| 9 | Monetize | ios-auth-monetize | (UI 가드 오버레이) | M1 ATT prompt · M2 Banner slot · M3 Interstitial frame · M4 Rewarded sheet |

**총 화면 수**: canon 13 + 추가 17 ≈ **30개 화면 (MVP v1.0.0)**.

> Phase 2 디자인 팔로업으로 `Collection 모듈 (C1/C2/C3)`, `Profile 서브 화면 (13b/c/d)`, `광고 슬롯 컴포넌트 시안 (M1~M4)` 본격 시안화. canon 13개는 v2.html에 이미 픽셀 시안 존재.

---

## 2. Onboarding 모듈

### 1.1 화면 흐름

```
앱 첫 실행 → 01 Splash (1.2~2.5s)
              ↓
            02 Login (Apple/Passkey/이메일)
              ↓ 성공
            03 Location 권한
              ↓ 허용 / 거부
            04 World Map (홈)
```

재실행: Splash → 토큰 유효 시 04 World Map 직행.

### 1.2 화면별 상태

| 화면 | 빈(Empty) | 로딩(Loading) | 에러(Error) | 성공(Success) |
|---|---|---|---|---|
| 01 Splash | — | 로고 + 점선 회전 ring (2s 초과 시 표시) | "연결 확인 중" + 재시도 (10s 초과) | 즉시 Login 또는 Map 전이 |
| 02 Login | — | 버튼 inline spinner 16pt | inline toast `Color.MM.rose` "로그인 실패. 다시 시도해주세요." | 페이드아웃 → Location 화면 |
| 03 Location | — | 시스템 다이얼로그 표시 중 | 거부 시 fallback: "도시를 직접 선택하세요" + 도시 검색 입력 | "위치 사용 중" toast 1.5s → Map |

### 1.3 광고 UX 가드 (가시 흔적)

- Splash와 Login에는 **광고 노출 절대 금지** (`monetize.md` §3.1, PRD §6 첫 60초 차단).
- Splash 단계에서 T0 timestamp 저장 → Map 모듈에서 60s 타이머 기준값으로 사용.

### 1.4 와이어프레임 (canon 외 추가 화면)

#### 03b · 알림 권한 (선택, v1.1로 후순위)
- 위치 권한 동일 레이아웃, Lottie placeholder 변경.
- "친구가 새 매장을 등록하면 알려드려요" 카피.
- MVP에서는 첫 친구 추가 시점에 inline 권한 요청 (별도 화면 없음).

---

## 3. Map 모듈

### 2.1 canon 화면

- **04 World Map**: 전세계 핀 + 클러스터 + StatHero banner. 검색바 floating, 칩 row.
- **05 City Map**: 도시 줌 (GMS camera level 14~16). 정렬/필터 칩 + 우측 컨트롤 + 하단 carousel.
- **06 Map Preview**: 핀 탭 시 floating store card.

### 2.2 화면 상태

| 화면 | 빈 | 로딩 | 에러 | 성공 |
|---|---|---|---|---|
| 04 World | "근처 매장이 없어요" overlay + "다른 도시 찾기" CTA | 지도 영역 shimmer + spinner | "지도를 불러올 수 없어요" + 재시도 | 핀 노출 |
| 05 City | 핀 0개 → 04와 동일 메시지 | 동상 | "도시 데이터 없음" → 04로 fallback | 핀 + carousel |
| 06 Preview | — | 카드 skeleton (photo gradient + line shimmer) | "매장 정보를 불러올 수 없어요" + close | 카드 표시 |

### 2.3 광고 UX 가드 (가시 흔적)

- **배너 슬롯**: TabBar 위 `AdBannerSlot` 320×50, 첫 60s 동안 `.opacity(0)` + height 0, T+60s에 fade-in 250ms.
- **컨텍스트 hide**: 06 Preview sheet 열릴 때 배너 hidden (sheet detent ≥ medium 시).
- 검색 입력 focus 시 배너 hidden.
- 시각적 격리: 배너 위 1pt `Color.MM.lineSoft` divider, 콘텐츠와 padding 0.

### 2.4 와이어프레임 (canon 외 추가)

#### 04b · 위치 권한 거부 fallback
- 헤더는 04와 동일 + 안내 banner `Color.MM.rosePale` "위치 권한이 꺼져있어요" + "도시 선택" PrimaryButton.
- 도시 선택 modal: 7개 (서울/도쿄/오사카/뉴욕/런던/베를린/파리) + 검색.

#### 04c · 매장 0 (지역 cold start)
- 지도 영역 빈 + 중앙 LottiePlaceholder + 헤드라인 "이 지역은 곧 추가될 거예요" + GhostButton "다른 도시 보기".

---

## 4. Store 모듈

### 3.1 canon 화면

- **07 Store Detail**: hero photo + 매장 정보 + 탭(소개/메뉴/리뷰).
- **08 Reviews tab**: 평점 분포 + 필터 + 리뷰 카드 리스트.
- **09 Search**: inline search bar + 카테고리 칩 + 결과 리스트.

### 3.2 화면 상태

| 화면 | 빈 | 로딩 | 에러 | 성공 |
|---|---|---|---|---|
| 07 Detail | hero photo placeholder + "사진 없음" mono 라벨 | hero shimmer + 본문 skeleton 3줄 | "매장을 찾을 수 없어요" + back | 정상 |
| 07b Closed | (영업 종료 시) 영업시간 카드 위에 `Color.MM.rosePale` banner "지금은 영업 종료" | — | — | — |
| 08 Reviews | "아직 리뷰가 없어요" + 큰 ✏ 아이콘 + "첫 리뷰 작성" PrimaryButton | 리뷰 카드 skeleton 3개 | 동상 | 리스트 |
| 09 Search | 검색 입력 전 → recent searches + popular | 입력 후 spinner inline | "검색 실패" + 재시도 | 결과 |
| 09b Empty search | "검색어 없음" + "근처 매장 보기" CTA | — | — | — |
| 09c No results | "결과가 없어요" + 필터 reset GhostButton | — | — | — |

### 3.3 광고 UX 가드

- **인터스티셜**: 07 Detail 진입 5번째마다 (PRD §6 사용자당 ≤ 1회/세션 P95). 첫 60초 차단. 광고 후 화면 진입 시 Detail 헤더 visible 0ms 보장.
- 실제 노출 인터스티셜 GMS SDK 풀스크린 — 본 디자인 시스템 토큰 적용 불가. 닫기 버튼 우상단 시스템 기본.

### 3.4 와이어프레임 (canon 외 추가)

#### 07b · Closed banner
- 영업시간 카드(line 360) 위에 height 36 banner: bg `Color.MM.rosePale`, fg `Color.MM.deep`, 아이콘 `clock` 14pt, "지금은 영업 종료 · 다음 영업 화 9:00" + chevron-right.

#### 09b · Empty search (입력 전)
- 검색 입력 0자.
- "최근 검색" mono 라벨 + Chip row (최근 6개).
- "지금 인기" mono 라벨 + StoreCard mini-list (top 5 nationwide).

#### 09c · No results
- 검색어 입력 후 결과 0.
- 큰 SVG illustration `magnifying-glass-leaf.svg` 120×120 (designer-icon 후속).
- 헤드라인 `MMTypography.title2` "결과가 없어요" + 부제 "다른 검색어를 시도해보세요" + GhostButton "필터 초기화".

---

## 5. Review 모듈

### 4.1 canon 화면

- **10 ReviewWrite**: 매장 row + 별점 + 사진 grid + 태그 + 본문.

### 4.2 화면 상태

| 화면 | 빈 | 로딩 | 에러 | 성공 |
|---|---|---|---|---|
| 10 Write | 별점 0 + 사진 0 + 본문 0 → 등록 disabled (`Color.MM.muted` bg) | 등록 버튼 inline spinner | inline toast "등록 실패" + 자동 재시도 안내 | 화면 닫고 toast "리뷰가 등록됐어요" |
| 10b Photo perm | 권한 없을 때 grid 추가 슬롯 탭 → 시스템 다이얼로그. 거부 시 inline banner "사진 접근이 꺼져있어요 · 설정에서 허용" + 설정 deeplink GhostButton | — | — | — |
| 10c Posting | 등록 후 네트워크 끊김: 큐잉(MVP는 v1.1.0 비범위) → "오프라인입니다. 연결 후 다시 시도해주세요" toast. 입력은 보존 | — | — | — |

### 4.3 광고 UX 가드

- 리뷰 등록 직후 인터스티셜 노출 **금지** (긍정 액션 직후 광고 = 사용자 박탈감, PRD §6 가드레일).

### 4.4 별점 → 카피 매핑 (다국어)

| 별점 | ko | en | ja | de | fr |
|---|---|---|---|---|---|
| 1 | 별로예요 | Not great | いまいち | Nicht gut | Bof |
| 2 | 그저 그래요 | It's okay | まあまあ | Geht so | Moyen |
| 3 | 괜찮아요 | Decent | 普通 | Ganz okay | Correct |
| 4 | 좋아요 | Good | おいしい | Gut | Bien |
| 5 | 완벽해요! | Perfect! | 最高! | Perfekt! | Parfait! |

→ String Catalog `review.rating_caption.{n}` 키. `qa-localization` 회귀.

---

## 6. Collection (도감) 모듈 — canon 미포함, 신규 시안

> PRD §3-5 도감. canon 13개에 도감 화면 시안 없음 — designer-lead가 본 문서에서 신규 정의. v2.html 시각 어휘 동일하게 유지.
> 데이터 SSOT: `docs/server/schema.md` § 2.1 (server-data ADR-302) — `stores.origin` (매장 SSOT) + `collections/items.{grade,originRegion,colorHex}` (사용자 도감 카드).

### 6.1 화면

- **C1 · Collection Grid**: 도감 메인. 사용자가 등록한 매장×등급 카드를 그리드 (3열 thumb).
- **C2 · Memory Card Detail**: 카드 1개 상세 (등급/원산지/색감/방문일/사진 수).
- **C3 · Locked Card**: 미등록 / 잠금 카드. 보상형 광고로 unlock.

### 6.2 데이터 소스 정책 (server-data ADR-302 정합)

도감 카드 표시 시 두 SSOT 충돌 정책:

| 필드 | 1차 소스 | 2차 (fallback) | 사용자 입력 시 |
|---|---|---|---|
| 매장명 | `stores.name` | — | (override 불가, store FK) |
| 등급 grade | `collections/items.grade` (사용자 평가) | `stores.origin.grade` (매장 SSOT) | 사용자가 등록 시 직접 선택. 매장 origin 있으면 prefill. |
| 원산지 region | `collections/items.originRegion` (사용자 기록) | `stores.origin.region` | 매장 origin 있으면 prefill, 없으면 자유 입력 |
| 원산지 country | `collections/items.originCountry` | `stores.origin.country` (ISO-3166 alpha-2) | 동상 |
| 색감 colorHex | `collections/items.colorHex` (사용자 기록) | (매장 SSOT 없음) | 사용자 평가 슬라이더 결과 |
| 방문일 visitedAt | `collections/items.visitedAt` | — | 등록 시점 또는 사용자 수정 |
| 사진 photos | `collections/items.photoIds[]` | — | — |

**Prefer 정책**: **사용자 도감 카드(`collections/items`)를 1차 prefer**. *내가 마신 한 잔의 기억*이 도감의 본질이므로 매장 SSOT보다 사용자 평가가 우선. 사용자 입력 0인 필드만 매장 origin fallback. 매장 origin 표기 시 mono 라벨 "매장 정보" 부기.

**v1.0.0 cold start (origin 채워진 매장 ~15-20%)**:
- 도감 카드 등록 UI(`screens.md § 5 ReviewWrite` 후속)에서 매장 origin 있으면 prefill.
- 매장 origin 없으면 사용자 직접 입력 (자유 입력 + region enum 추천 칩).
- 사용자가 입력 안 하면 도감 카드의 origin 섹션 hide (필드 비어 있음 → 섹션 자체 비표시).

### 6.3 와이어프레임

#### C1 · Collection Grid
- 헤더: "도감" `MMTypography.headline` + 통계 `47 / 200` mono.
- 필터 칩 row: 등급 (전체/S/A/B/C) · 국가 (jp/kr/us/uk/de/fr).
- 그리드 3×N: thumb 110×140 (radius `MMRadius.lg`), 좌상단 `GradeChip(.sm)` (사용자 grade), 좌하단 매장명 11pt 1줄, 잠금 카드는 `Color.MM.cream` bg + 자물쇠 아이콘.
- 빈 상태: "첫 매장을 마셔보세요" + "지도 보기" PrimaryButton.

#### C2 · Memory Card Detail (server-data 정합)
- 화면 전체 hero photo height 320 + gradient overlay → bottom paper card.
- bottom card 구성 (위→아래):
  1. **매장명** `MMTypography.title2` `Color.MM.deep` + 우측 hero `GradeChip(.lg)` (사용자 grade)
  2. **메타** mono row: `방문일 visitedAt` (RelativeDateTimeFormatter) · `마신 종류 (예: 코이차/우스차/호우지차)` · `사진 N장`
  3. **"원산지" 섹션** (origin 있을 때만 표시):
     - 좌상단 mono 라벨 `MMTypography.monoLabel` `Color.MM.muted` "ORIGIN"
     - 우상단 fallback 표시: 사용자 입력 시 mono 라벨 "내 기록", 매장 origin fallback 시 mono 라벨 "매장 정보"
     - 본문: region chip `Color.MM.matchaPale` (예: "🇯🇵 우지" / "🇰🇷 보성") + grade enum chip (`ceremonial`/`premium`/`standard`/`culinary` — i18n 5언어 카피)
     - origin notes 200자 본문 `MMTypography.callout` `Color.MM.text`
     - 우측 mini-map (`CityMap2` 60×80) — region 좌표 표시. **좌표 매핑 SSOT**: `design-system.md § 9 MatchaOriginCoords` (8 region × {lat, lng} hardcoded — server-data Q1 (b) 채택, 2026-05-04). enum 외 / `.other` / `.unknown` / null 시 mini-map **전체 hide**.
  4. **"색감" 섹션** (server-data ADR-302 v1.1 `colorTier` enum 5단계):
     - 좌상단 mono "COLOR"
     - 5단계 색 슬라이더 stop: `matchaSoft` → `matchaPale` → `matcha` → `deepMatcha` → `deep` (matchaSoft가 가장 연함). **매핑 SSOT**: `design-system.md § 1.5.1 colorTier`. server-data Q2 (하이브리드) 채택 — 사용자는 enum 5단계만 입력, `colorHex`는 Cloud Functions가 자동 미러.
     - 사용자 평가 마커: `colorTier` stop 위치에 `Color.MM.deep` dot. 미입력(`colorTier=null`) 시 슬라이더 hide.
  5. **하단** `PrimaryButton(.fullWidth)` "다시 방문" → 매장 상세 (07)로.

##### 다국어 라벨 매핑 (origin.grade enum)
| enum | ko | en | ja | de | fr |
|---|---|---|---|---|---|
| ceremonial | 다도용 | Ceremonial | 抹茶（濃茶） | Zeremoniell | Cérémonial |
| premium | 프리미엄 | Premium | プレミアム | Premium | Premium |
| standard | 스탠다드 | Standard | スタンダード | Standard | Standard |
| culinary | 요리용 | Culinary | 料理用 | Kulinarisch | Culinaire |

##### 다국어 라벨 매핑 (origin.region enum)
| enum | ko | en | ja | de | fr |
|---|---|---|---|---|---|
| uji | 우지 | Uji | 宇治 | Uji | Uji |
| nishio | 니시오 | Nishio | 西尾 | Nishio | Nishio |
| shizuoka | 시즈오카 | Shizuoka | 静岡 | Shizuoka | Shizuoka |
| kagoshima | 가고시마 | Kagoshima | 鹿児島 | Kagoshima | Kagoshima |
| boseong | 보성 | Boseong | 宝城 | Boseong | Boseong |
| hadong | 하동 | Hadong | 河東 | Hadong | Hadong |
| jeju | 제주 | Jeju | 済州 | Jeju | Jeju |
| other | 기타 | Other | その他 | Andere | Autre |

→ String Catalog 키: `origin.region.{enum}` / `origin.grade.{enum}`. `qa-localization` 회귀.

#### C3 · Locked Card
- thumb는 C1 그리드 안의 한 항목.
- 풀스크린 modal: 잠금 카드 미리보기(blur) + "이 매장을 마시면 도감에 등록돼요" + 두 CTA:
  1. `PrimaryButton(.fullWidth)` "지도에서 보기"
  2. `SecondaryButton(.fullWidth)` "광고 시청하고 unlock" (보상형, 24h 쿨다운 후)

### 6.4 화면 상태

| 화면 | 빈 | 로딩 | 에러 | 성공 |
|---|---|---|---|---|
| C1 Grid | "첫 매장을 마셔보세요" empty state | thumb skeleton (110×140 shimmer) | "도감 불러오기 실패" + 재시도 | 그리드 |
| C2 Detail | 사진 0 → "사진 없음" placeholder, origin/색감 미입력 시 섹션 hide | hero shimmer | "카드 정보 없음" + back | 정상 |
| C3 Locked | — | 광고 로딩 spinner | "광고 로드 실패" toast + close | 보상 → 카드 unlock 애니메이션 (matchaPale → matcha 그라디언트 0.4s) |

### 6.5 광고 UX 가드 (보상형)

- C3에서만 보상형 광고 호출.
- 도감 카드별 24h 쿨다운: AsyncStorage `unlock.{storeId}.lastTriggeredAt`.
- 광고 미로드 시 SecondaryButton disabled + "광고 준비 중" 라벨.

---

## 7. Social 모듈

> Stories 24h 기능은 v1.1.0 이연 (po-lead 결정). canon 11 Feed의 Stories row는 v1.0.0에서 hidden 처리 (designer-icon 자산은 보존, FeatureSocial 빌드 플래그로 toggle).

### 7.1 canon 화면

- **11 Feed**: stories row + post 리스트 (avatar + content + photo + actions).

### 6.2 추가 화면

- **F1 · Story Viewer**: 풀스크린 dark, 상단 progress bar 5개, 좌우 탭 prev/next, 하단 reply input.
- **F2 · Friend Search**: inline search bar + 친구 추천 row (Avatar + name + handle + Add button).
- **F3 · Notification List**: 알림 활동 (좋아요/댓글/팔로우).

### 6.3 화면 상태

| 화면 | 빈 | 로딩 | 에러 | 성공 |
|---|---|---|---|---|
| 11 Feed | "친구를 추가해 피드를 시작하세요" + "친구 찾기" PrimaryButton | post skeleton 3개 (avatar + line + image area shimmer) | "피드를 불러올 수 없어요" + pull-to-refresh | 정상 |
| F1 Story | — | progress bar fill 0→100% | 사진 로드 실패 → 다음 자동 | 다음 친구로 |
| F2 Search | 입력 전 → "추천 친구" 리스트 | 검색 spinner | "검색 실패" toast | 결과 |
| F3 Notifications | "알림이 없어요" + 빈 종 아이콘 | skeleton row 5 | 동상 | 리스트 |

### 6.4 광고 UX 가드

- 피드 매 5 post 사이 native ad (v1.1.0 옵션). MVP 미포함 — `po-growth` 합의 시 포함.
- ATT 프롬프트는 첫 방문 60초 후, 첫 광고 노출 *직전* 트리거 (`monetize.md`).

### 6.5 Stories 24h 정책 (PRD 결정 필요)

> **Open issue**: PRD §3 Social에 "친구 피드, 좋아요/댓글" 명시. Stories(24h) 명시 없음. canon 시안엔 포함. v1.0 vs v1.1 결정 필요 — `po-lead`에 별도 메시지로 사인오프 요청.

---

## 8. Wishlist 모듈

### 7.1 canon 화면

- **12 Wishlist**: 헤더 + mini world map + 국가 칩 + 지역별 그룹 리스트.

### 7.2 추가 화면

- **12b · Empty**: 위시 0건. 큰 illustration + "지도에서 보기" + "친구 위시리스트 가져오기".
- **12c · Friend Wishlist Import**: 친구 선택 → 그 친구의 위시 리스트 보기 + add to mine.

### 7.3 화면 상태

| 화면 | 빈 | 로딩 | 에러 | 성공 |
|---|---|---|---|---|
| 12 List | 12b 화면 | mini map shimmer + row skeleton | "위시 불러오기 실패" + 재시도 | 정상 |
| 12c Friend | "공개 위시 없음" | spinner | "친구 위시 비공개" | 리스트 + add |

### 7.4 광고 UX 가드

- 위시리스트 화면은 광고 슬롯 **없음** (저속 탐색 화면, 광고 충돌).

---

## 9. Profile 모듈

### 8.1 canon 화면

- **13 Profile**: 헤더 + Avatar + StatHero + 최근 마신 말차 carousel + 메뉴.

### 8.2 추가 화면

- **13b · Edit**: Avatar 변경 / 이름 / 핸들 / 한 줄 소개 / 출신 도시.
- **13c · Settings**: 알림 / 개인정보 / 광고 환경 (ATT 재요청 / Do Not Sell) / 언어 / 로그아웃.
- **13d · Friends List**: 친구 / 팔로워 / 팔로잉 탭.

### 8.3 화면 상태

| 화면 | 빈 | 로딩 | 에러 | 성공 |
|---|---|---|---|---|
| 13 Profile | 통계 0 → "첫 매장을 방문해보세요" CTA | StatHero skeleton + carousel skeleton | "프로필 불러오기 실패" + retry | 정상 |
| 13b Edit | — | 저장 버튼 inline spinner | "저장 실패" toast | 저장 후 toast + back |
| 13c Settings | — | row skeleton | — | 정상 |
| 13d Friends | "친구가 없어요" + Add CTA | row skeleton | — | 리스트 |

### 8.4 광고 UX 가드

- 프로필은 광고 슬롯 **없음** (사용자 정체성 영역, 광고 침범 시 부정 인식).
- 13c 설정 화면에 "광고 환경 설정" 섹션 명시: ATT 재요청 / Do Not Sell / 광고 정책 안내 (GDPR/CCPA, `monetize.md` §5).

---

## 10. Monetize 모듈 — 광고 슬롯 시안

### 9.1 화면 / 컴포넌트

- **M1 · ATT Prompt 안내 화면**: iOS 시스템 ATT 다이얼로그 *직전* 표시되는 in-app 안내. 동의율 향상 목적 (PRD 가드레일 ≥ 35%).
- **M2 · Banner Slot UI**: 배너 컨테이너 디자인 (TabBar 위 320×50).
- **M3 · Interstitial 진입 시 wrapper**: 광고 로딩 중 화면 (system interstitial 자체는 GMS SDK).
- **M4 · Rewarded Sheet**: C3 Locked Card에서 호출하는 보상형 광고 안내 sheet.

### 9.2 와이어프레임

#### M1 · ATT Prompt 안내
- 풀스크린 modal `Color.MM.bg`.
- 중앙 SVG illustration (잎 + 별 sparkle) 120×120.
- 헤드라인 `MMTypography.title2` "더 적합한 광고를 보여드릴게요".
- 본문 `MMTypography.body` 3줄 (약 80자, 다국어 마진 +20%): "광고 식별자 사용에 동의하시면 더 관련성 높은 광고를 볼 수 있어요. 거부해도 앱은 정상 사용 가능합니다."
- 하단 두 CTA:
  1. `PrimaryButton(.fullWidth)` "동의하고 계속" → 시스템 ATT 다이얼로그 호출
  2. `GhostButton` "지금은 비공개로" → 비개인화 광고 모드
- mono 안내 "언제든지 설정 > 광고 환경 에서 변경 가능" `Color.MM.muted`.

#### M2 · Banner Slot UI
- height 50 (또는 100 if `po-growth` 결정), full width.
- top: 1pt `Color.MM.lineSoft` divider.
- bg `Color.MM.paper`.
- 광고 영역 = GMS SDK iframe 그대로. 좌우 padding 0 (GMS 광고가 컨트롤).
- 시각 명료성: 좌상단 6pt × 14pt mono 라벨 "AD" `Color.MM.muted` (Apple 5.1.1 / GDPR 광고 disclosure).
- skeleton (광고 미로드): `Color.MM.lineSoft` shimmer 50% width.

#### M3 · Interstitial Wrapper
- 인터스티셜 자체는 GMS SDK 풀스크린 — 디자인 토큰 적용 불가.
- *호출 직전* 0.4s 검은색 fade-in transition으로 컨텍스트 전환 시그널.
- 닫힘 후 0.25s fade-in으로 화면 복귀 → 사용자가 광고 → 콘텐츠 전환을 명확히 인지.

#### M4 · Rewarded Sheet
- Sheet detent `.medium`.
- 헤더 grab handle 36×5 + 우상단 close.
- 중앙 잠금 SVG 80×80 → 잎(`leaf-fill`) 80×80 모핑 (광고 후 reveal).
- 헤드라인 `MMTypography.title2` "광고 보고 도감 카드 unlock".
- 본문 "약 30초 광고를 끝까지 시청하면 이 매장을 도감에 추가할 수 있어요."
- CTA: `PrimaryButton(.fullWidth)` "광고 시청 시작" → GMS rewarded.
- footer mono "쿨다운 24시간".

### 9.3 광고 UX 가드 (총괄)

| 가드 | 적용 대상 | 시각적 표현 |
|---|---|---|
| 첫 60초 차단 | 모든 광고 | 배너 height 0 + opacity 0 (T+60s에 spring fade-in) |
| 첫 화면 (Splash/Login) 차단 | 모든 광고 | 절대 금지 — 모듈 자체에 슬롯 없음 |
| 매장 미리보기 sheet 시 hide | 배너 | sheet detent ≥ medium → 배너 fade-out 200ms |
| 검색 input focus 시 hide | 배너 | focus → 배너 fade-out 150ms |
| 인터스티셜 쿨다운 90s | 인터 | 호출 무시, 광고 미노출 |
| 인터스티셜 ≤ 1/세션 P95 | 인터 | matchamap-orchestrator 정책 enforce |
| 보상형 24h 쿨다운 (카드별) | 보상 | 버튼 disabled + "다시 시도 가능: 23시간 후" 라벨 |
| 긍정 액션 직후 광고 금지 | 인터 | 리뷰 등록 / 친구 추가 직후 광고 호출 무시 |

### 9.4 GDPR / CCPA / ATT

- **GDPR (EU 5국)**: UMP SDK 동의 다이얼로그 첫 실행 시 호출. 비동의 시 비개인화 광고 fallback. 13c Settings에서 "동의 변경" 진입 가능.
- **CCPA (US)**: 13c Settings에 "Do Not Sell My Personal Information" 토글.
- **ATT**: PRD §6 첫 60초 후 + 첫 광고 슬롯 도달 직전 호출. M1 in-app 안내 → 시스템 다이얼로그 → 결과 저장.

---

## 11. iOS 26.2 Liquid Glass 적용 정책

### 10.1 적용 대상 (sparingly)

iOS 26.2의 `.glassEffect()` modifier는 **선택적 사용**. 남발 시 가독성/배터리/성능 모두 악화.

| 컴포넌트 | Liquid Glass | 사유 |
|---|---|---|
| TabBar2 | **YES** (.glassEffect(.thin)) | OS 표준, 이미 시안에서 backdrop blur 사용 |
| 04 World Map 검색바 (floating) | **YES** (.glassEffect(.thin)) | 지도 위 floating, 시안에서 blur(12px) 사용 |
| 07 Detail glass IconButton (back/share/bookmark) | **YES** | 시안에서 backdrop blur 8px |
| StatusBar2 area | **NO** | 시스템 자체 적용 |
| 06 Map Preview 카드 | **NO** | 카드 자체 paper bg, blur 시 가독성 저하 |
| Sheet handle area | **NO** | 시스템 기본 |
| 모든 본문 카드 (StoreCard, ReviewCard, FeedPostCard) | **NO** | 가독성 우선, paper opaque |

### 10.2 fallback (iOS 26.2 미만 — 본 프로젝트 deployment target)

- 본 프로젝트 iOS 26.2 단일 deployment target이므로 fallback 불필요.
- 단, `.glassEffect()` API availability 확인 후 `if #available(iOS 26.2, *)` wrap. 미지원 디바이스(iPhone 11 이전)에서는 `.background(.ultraThinMaterial)` 로 graceful degrade.

### 10.3 색·대비 영향

- glassEffect는 배경에 따라 텍스트 대비가 달라짐 → 텍스트 항상 `Color.MM.deep` 또는 `.ink` 사용. `.muted` 같은 약한 톤은 glass 위 사용 금지.
- `qa-localization` + `qa-functional`이 6개 언어 + 3가지 배경(밝은 지도/어두운 사진/일반) 조합으로 회귀.

---

## 12. 화면 전환 / 모션 정책

| 전환 | 모션 | 비고 |
|---|---|---|
| 탭 전환 | 즉시 (no animation) | iOS HIG 표준 |
| Push (Detail 진입) | system push 0.35s easeOut | iOS 기본 |
| Modal (리뷰 작성) | system fullScreenCover 0.3s | sheet `.large` 또는 fullScreenCover |
| Sheet (Map Preview) | `MMMotion.spring` (response 0.45 / damping 0.8) | drag 가능 |
| ATT/Rewarded | system modal | iOS 기본 |
| Splash → Login/Map | crossFade 0.3s | 부드러운 전이 |
| Pin glow (S 등급) | `MMMotion.pulse` 2s 무한 | 항상 활성 |
| Lottie 회전 | 18s/12s 무한 (forward/reverse) | 03 Location 화면 |

---

## 13. 검수 기준 (per screen)

각 화면 빌드 시 `qa-functional`이 검수:

1. **상태 4종 모두 구현?** (빈 / 로딩 / 에러 / 성공)
2. **canon 시안 픽셀 일치?** (color / spacing / radius / typography 모두 토큰)
3. **광고 UX 가드 작동?** (60초 차단 / hide / 쿨다운)
4. **다국어 5개 (ko/en/de/ja/fr) 가장 긴 카피 적용 시 줄넘침/잘림 없음?**
5. **VoiceOver 모든 컨트롤 라벨?** (`accessibility.md` 체크리스트)
6. **Dynamic Type XS~AX5 레이아웃 유지?**
7. **WCAG AA 컨트라스트?** (`design-system.md § 1.8` 룰 준수)

검수 실패 시 PR 차단, designer-lead에 SendMessage.

---

## 14. 변경 이력

| 일자 | 변경 | 사유 |
|---|---|---|
| 2026-05-04 | 초안 작성 (9 모듈 30 화면 매핑 + 4상태 + 광고 UX 가드 시안화 + Liquid Glass 정책) | designer-lead, po-lead 후속 요청 |
| 2026-05-04 | § 0 페르소나 → 화면 시나리오 매핑 추가 (P1/P2/P3 Critical Path + UI 가드 + 우선순위 매트릭스) | po-lead 사인오프 메시지 — icp.md 3 페르소나 정합 요청 |
| 2026-05-04 | § 6 Collection 모듈 stores.origin 정합 (server-data ADR-302) — 데이터 소스 정책(사용자 1차 prefer + 매장 fallback) + origin region/grade enum 5언어 i18n 매핑. § 7 Stories v1.1 이연 명시. 섹션 번호 5.x→6.x 정정 | server-data SendMessage + po-lead 결정 |

---

References:
- canon: `_handoff/matchamap/project/MatchaMap v2.html` + `mm-screens-v2.jsx`
- PRD: `docs/product/PRD.md` § 3 모듈 표, § 6 비기능 가드
- 광고 정책: `docs/product/admob-slots.md` § 3 UX 가드
- 사이드: `docs/design/design-system.md`, `docs/design/components.md`, `docs/design/handoff-mapping.md`
