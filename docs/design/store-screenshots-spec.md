# Store Screenshots & Key Visual Spec — MatchaMap v1.0.0

> Owner: `designer-icon` · Reviewers: `designer-lead`, `po-lead`, `po-growth`, `qa-localization`
> Trigger: `app-icon-decision.md` (B 채택) §7 약점 보강 정책. 앱 아이콘이 "잎"만 노출하므로 **스토어/온보딩에서 컵+잎 컴포지션을 명시 노출**해 음료/카테고리 시그널을 보강.
> 자동화 fastlane lane: `screenshots` (시뮬레이터 6개 언어 일괄 캡처), `upload_metadata` (App Store Connect 일괄 업로드).

---

## 1. 정책 (강제 사항)

1. **컵+잎 컴포지션을 첫 스크린샷(슬롯 1)에 반드시 포함**. 잎만 노출되는 시각은 슬롯 1 금지.
2. **앱 아이콘 B의 잎 실루엣 + vein 시그니처 패턴(6 비대칭)을 일관되게 재사용**. 새로운 잎 모양 임의 생성 금지.
3. **컬러 토큰은 MM2(`decisions-design.md`) 강제**. 임의 색 추가 금지.
4. **6개 언어 모두 같은 슬롯 구성**. 카피만 언어별 카탈로그 키로 분기.
5. **광고 슬롯/AdMob 배너는 스크린샷에 노출 금지** — 첫 60초 광고 차단 정책(PRD §6)과 정합.
6. **개인 식별 정보 노출 금지** — 임의 닉네임/사진은 디자이너 제공 placeholder만 사용.

---

## 2. 슬롯 구성 (App Store 6.7" iPhone — 1290×2796 마스터)

App Store Connect는 최대 10장. v1.0.0은 6장 강제 + 4장 선택 보충.

| # | 슬롯명 | 카피 키 | 비주얼 핵심 | 컵+잎 노출 |
|---|---|---|---|---|
| 1 | hero-discover | `aso.s1.title` / `aso.s1.body` | **컵 + 잎 + 거품 컴포지션** (앱 아이콘 A 모티프 재사용) + "전세계 말차 카페 발견" 카피 | **필수** |
| 2 | map-world | `aso.s2.title` / `aso.s2.body` | 전세계 지도 + 매장 핀 클러스터 + 도쿄/서울/파리 줌 미리보기 | 핀(잎) 노출 |
| 3 | store-detail | `aso.s3.title` / `aso.s3.body` | 매장 상세 카드 + 평점 + 메뉴 + 리뷰 1건 | 메뉴 카드에 잎 아이콘 노출 |
| 4 | collection | `aso.s4.title` / `aso.s4.body` | 도감 그리드 + 등급/원산지/색감 | 그리드 항목 라벨에 잎 노출 |
| 5 | wishlist | `aso.s5.title` / `aso.s5.body` | 위시리스트 국가별 그룹 + 미니 세계지도 | 국가 그룹 헤더에 잎 노출 |
| 6 | social-feed | `aso.s6.title` / `aso.s6.body` | 친구 피드 카드 N개 + 좋아요/댓글 | 피드 카드 사진 1건에 잎 라떼아트 |
| 7 (옵션) | onboarding-value | `aso.s7.title` | 가치제안 화면(컵 + 잎 + 거품 키비주얼) | **필수** |
| 8 (옵션) | review-creation | `aso.s8.title` | 리뷰 작성 + 사진 첨부 | - |
| 9 (옵션) | profile-stats | `aso.s9.title` | 프로필 통계 + 누적 컬렉션 N개 | - |
| 10 (옵션) | localized-cities | `aso.s10.title` | 출시 6개 국가 도시 콜라주 | 각 도시 핀(잎) |

> 슬롯 1과 7은 컵+잎 컴포지션 필수. 나머지는 잎 단일 노출도 허용(핀/뱃지로 잎 시그널 유지).

---

## 3. 키비주얼 — 컵+잎 컴포지션 (슬롯 1, 7)

**모티프 재사용**: 앱 아이콘 후보 A(`_design_assets/svg/appicon/A-foam-leaf.svg`) — B로 채택되지 않았지만 **마케팅 키비주얼로 재사용**해 음료 시그널 보강. (B와 A의 잎 좌표는 동일 — vein 시그니처 일관)

### 3.1 컴포지션 좌표 (1290×2796 캔버스)

- 캔버스 = 1290×2796 (cx = 645).
- 컵 본체 폭 = 760, 컵 상단 y = 980, 컵 바닥 y = 1660. 좌우 cx=645 대칭.
- 거품 ellipse: cx=645 cy=1010 rx=370 ry=72.
- 잎 (앱 아이콘과 동일 vein 시그니처):
  - 잎 tip = (645, 720), 잎 base = (645, 1320) (거품 위에 살짝 떠 있는 위치).
  - 잎 폭 = 320 (좌우 대칭).
- 헤드라인 카피: 잎 위 y=400 영역, 가운데 정렬.
- 배경: MM2.cream `#f5f1ea` → MM2.matchaPale `#e6ecde` 라디얼 그라데이션 (앱 아이콘 A의 배경 그라데이션과 동일).
- 좌측 상단/우측 하단에 미세 보케(matcha/rose) — B의 보케 좌표를 1290 캔버스에 비례 확대.

### 3.2 vein 시그니처 (동결 — v2.x까지 변경 금지)

앱 아이콘 B의 잎 vein 6개를 1290 캔버스에 비례 확대해서 그대로 재사용. 새로운 vein 패턴 그리지 말 것.

| vein# | 시작점 (앱아이콘 B 좌표 / 1024) | 종점 |
|---|---|---|
| 중앙 | (512, 280) | (512, 770) |
| 좌1 | (512, 360) | (388, 440) |
| 우1 | (512, 360) | (636, 440) |
| 좌2 | (512, 470) | (372, 580) |
| 우2 | (512, 470) | (652, 580) |
| 좌3 | (512, 600) | (408, 690) |
| 우3 | (512, 600) | (616, 690) |

> 1290×2796 캔버스에서 잎 영역 (645, 720)..(645, 1320)일 때 위 좌표를 비례 확대 (× ~1.18) 적용. 자동 계산은 fastlane `screenshots` lane에서 수행.

---

## 4. 카피 매트릭스 (6개 언어)

> String Catalog `aso.xcstrings`에 다음 키 일괄 등록. 빈 키 0건 — `qa-localization` 회귀 통과 조건.

| 키 | KR | EN-US | EN-GB | DE | JA | FR |
|---|---|---|---|---|---|---|
| `aso.s1.title` | 전세계 말차 카페, 한 손에 | Find matcha cafés worldwide | Find matcha cafés worldwide | Matcha-Cafés weltweit entdecken | 世界の抹茶カフェを、ひとつのアプリで | Cafés matcha du monde entier |
| `aso.s1.body` | 도쿄·서울·파리·뉴욕 어디서든 | From Tokyo to Paris, in one app | From Tokyo to Paris, in one app | Von Tokio bis Paris, in einer App | 東京、ソウル、パリ、ロンドン | De Tokyo à Paris, en une app |
| `aso.s2.title` | 지도에서 발견 | Discover on the map | Discover on the map | Auf der Karte entdecken | マップで発見 | Découvrir sur la carte |
| `aso.s3.title` | 매장 상세와 메뉴 | Stores and menus | Stores and menus | Cafés und Menüs | お店とメニュー | Cafés et menus |
| `aso.s4.title` | 나만의 말차 도감 | Your matcha collection | Your matcha collection | Deine Matcha-Sammlung | あなたの抹茶コレクション | Votre collection matcha |
| `aso.s5.title` | 위시리스트, 나라별로 | Wishlist by country | Wishlist by country | Wunschliste nach Land | 国別ウィッシュリスト | Liste de souhaits par pays |
| `aso.s6.title` | 친구의 추천 | Friends' picks | Friends' picks | Freunde-Empfehlungen | 友達のおすすめ | Choix des amis |
| `aso.s7.title` | 발견 · 기록 · 도감 | Discover · Record · Collect | Discover · Record · Collect | Entdecken · Aufzeichnen · Sammeln | 発見・記録・図鑑 | Découvrir · Noter · Collecter |

> 독일어가 가장 길어질 가능성 높음 — 슬롯 1 헤드라인 박스 폭은 독일어 기준으로 검증(`qa-localization`).

---

## 5. 출력 위치

| 결과물 | 경로 |
|---|---|
| 키비주얼 SVG 마스터 (1290×2796) | `_design_assets/svg/marketing/keyvisual-cup-leaf.svg` (B 채택 후속에서 작성) |
| 슬롯별 PNG (자동 생성) | `fastlane/screenshots/{ko,en-US,en-GB,de-DE,ja,fr-FR}/iPhone-67/` |
| 메타데이터 (제목/설명/whatsnew) | `fastlane/metadata/{ko,en-US,en-GB,de-DE,ja,fr-FR}/` |

---

## 6. 검증 체크리스트

`qa-localization` + `qa-functional` 사인오프 조건:

- [ ] 슬롯 1과 7에 컵+잎 컴포지션이 명시 노출되었는가.
- [ ] 모든 슬롯에서 잎 vein 6개 시그니처 패턴이 일치하는가 (시각 회귀 diff).
- [ ] 6개 언어 모두 빈 카피 키 0건 (`String Catalog`).
- [ ] 독일어 헤드라인이 슬롯 박스 폭을 넘지 않는가.
- [ ] 앱 아이콘 B와 키비주얼의 잎 모양/색이 동일 시그니처인가.
- [ ] 광고 슬롯/AdMob 배너 노출 0건.
- [ ] 개인 식별 정보(임의 닉네임/얼굴 사진) 노출 0건.

---

## 7. 후속 작업 (다음 단계)

1. `_design_assets/svg/marketing/keyvisual-cup-leaf.svg` 마스터 작성 — Phase 2 진입 직전 또는 ios-store 매장 상세 화면 시안 동결 후.
2. fastlane `screenshots` lane 작성 — `ios-lead` + `qa-functional` 협업.
3. `aso.xcstrings` 키 카탈로그 — `qa-localization`이 6개 언어 카탈로그에 키 일괄 등록.
4. App Store Connect 메타데이터 디렉토리(`fastlane/metadata/`) 생성 + 카피 적재 — `po-growth` 협업.

---

## 8. Changelog

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-04 | 초안 — 컵+잎 키비주얼 정책 + 10 슬롯 구성 + 6개 언어 카피 매트릭스 + vein 시그니처 동결 | designer-icon (po-lead 사인오프 대기) |

---

생성: 2026-05-04 · Owner: `designer-icon`
