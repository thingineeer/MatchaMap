# Localization Policy — 6 Languages

> 6개 언어 String Catalog 길이 정책 + 가장 긴 카피(독일어/프랑스어) 기준 레이아웃 검증 룰.
> RTL은 v1.0.0 비범위(PRD §9). 언어 확장 시 재논의.

소유: `designer-lead` 책임 / `qa-localization` 회귀 / `po-lead` 사인오프.

---

## 1. 대상 언어 (PRD §6 / §7)

| code | 시장 | iOS region | String Catalog 우선순위 | 비고 |
|---|---|---|---|---|
| `ko` | KR | ko-KR | 1차 (소스) | 한국어가 작업 소스. 다른 언어는 번역. |
| `en-US` | US | en-US | 2차 | 영어 fallback (en-GB 미지원 디바이스) |
| `en-GB` | UK | en-GB | 3차 | en-US와 차이: 단어 (color → colour, dollar → pound, "store hours" 등) |
| `de-DE` | DE | de-DE | 4차 | **가장 긴 카피의 기준 언어** (레이아웃 검증) |
| `ja` | JP | ja-JP | 5차 | 한자/가타카나 혼용. 줄바꿈 규칙 다름. |
| `fr-FR` | FR | fr-FR | 6차 | 두 번째로 긴 언어. 액센트 문자 (à/é/ç) |

**소스 언어 = ko**. 모든 키는 한국어로 먼저 작성 → 번역가 패스. `qa-localization`이 누락 키 0 회귀.

---

## 2. 길이 비율 (한국어 대비 추정)

`po-growth` 시장조사 + 일반 i18n 통계 기반:

| 언어 | 평균 길이 비율 | 최악 케이스 | 비고 |
|---|---|---|---|
| ko | 1.00 | 1.00 | 기준 |
| en-US | 1.20~1.40 | 1.50 | 단어가 더 김 (복수형, 관사) |
| en-GB | 1.25~1.40 | 1.50 | en-US와 거의 동일 |
| de-DE | 1.40~1.80 | **2.00** | 합성어 ("Wunschliste", "Tee-Erlebnis") |
| ja | 0.90~1.10 | 1.20 | 가타카나 사용 시 늘어남 |
| fr-FR | 1.30~1.60 | 1.80 | 관사/연결어 ("de la", "à l'") |

**레이아웃 설계 기준**: 모든 카피는 **ko × 1.5** 길이 가정해서 max-width 결정. 독일어 worst-case 빌드에서 추가 검증.

---

## 3. 컴포넌트별 max-width 정책

### 3.1 텍스트 컴포넌트

| 컴포넌트 | 토큰 | max chars (ko) | max chars (en/de/fr) | 줄 수 | 행동(over) |
|---|---|---|---|---|---|
| Display 40pt (Splash 로고) | `MMTypography.display` | 4 | 9 | 1 | 28pt downscale (NSK Bold) |
| Title1 32pt (로그인 헤드라인) | `MMTypography.title1` | 8/줄 | 18/줄 | 2 | 26pt downscale + lineLimit 3 허용 |
| Title2 26pt (위치권한, 매장명 hero) | `MMTypography.title2` | 10/줄 | 22/줄 | 2 | 22pt downscale + minimumScaleFactor 0.85 |
| Headline 22pt (매장 미리보기, 피드 헤더) | `MMTypography.headline` | 12/줄 | 24/줄 | 1~2 | minimumScaleFactor 0.85 |
| Body 14pt (단락) | `MMTypography.body` | 무제한 | 무제한 | 무제한 | minimumScaleFactor 0.95 |
| Callout 13pt (리뷰 본문) | `MMTypography.callout` | 무제한 | 무제한 | 무제한 | 동상 |
| Subhead 12pt (UI 라벨) | `MMTypography.subhead` | 12 | 26 | 1 | truncate ellipsis tail |
| Footnote 11pt (작은 메타) | `MMTypography.footnote` | 14 | 30 | 1 | truncate |
| Caption 10pt (탭바, 미니 메타) | `MMTypography.caption` | 6 | 12 | 1 | truncate / 약어 |

### 3.2 인터랙티브 컴포넌트

| 컴포넌트 | max chars (ko) | max chars (de) | 행동(over) |
|---|---|---|---|
| TabBar2 라벨 (10pt) | 5 | 6 | de "Wunschliste" → "Liste" 약어 사용 |
| Chip label (12pt) | 8 | 14 | truncate ellipsis tail |
| PrimaryButton title (height 54, 15pt) | 8 | 22 | minimumScaleFactor 0.9 → short-form 카피 |
| PrimaryButton compact (height 36, 12pt) | 6 | 14 | 동상 |
| SecondaryButton (15pt) | 8 | 20 | 동상 |
| Quick action grid label (10pt) | 4 | 8 | 약어 (예: "웹사이트" → "Site") |

### 3.3 카드 / 리스트

| 컴포넌트 | 필드 | 정책 |
|---|---|---|
| StoreCard (모든 variant) | 매장명 | lineLimit 2, minimumScaleFactor 0.9, .truncationMode(.tail) |
| StoreCard | 위치 | lineLimit 1, truncate |
| ReviewCard | title | lineLimit 1, truncate |
| ReviewCard | body | lineLimit 4 (default) → "더보기" expand |
| FeedPostCard | body | lineLimit 5 → "더보기" expand |
| Wishlist row | 매장명 | lineLimit 1, truncate |
| Wishlist row | 메모 | lineLimit 1, italic |

---

## 4. 줄바꿈 정책

### 4.1 강제 줄바꿈 사용 케이스 (`\n`)

다음 화면에서만 String Catalog의 `\n` 사용:

| 화면 / 컴포넌트 | 카피 예 | 사유 |
|---|---|---|
| Splash 부제 | `세상의 말차를\n한 잔씩 모아두는 곳` | 디자인 의도 (시각 정렬) |
| Login 헤드라인 | `말차맵에\n오신 걸 환영해요` | 디자인 의도 |
| Login 부제 | `로그인하면 마신 말차와 위시리스트를\n모든 기기에서 동기화할 수 있어요.` | 가독성 |
| Location 헤드라인 | `주변의 말차를\n발견하세요` | 디자인 의도 |
| World map StatHero | `전 세계 1,847개 매장에서\n말차가 우려지고 있어요` | 디자인 의도 |
| ATT prompt 부제 | `광고 식별자 사용에 동의하시면\n더 관련성 높은 광고를 볼 수 있어요.` | 가독성 |

> 위 카피들은 6개 언어 *각각* 줄바꿈 위치를 번역가가 결정. ko의 `\n` 위치를 그대로 복사하지 않음. `qa-localization`이 5개 언어로 화면 캡처 후 줄바꿈 위치 적절성 검수.

### 4.2 자연 줄바꿈 (default)

위 6개 외 모든 텍스트는 **`\n` 사용 금지**. SwiftUI `.lineLimit(n)` + `.multilineTextAlignment(.leading)`로 자연 흐름 처리.

### 4.3 단어 단위 줄바꿈 (de/ja 특수)

- **de**: 합성어가 매우 길면 SwiftUI 기본은 단어 끝에서 줄바꿈. 예: "Wunschlisten-Eintrag" 한 줄 안에 못 넣으면 통째로 다음 줄. CSS `hyphens: auto`처럼 `MMTypography` 단계에서 자동 하이픈은 미적용 (가독성 우선).
- **ja**: 일본어는 단어 경계가 모호. SwiftUI `Text`의 기본 줄바꿈 정책 (`.lineBreakMode(.byCharWrapping)` 등) 사용 — 한자 중간에서도 줄바꿈 OK. 단, 헤드라인은 의미 단위 잘리지 않도록 `qa-localization` 검수.

---

## 5. 약어 / 단축형 사전 (de / fr)

> `qa-localization`이 본 사전을 SSOT로 관리. 디자인 단계에서 본 사전 외 약어 사용 시 합의 필요.

### 5.1 TabBar / 메뉴 라벨

| 의미 | ko | en | de full | de **short** (사용) | fr full | fr **short** (사용) |
|---|---|---|---|---|---|---|
| 지도 | 지도 | Map | Karte | **Karte** | Carte | **Carte** |
| 피드 | 피드 | Feed | Feed | **Feed** | Fil | **Fil** |
| 위시리스트 | 위시리스트 | Wishlist | Wunschliste | **Liste** | Liste de souhaits | **Liste** |
| 내정보 | 내정보 | Me | Profil | **Profil** | Profil | **Profil** |

### 5.2 빠른 액션 라벨 (Quick action grid, 10pt)

| 의미 | ko | en | de | fr |
|---|---|---|---|---|
| 길찾기 | 길찾기 | Route | Route | Route |
| 전화 | 전화 | Call | Anruf | Appel |
| 웹사이트 | 웹사이트 | Web | Web | Web |
| 공유 | 공유 | Share | Teilen | Partager |

### 5.3 Section 라벨 (긴 형태 사용 가능)

| 의미 | ko | en | de | fr |
|---|---|---|---|---|
| 위시리스트 (페이지 헤더) | 위시리스트 | Wishlist | Wunschliste | Liste de souhaits |
| 가고 싶은 매장 | 가고 싶은 매장 | Want to visit | Möchte besuchen | À visiter |
| 마신 말차 | 마신 말차 | Tasted | Probiert | Dégusté |

> Tab은 항상 **short**, Section은 **full**. 일관성을 위해 String Catalog에 별도 키 (`tab.wishlist`, `section.wishlist`).

---

## 6. 다국어 데이터 표기

### 6.1 매장명

- 일본어 매장은 한자/히라가나 원본 + 영문 transliteration 병기. 예: `宇治園 시부야 / Ujien Shibuya`.
- 한국어 매장은 한글 원본 + 영문 transliteration. 예: `다실 안국 / Dasil Anguk`.
- 표기 정책: **현지 표기 우선**, transliteration 보조. 사용자 locale `ja`인 경우 한자만 표기.

### 6.2 통화 / 가격대

| locale | 가격대 표기 |
|---|---|
| ko | ₩ / ₩₩ / ₩₩₩ / ₩₩₩₩ |
| en-US | $ / $$ / $$$ / $$$$ |
| en-GB | £ / £££ |
| de-DE | € |
| ja | ¥ / ¥¥ |
| fr-FR | € |

> 매장 데이터의 price-tier는 1~4 정수. UI 렌더 시 locale별 기호 매핑 (`server-data` 스키마).

### 6.3 거리

- locale `en-US` / `en-GB`: mile 사용 (선택, MVP는 km 단일 사용).
- 그 외: km 사용 (소수 1자리, 100m 미만은 m 사용).

### 6.4 시간 표기 (영업시간)

- locale `en-US` / `en-GB`: 12시간 표기 (9:00 PM).
- 그 외: 24시간 표기 (21:00).
- "영업중" / "영업 종료" / "곧 마감" 라벨은 locale별 카피.

### 6.5 별점 → 카피 매핑

`screens.md § 4.4`의 5단계 매핑 (1~5점 → 별로예요/그저그래요/괜찮아요/좋아요/완벽해요!) 6개 언어 String Catalog에 등록.

### 6.6 상대 시간 (피드 / 리뷰)

iOS `RelativeDateTimeFormatter` 사용. locale 자동 매핑 (`2시간 전` / `2 hours ago` / `vor 2 Stunden` / `il y a 2 heures` / `2時間前`).

---

## 7. ATT / GDPR / 광고 카피 다국어

### 7.1 ATT 시스템 다이얼로그 보조 카피 (Info.plist `NSUserTrackingUsageDescription`)

| locale | 카피 (max 200 chars) |
|---|---|
| ko | 더 관련성 높은 광고를 보여드리기 위해 광고 식별자를 사용해요. 거부해도 앱은 정상 사용 가능합니다. |
| en | We use the advertising identifier to show you more relevant ads. You can decline and still use the app normally. |
| de | Wir nutzen die Werbe-ID, um Ihnen relevantere Anzeigen zu zeigen. Sie können ablehnen und die App weiter normal nutzen. |
| ja | より関連性の高い広告を表示するために、広告識別子を使用します。拒否してもアプリは正常にご利用いただけます。 |
| fr | Nous utilisons l'identifiant publicitaire pour vous montrer des publicités plus pertinentes. Vous pouvez refuser et continuer à utiliser l'app normalement. |

### 7.2 GDPR UMP 동의 카피

`UMP SDK` 자체 카피 사용 + 본 앱 카피 보조. EU 5국(de-DE / fr-FR / en-GB) 필수.

### 7.3 광고 disclosure 라벨

배너 좌상단 mono 라벨:
- ko: `광고`
- en: `Ad`
- de: `Anzeige`
- ja: `広告`
- fr: `Publicité` (max 4 chars 권장 → `Pub`로 단축)

---

## 8. 폰트 / 글자 메트릭

### 8.1 Pretendard 다국어 fallback

| locale | 1차 | 2차 |
|---|---|---|
| ko | Pretendard | Apple SD Gothic Neo |
| en-US/en-GB | Pretendard | -apple-system (SF Pro) |
| de-DE | Pretendard | -apple-system (SF Pro) |
| ja | Hiragino Sans | -apple-system (SF Pro) |
| fr-FR | Pretendard | -apple-system (SF Pro) |

> Pretendard는 라틴/한글 cover. 일본어는 Hiragino Sans 우선 (시스템 기본). `MMTypography` 정의 시 `.subheadline`처럼 OS-relative font 사용 옵션 검토.

### 8.2 Noto Serif KR (디스플레이 폰트)

- ko / ja / zh: Noto Serif KR 또는 Noto Serif JP / TC.
- en/de/fr: serif fallback (`Times New Roman` → 시스템).
- 디스플레이 폰트는 **로고 / Splash / 매장명 hero**에서만 사용. 기본 UI는 Pretendard.

### 8.3 IBM Plex Mono (mono 라벨)

- 모든 locale 동일 사용. mono 라벨은 영어/숫자 전용 (`EST. 2025`, `1,847 PINS` 등).
- 한국어/일본어 mono 라벨은 사용 금지 (가독성 저하). `qa-localization` 회귀.

---

## 9. 검증 / 회귀 절차 (`qa-localization`)

### 9.1 자동화

1. **String Catalog 무결성**: 누락 키 0건. CI에서 `xcrun stringsdict-validate` 또는 동등 검증.
2. **길이 회귀**: 모든 키의 ko 길이 × 2.0 vs de/fr/en 길이 비교. 초과 시 PR 차단.
3. **screenshot diff**: fastlane `snapshot` 6개 locale × 30 화면 = 180 캡처. visual diff 도구로 잘림/오버플로우 자동 검출 (Phase 5).

### 9.2 수동 회귀

- 5개 locale 시뮬레이터 빌드 후 30 화면 (screens.md) 모든 화면 점검.
- `qa-localization` 체크리스트 (별도 `docs/qa/i18n-checklist.md`):
  1. 텍스트 잘림 없음
  2. 줄바꿈 부자연 없음
  3. 약어 사용 적절
  4. 통화/거리/시간 표기 locale 일치
  5. RTL 잘못 적용 없음 (MVP는 LTR만)
  6. mono 라벨에 비라틴 문자 없음
  7. ATT/UMP 카피 표시
  8. 별점 카피 매핑 정확

### 9.3 결함 보고 채널

`qa-localization` → `designer-lead` SendMessage. designer-lead가 short-form 카피 또는 디자인 수정으로 대응 (`agents/designer-lead.md` § 에러 핸들링).

---

## 10. RTL — v1.0.0 비범위 (PRD §9)

- 아랍어/히브리어/페르시아어 6개 언어에 포함되지 않음.
- v1.x 언어 확장 시 재논의 — 추가 ADR `docs/architecture/ADR-XXX-rtl-support.md` 필요.
- 현재 SwiftUI 코드는 `.environment(\.layoutDirection, .leftToRight)` 강제 권장 (`ios-lead` 결정).

---

## 11. 변경 이력

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-04 | 초안 작성 (6 languages × 9 modules max-width policy + 약어 사전 + ATT/광고 카피) | designer-lead |

---

References:
- PRD `docs/product/PRD.md` § 6 비기능 (다국어 6개 언어, RTL 비범위)
- 디자인 토큰 `docs/design/design-system.md` § 7 다국어 길이 정책 (요약)
- 화면 매트릭스 `docs/design/screens.md` § 12 검수 기준
- 컴포넌트 `docs/design/components.md` § 10 다국어 max-width
- QA `docs/qa/i18n-checklist.md` (qa-localization이 작성 예정)
