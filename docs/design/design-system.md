# MatchaMap Design System (MM2)

> **정전(canon)**: `_handoff/matchamap/project/MatchaMap v2.html` + `mm-shared-v2.jsx` + `mm-screens-v2.jsx` + `styles.css`. v1 자료 폐기.
> 본 문서는 SwiftUI(`LocalPackages/DesignSystem/`)에서 강제되는 토큰의 단일 진실. **색상 리터럴 사용 금지** — 모든 색은 `Color.MM.*` 토큰을 통해서만.

소유: `designer-lead` · 리뷰: `designer-icon` / `ios-lead` · 사인오프: `po-lead`.

---

## 1. 컬러 토큰 (17개)

MM2 팔레트 = 화이트톤(여행자 친화) + 먼지 매차 + 더스티 로즈 액센트. 광고 슬롯과의 명도 충돌을 줄이기 위해 v1 진한 톤을 폐기.

### 1.1 Surface — 표면 / 배경

| 토큰 | hex | RGB | 용도 |
|---|---|---|---|
| `Color.MM.bg` | `#FBFAF7` | 251 250 247 | 화면 기본 배경 (모든 Phone2 wrapper의 기본값) |
| `Color.MM.paper` | `#FFFFFF` | 255 255 255 | 카드 / 시트 / 탭바 표면 |
| `Color.MM.cream` | `#F5F1EA` | 245 241 234 | Splash · 프로필 아바타 등 따뜻한 강조 표면 |

### 1.2 Brand — 매차 (5단계)

| 토큰 | hex | 용도 |
|---|---|---|
| `Color.MM.deep` | `#3D4A2D` | 1차 브랜드. 헤드라인 텍스트, S등급 핀 본체, 활성 탭 아이콘, primary 버튼 배경 |
| `Color.MM.matcha` | `#7A9560` | 2차 브랜드. A등급 핀, 영업중 인디케이터, 평점 분포 막대, 친구 아바타 fallback |
| `Color.MM.matchaSoft` | `#A8B994` | S핀 leaf, 점선 링 (Lottie placeholder) |
| `Color.MM.matchaPale` | `#E6ECDE` | Passkey 안내 배지 배경, 선택된 태그 배경 |
| (alias) `Color.MM.deepInk` | `#3D4A2D` | `deep` 별칭 (시매틱: 텍스트 강조 시 `deep` 그대로 사용) |

### 1.3 Accent — 더스티 로즈 (3단계)

| 토큰 | hex | 용도 |
|---|---|---|
| `Color.MM.rose` | `#C98B85` | 액센트 1. 거리 표기, 라벨("지금 이 순간"), 위시리스트 메모, 하트 fill, B등급 핀 |
| `Color.MM.rosePale` | `#F0D9D5` | 회전 점선 보조 링 |
| `Color.MM.blush` | `#E8C4C0` | 보조 강조 (피드 그라디언트 stop) |

### 1.4 Neutrals — 텍스트 / 라인

| 토큰 | hex | 용도 |
|---|---|---|
| `Color.MM.ink` | `#2A2A2A` | StatusBar2 시계 / 시스템 아이콘 (라이트 배경) |
| `Color.MM.text` | `#4A4A45` | 본문 텍스트 (body / paragraph) |
| `Color.MM.muted` | `#A39E92` | 보조 텍스트 (캡션, 메타, placeholder) |
| `Color.MM.mutedSoft` | `#C4BFB2` | (예비) 비활성 상태 텍스트 |
| `Color.MM.line` | `#EBE7DC` | 1px divider, 입력 필드 외곽선, 정렬 칩 외곽 |
| `Color.MM.lineSoft` | `#F2EFE6` | 카드 내부 분리선, 테이블 row separator |

### 1.5 Functional

| 토큰 | hex | 용도 |
|---|---|---|
| `Color.MM.gold` | `#C9A566` | 별점(`Stars`) fill |

### 1.6 의미 토큰 (Semantic Layer · 다크 모드 대비)

MVP는 라이트 단일이지만, 다크 추가 시 토큰만 갈아끼우면 되도록 별도 레이어 정의.

| 의미 토큰 | 라이트 매핑 | 비고 |
|---|---|---|
| `Color.MM.surface` | `bg` | 루트 배경 |
| `Color.MM.surfaceElevated` | `paper` | 카드 / 시트 |
| `Color.MM.surfaceMuted` | `cream` | 강조 surface |
| `Color.MM.textPrimary` | `deep` | 헤드라인 |
| `Color.MM.textBody` | `text` | 본문 |
| `Color.MM.textMuted` | `muted` | 캡션 |
| `Color.MM.divider` | `line` | 1차 구분선 |
| `Color.MM.dividerSoft` | `lineSoft` | 2차 구분선 |
| `Color.MM.accent` | `rose` | 액센트 |
| `Color.MM.brand` | `deep` | 브랜드 1차 |
| `Color.MM.brandSecondary` | `matcha` | 브랜드 2차 |

> 구현 시 두 레이어 모두 `Color.MM` enum 안에 nested. 화면은 의미 토큰을, 컴포넌트는 hex 토큰을 사용.

### 1.7 등급별 매핑 표 (S/A/B/C)

| 등급 | Pin 본체 | Pin Leaf | Chip 배경 | Chip 글자 |
|---|---|---|---|---|
| S | `deep` | `matchaSoft` | `deep` | `paper` |
| A | `matcha` | `cream` | `matcha` | `paper` |
| B | `rose` | `paper` | `rose` | `paper` |
| C | `paper` | `matcha` | `cream` | `deep` |

### 1.8 접근성 (WCAG AA)

- 본문 `text(#4A4A45)` on `bg(#FBFAF7)` ≈ 9.3:1 — AAA pass.
- `muted(#A39E92)` on `bg` ≈ 2.8:1 — **AA fail**. 캡션/메타에만 사용, 본문 절대 금지. 14pt 이하에서만 허용.
- `deep(#3D4A2D)` on `paper(#FFFFFF)` ≈ 9.0:1 — AAA pass.
- `rose(#C98B85)` on `paper` ≈ 3.4:1 — **AA fail (small text)**. 대형 텍스트(18pt+ bold) / 아이콘 / 데코에만 사용.
- `gold(#C9A566)` on `paper` ≈ 2.7:1 — 텍스트 사용 금지. 별 아이콘 fill 전용.

→ `qa-localization`이 색대비 회귀에서 위 룰 강제.

---

## 2. 타이포그래피

### 2.1 폰트 스택

| 시매틱 폰트 | 실제 스택 | 용도 |
|---|---|---|
| Display | `Noto Serif KR` → `Apple SD Gothic Neo` → serif | 화면 헤드라인 (말차맵 / 매장 이름 / 통계 숫자) |
| Sans (Body) | `Pretendard` → `-apple-system` → `system-ui` → sans-serif | 본문 / UI 라벨 / 버튼 |
| Mono | `IBM Plex Mono` → `SF Mono` → monospace | 거리/카운트/메타라벨 (대문자 + letterSpacing 0.15~0.3em) |

### 2.2 사이즈 스케일 9단계 (Pretendard 기준)

| Token | size | line-height | weight | letter-spacing | 용도 (정전 출처) |
|---|---|---|---|---|---|
| `MMTypography.display` | 40 | 1.2 (48) | 700 | -0.02em | Splash "말차맵" (mm-screens-v2:17) |
| `MMTypography.title1` | 32 | 1.2 (38) | 700 | -0.01em | 로그인 헤드라인 "말차맵에 오신 걸 환영해요" (line 42) |
| `MMTypography.title2` | 26 | 1.3 (34) | 700 | -0.01em | 위치권한 "주변의 말차를 발견하세요" (line 113), 매장 상세 매장명 (line 316) |
| `MMTypography.headline` | 22 | 1.2 (26) | 700 | 0 | 매장 미리보기 매장명 (line 268), 피드/위시리스트 헤더 |
| `MMTypography.body` | 14 | 1.6 (22) | 400 | 0 | 본문 단락 (로그인 부제, 매장 소개 등) |
| `MMTypography.callout` | 13 | 1.7 (22) | 500 | 0 | 리뷰 본문, 영업 상태 |
| `MMTypography.subhead` | 12 | 1.5 (18) | 500/600 | 0 | UI 라벨, 칩 텍스트, 거리/메타 |
| `MMTypography.footnote` | 11 | 1.5 (16) | 500 | 0 | 작은 메타 (카운트, 부가설명) |
| `MMTypography.caption` | 10 | 1.4 (14) | 500 | 0 | 탭바 라벨, 미니 메타 |

### 2.3 모노 라벨 (특수)

| Token | size | weight | letter-spacing | text-transform | 용도 |
|---|---|---|---|---|---|
| `MMTypography.monoLabel` | 9–11 | 400/500 | 0.15–0.30em | uppercase | "EST. 2025 · KYOTO", "LOTTIE · ...", 거리 km, 카운트 |

### 2.4 디스플레이 숫자 (스탯 hero)

프로필/지도 통계의 큰 숫자(`28`, `1,847`, `4.8`)는 **Noto Serif KR / 22~44pt / 700 / line-height 1**. 별도 토큰: `MMTypography.statNumber`.

### 2.5 SwiftUI 매핑 (Dynamic Type relativeTo SSOT)

> 본 표는 **Dynamic Type relativeTo 매핑 SSOT** (po-lead 권고 #2 / ios-lead 위임 2026-05-04). 본 매핑이 PR 단계 .coderabbit.yaml DesignSystem path 룰에서 인용됨.
> 사이즈 값은 v2 시안 기준(`mm-screens-v2.jsx`). Apple HIG 기본값(body 17pt 등)과 다르나 정전 우선.

#### Dynamic Type 매핑 표

| MMTypography 토큰 | base size | weight | relativeTo (Dynamic Type) | 용도 |
|---|---|---|---|---|
| `display` | 40 | 700 (Bold) | `.largeTitle` | Splash 로고 헤드라인 |
| `title1` | 32 | 700 (Bold) | `.title` | 로그인 헤드라인 |
| `title2` | 26 | 700 (Bold) | `.title2` | 위치권한, 매장 상세 매장명 hero |
| `headline` | 22 | 700 (Bold) | `.title3` | 매장 미리보기, 피드/위시리스트 헤더 |
| `body` | 14 | 400 (Regular) | `.body` | 본문 단락 (가독성 기준) |
| `callout` | 13 | 500 (Medium) | `.callout` | 리뷰 본문, 영업 상태 |
| `subhead` | 12 | 500/600 | `.subheadline` | UI 라벨, 칩 텍스트, 거리/메타 |
| `footnote` | 11 | 500 (Medium) | `.footnote` | 작은 메타 (카운트, 부가설명) |
| `caption` | 10 | 500 (Medium) | `.caption` | 탭바 라벨, 미니 메타 |
| `monoLabel` | 10 | 400/500 | `.caption2` | 모노 라벨 (대문자 + letterSpacing) |
| `statNumber` | 28 | 700 (Bold) | `.largeTitle` | StatHero 큰 숫자 |

#### SwiftUI 코드

```swift
public enum MMTypography {
    public static let display    = Font.custom("NotoSerifKR-Bold",   size: 40, relativeTo: .largeTitle)
    public static let title1     = Font.custom("NotoSerifKR-Bold",   size: 32, relativeTo: .title)
    public static let title2     = Font.custom("NotoSerifKR-Bold",   size: 26, relativeTo: .title2)
    public static let headline   = Font.custom("NotoSerifKR-Bold",   size: 22, relativeTo: .title3)
    public static let body       = Font.custom("Pretendard-Regular", size: 14, relativeTo: .body)
    public static let callout    = Font.custom("Pretendard-Medium",  size: 13, relativeTo: .callout)
    public static let subhead    = Font.custom("Pretendard-Medium",  size: 12, relativeTo: .subheadline)
    public static let footnote   = Font.custom("Pretendard-Medium",  size: 11, relativeTo: .footnote)
    public static let caption    = Font.custom("Pretendard-Medium",  size: 10, relativeTo: .caption)
    public static let monoLabel  = Font.custom("IBMPlexMono-Regular", size: 10, relativeTo: .caption2)
    public static let statNumber = Font.custom("NotoSerifKR-Bold",   size: 28, relativeTo: .largeTitle)
}
```

#### 룰

1. **`Font.system(size:)` 직접 사용 금지** — `.coderabbit.yaml` PR 차단 룰에 등록됨.
2. **`Font.custom(_:size:)` (relativeTo 누락) 사용 금지** — Dynamic Type 비호환. 항상 `relativeTo:` 명시.
3. **`MMTypography.*` 통해서만 사용** — 위 enum 외 폰트 정의 PR 차단.
4. **AX1 이상 (Larger Layout 모드)** — `accessibility.md` § 3.3 6개 룰 적용.

#### relativeTo 선택 사유 (디자인 vs HIG 절충)

- **`headline` → `.title3`**: 22pt → 본 토큰은 매장 미리보기/피드 헤더 등 hero 다음 강조. `.title3`(20pt 기본) relativeTo가 AX 모드 확대 비율 가장 자연. `.headline`(17pt)은 본문 강조용으로 너무 작음.
- **`body` → `.body`**: 14pt → 본 토큰은 v2 시안 본문 단락 표준. Apple HIG `.body` (17pt)보다 작으나 정전 우선. AX 모드 확대 시 `.body` relativeTo가 가독성 보장.
- **`subhead` → `.subheadline`**: 12pt → UI 라벨 표준. relativeTo `.subheadline`은 13pt 기본이라 base 12pt보다 살짝 큼 — 의도. AX 모드 확대 시 적절히 stretch.
- **`monoLabel` → `.caption2`**: 10pt → 가장 작은 텍스트 (uppercase + letterSpacing). `.caption2` (11pt) relativeTo가 AX 모드에서 가장 보수적 확대.

> `LOCALIZATION_PREFERS_STRING_CATALOGS = YES` 환경에서 텍스트는 모두 String Catalog 통해 주입.

---

## 3. 스페이싱 (8-point grid)

### 3.1 토큰 (8단계)

| Token | px | 용도 |
|---|---|---|
| `MMSpacing.xxs` | 4 | 아이콘과 라벨 사이 (탭바 gap=3은 예외) |
| `MMSpacing.xs` | 8 | 카드 안 인접 요소, 그라디언트 stop 간격 |
| `MMSpacing.sm` | 12 | 카드 내부 인접 그룹, 칩 간 gap |
| `MMSpacing.md` | 16 | 화면 좌우 padding 기본값, 카드 내부 padding |
| `MMSpacing.lg` | 20 | 헤더/본문 padding (매장 상세, 프로필) |
| `MMSpacing.xl` | 24 | 큰 시각 분리, 헤더 ↔ 본문 |
| `MMSpacing.xxl` | 32 | 섹션 분리 |
| `MMSpacing.xxxl` | 48 | hero ↔ CTA |

### 3.2 화면 그리드 베이스라인

- **Phone2 frame**: 390 × 844 (iPhone 14/15 기준).
- **safe area top**: StatusBar2 = 54pt.
- **safe area bottom**: TabBar2 padding-bottom = 28pt + content 8pt + content area = 56pt 총 높이. HomeIndicator2 = 약 13pt.
- **수평 padding 표준**: 16pt (화면 본문) / 20pt (밀도 낮은 화면 — 매장 상세, 프로필).
- **카드 corner-margin**: 외부 16pt, 내부 padding 12~16pt.

---

## 4. 라운드 (Corner Radius)

| Token | px | 용도 |
|---|---|---|
| `MMRadius.xs` | 4 | GradeChip, 미니 블록 |
| `MMRadius.sm` | 8 | 미니 카드, 작은 photo (48 이하) |
| `MMRadius.md` | 10 | 일반 photo (60~80) |
| `MMRadius.lg` | 12 | 카드 내부 박스 (속성 / 영업시간 / 입력 필드) |
| `MMRadius.xl` | 14 | 검색바, 매장 미리보기 카드 헤더 |
| `MMRadius.xxl` | 16 | 큰 카드, 통계 hero, 매장 상세 mini-map |
| `MMRadius.xxxl` | 18 | 매장 미리보기 floating 카드 |
| `MMRadius.pill` | 28 | 버튼 (height 54~56), 라운드 풀 |
| `MMRadius.full` | .infinity | 아바타, 점, FAB |

---

## 5. 그림자 (Shadows)

iOS와 CSS의 그림자 모델이 다르므로 SwiftUI 측은 단일 `.shadow(color:radius:x:y:)`로 단순화.

| Token | color | radius | y | 용도 (정전 출처) |
|---|---|---|---|---|
| `MMShadow.small` | `black @ 4%` | 4 | 2 | 칩 / 정렬 옵션 (`0 2px 4px rgba(0,0,0,0.04)`) |
| `MMShadow.medium` | `black @ 6%` | 8 | 4 | 검색바, 카드 (`0 4px 12~16px rgba(0,0,0,0.06)`) |
| `MMShadow.large` | `black @ 8%` | 12 | 8 | 통계 banner (`0 8px 20px rgba(0,0,0,0.06)`) |
| `MMShadow.float` | `black @ 10%` | 16 | 12 | floating 카드 (매장 미리보기) |
| `MMShadow.pin` | `deep @ 18%` | 6 | 3 | MatchaPin drop-shadow |

```swift
public enum MMShadow {
    public static let small  = Shadow(color: Color.black.opacity(0.04), radius: 4,  x: 0, y: 2)
    public static let medium = Shadow(color: Color.black.opacity(0.06), radius: 8,  x: 0, y: 4)
    public static let large  = Shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 8)
    public static let float  = Shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 12)
    public static let pin    = Shadow(color: Color.MM.deep.opacity(0.18), radius: 6, x: 0, y: 3)
}
```

> 백드롭 블러(`backdropFilter: blur(20px)`)는 SwiftUI에서 `.background(.ultraThinMaterial)`로 매핑. 정전의 `rgba(255,255,255,0.96) + blur(20)` 조합은 `Color.MM.paper.opacity(0.96).background(.ultraThinMaterial)`.

---

## 6. 모션 / 애니메이션

| Token | curve | duration | 용도 |
|---|---|---|---|
| `MMMotion.fast` | easeOut | 150ms | 아이콘 토글 (heart, bookmark) |
| `MMMotion.standard` | easeOut | 250ms | 시트 / 모달 열림, 칩 전환 |
| `MMMotion.slow` | easeInOut | 400ms | 화면 전환 |
| `MMMotion.spring` | spring(response:0.45, damping:0.8) | — | Sheet drag, 위시리스트 추가 |
| `MMMotion.pulse` | linear infinite | 2000ms | MatchaPin glow (S 등급 강조) |
| `MMMotion.rotate` | linear infinite | 18000ms (forward) / 12000ms (reverse) | Lottie placeholder 점선 링 |
| `MMMotion.blink` | step | 1000ms | 텍스트 입력 커서 (리뷰 작성) |

### 6.1 SwiftUI 매핑

```swift
public enum MMMotion {
    public static let fast     = Animation.easeOut(duration: 0.15)
    public static let standard = Animation.easeOut(duration: 0.25)
    public static let slow     = Animation.easeInOut(duration: 0.40)
    public static let spring   = Animation.spring(response: 0.45, dampingFraction: 0.8)
}
```

> Lottie 자체 애니메이션(위치권한 화면)은 별도 자산. `designer-icon`이 mp4/json 명세 책임.

---

## 7. 다국어 길이 정책 (6개 언어)

대상: ko / en-US / en-GB / de-DE / ja / fr-FR.

### 7.1 카피 max-width 룰

| 컴포넌트 | 최대 줄 수 | 폰트 / 사이즈 | 줄바꿈 정책 |
|---|---|---|---|
| Display(40pt, Splash) | 1줄 | Noto Serif KR Bold | 4글자 이내 ko / 9글자 이내 en — 초과 시 28pt로 다운 |
| Title1(32pt, 로그인) | 2줄 | NSK Bold | 줄당 ko 8자 / en 18자 / de 22자. 초과 시 26pt로 다운 |
| Title2(26pt) | 2줄 | NSK Bold | 줄당 ko 10자 / en 22자 / de 26자 |
| Body(14pt) | 무제한 | Pretendard | minimumScaleFactor 0.9 |
| Button label(15pt) | 1줄 | Pretendard SemiBold | ko 8자 / en 18자 / de 22자. 초과 시 short-form 카피 |
| Tab label(10pt) | 1줄 | Pretendard Medium | de "Wunschliste" → 약어 "Wunsch" 또는 "Liste" 사용. **`qa-localization`이 단어별 변형 사전 관리** |

### 7.2 위시리스트 탭 라벨 권장 (de-DE / fr-FR)

| 화면 | ko | en | de | fr |
|---|---|---|---|---|
| Tab (탭바, 10pt) | 위시리스트 | Wishlist | Liste | Liste |
| Section (Title1) | 위시리스트 | Wishlist | Wunschliste | Liste de souhaits |

> Tab은 항상 짧은 형, Section은 긴 형 사용. `qa-localization`이 회귀.

### 7.3 동적 줄바꿈

- 시안의 `<br/>` 강제 줄바꿈은 SwiftUI에서 **사용하지 않음** — 대신 `lineLimit(2)` + `multilineTextAlignment(.leading)`로 자연 흐름 처리.
- 단, Splash·로그인 헤드라인은 디자인 의도로 강제 줄바꿈 — String Catalog의 키 단위로 `\n` 포함하되, 길이 검증을 `qa-localization`이 회귀.

---

## 8. 광고 UI 가드 (AdMob 3슬롯 — 디자인 정책)

> 본 섹션은 PRD §6 비기능 + `docs/product/admob-slots.md` §3 정책의 *시각 구현* SSOT.
> 화면별 슬롯 배치는 `docs/design/screens.md` § 9 / `handoff-mapping.md` § 2, 컴포넌트 spec은 `components.md` § 9 참조.

### 8.1 첫 60초 광고 차단 — 시각 정책 (배너)

T0 = 앱 첫 실행 / 새 세션 시작 시각. T < T0 + 60s 동안 모든 광고 노출 차단.

배너 슬롯 placeholder는 **빈 공간 / 스켈레톤 / 숨김** 중 — 결정: **숨김 (height 0 + opacity 0)**.

| 옵션 | 채택 여부 | 사유 |
|---|---|---|
| 빈 공간 (height 50, bg `Color.MM.paper`) | ✗ | 사용자에게 "광고가 없는 자리"를 인지시켜 60초 후 광고 등장 시 인지 충격이 큼. 첫인상 부정적. |
| 스켈레톤 (shimmer) | ✗ | "뭔가 로드 중"으로 오인. 광고를 *기대하게* 만드는 시그널은 리텐션 보호 목적과 모순. |
| **숨김 (height 0)** | ✓ | T0~T+60s 콘텐츠가 전체 영역 사용. T+60s 시점에 spring fade-in 250ms로 자연 등장. 배너 유무를 인지하지 못하면 그게 최선. |

#### SwiftUI 구현 가이드

```swift
@State private var showBanner = false

var body: some View {
  VStack(spacing: 0) {
    content
    if showBanner {
      AdBannerSlot()
        .frame(height: 50)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
  }
  .task {
    let elapsed = Date().timeIntervalSince(sessionStartTime)
    let delay = max(0, 60 - elapsed)
    try? await Task.sleep(for: .seconds(delay))
    withAnimation(MMMotion.spring) { showBanner = true }
  }
}
```

#### 컨텍스트 hide (배너 일시 숨김)

T+60s 이후라도 다음 상태에서는 배너 fade-out 200ms:

| 트리거 | hide 지속 | 복귀 |
|---|---|---|
| Map Preview sheet (detent ≥ medium) 열림 | sheet 닫힐 때까지 | sheet 닫힘 + 200ms |
| 검색 입력 focus | focus 해제까지 | focus blur + 200ms |
| 키보드 표시 중 | 키보드 dismiss까지 | 키보드 hide + 200ms |
| Modal / Sheet 표시 중 | dismiss까지 | dismiss + 200ms |

### 8.2 인터스티셜 등장 정책 — 콘텐츠 우선

**결정: 콘텐츠 표시 후 N초 뒤 인터스티셜** (po-lead 사인오프).

| 옵션 | 채택 여부 | 사유 |
|---|---|---|
| 로딩 스피너 위에 인터스티셜 | ✗ | "내가 매장 상세를 보려 했는데 광고부터" → 사용자 의도 박탈. Apple 5.1.1 위반 위험. |
| 콘텐츠 표시 → N초 후 인터스티셜 | ✗ | 사용자가 콘텐츠 읽기 시작 후 광고로 끊김. 뒤늦은 박탈감. |
| **콘텐츠 표시 → 사용자가 다시 다른 액션 (백 버튼 / 다음 매장 진입) 직전에 인터스티셜** | ✓ | 콘텐츠 소비를 끝낸 시점에 노출 = 광고 보는 동안 작업 손실 0. AdMob 모범 사례. |

#### 구현 패턴

매장 상세 화면 진입 카운터 + 콘텐츠 소비 시간 측정:
1. 매장 상세 진입 → 카운터 +1.
2. 5번째 진입에서 카운터 mod 5 == 0 매치.
3. 사용자가 *back 버튼 탭* 또는 *다른 매장 핀 탭* 시점 캐치.
4. 인터스티셜 호출 → 닫힘 → 의도한 액션 (back / next) 실행.
5. 마지막 인터 닫힘 시각 Tlast 갱신. 90초 쿨다운.

#### 가드 (admob-slots.md §3.2와 정합)

- 인터스티셜 ≤ 1회/세션 P95 (PRD §6).
- 첫 60초 차단 (T < T0+60s) + 첫 화면 차단 (Splash/Login).
- 긍정 액션 직후 인터 호출 금지: 리뷰 등록 / 친구 추가 / 위시 추가 / 좋아요 / 도감 unlock 직후 90초간 인터 차단.
- 인터스티셜 닫힘 후 0.25s 콘텐츠 fade-in으로 컨텍스트 복귀 시그널.

### 8.3 보상형 광고 시각 강도 — 도감 본질 보호

`screens.md § 5.2 C3 Locked Card` 보상형 sheet의 시각적 강도 룰. PRD §3-5 도감의 본질 = "수집욕"이므로 광고 CTA가 그 본질을 압도해서는 안 됨.

#### 시각 비중 (sheet 안 영역 비율)

| 영역 | 권장 비율 | 사유 |
|---|---|---|
| Headline + 본문 (도감 unlock 의미) | 50% | "광고 보고 *도감 카드 unlock*" — 명사가 핵심 |
| 잠금 → 잎 모핑 illustration | 25% | 보상의 *시각화*. unlock 후 reveal 미리보기 |
| 보상형 광고 CTA 버튼 | 15% | PrimaryButton, 주황/빨강 강조색 사용 금지 — `Color.MM.deep` 단일 |
| 닫기 / 쿨다운 footer | 10% | 부담 없음 |

#### 색·타이포 룰

- CTA 버튼 텍스트 "**광고 시청 시작**" — 광고가 강조어. 단, 텍스트 weight 600 / 사이즈 15pt **표준**으로 유지. 24pt+ 또는 weight 800 **금지** (도박앱식 강도).
- 잠금 카드 자체는 `Color.MM.cream` blur로 처리 → 사용자가 *원하는 카드를 본인이 선택해서* unlock하는 시각 흐름 유지.
- 보상형 닫기는 시스템 sheet handle drag로 항상 가능 (탈출 가능성 보장).

#### 안티패턴 (사용 금지)

- ❌ 풀스크린 모달 + 닫기 버튼 숨김 / 5초 후 표시 — 도박앱 패턴.
- ❌ 깜빡이는 CTA (`MMMotion.pulse` 사용 금지).
- ❌ "지금 안 보면 카드 못 받아요" 류 손실회피 카피.
- ❌ 보상형 시청 후 *자동* 다른 카드 unlock 제안 — 사용자가 능동적 선택해야 함.

### 8.4 ATT / GDPR 시각 가드

`screens.md § 9.2 M1 ATT Prompt 안내`의 시각 구현 룰:

- ATT 시스템 다이얼로그 *직전* in-app 안내 화면 = `Color.MM.bg` 배경, illustration 120×120, 본문 80자 내외.
- 두 CTA: `PrimaryButton(.fullWidth)` 동의 + `GhostButton` 비공개 — **둘의 시각 비중이 명확히 차별화**되되 비공개 옵션이 *숨겨지지 않음*. 비공개 버튼 fg `Color.MM.muted`는 가독성 OK (12pt 이상이면 AA pass).
- 다국어 카피 한도: ko 80자 / en 120자 / de 150자 (`localization-policy.md § 7.1`).

### 8.5 광고 disclosure 라벨 (Apple 5.1.1 / GDPR 광고 식별)

배너 좌상단 mono 라벨 — 디자인 시스템에서 강제:

| 위치 | 텍스트 (locale별) | 토큰 |
|---|---|---|
| 배너 슬롯 좌상단 inset 6pt | ko `광고` / en `Ad` / de `Anzeige` / ja `広告` / fr `Pub` | `MMTypography.monoLabel` (10pt) `Color.MM.muted` |
| 인터스티셜 | (시스템 GMS SDK 자체 처리) | — |
| 보상형 sheet 헤더 | "광고 후 보상" 안내 텍스트 (10pt mono) | 동상 |

> 디자인 시스템 토큰으로 강제하므로 `ios-auth-monetize`가 슬롯 컴포넌트 내부에 항상 포함. 미포함 시 PR 차단.

### 8.6 광고 슬롯 색·격리

광고 영역(GMS SDK iframe)은 디자인 시스템 토큰 적용 불가 — *외부 격리*만 가능:

- 배너 위 1pt `Color.MM.lineSoft` divider (광고 ↔ 콘텐츠 분리).
- 배너 좌우 padding 0 (GMS가 자체 padding 처리).
- 인터스티셜은 풀스크린, 격리 의미 없음.
- 보상형 sheet는 본 디자인 시스템 토큰 사용 (CTA / 헤더만), 광고 자체는 GMS 풀스크린.

---

## 9. 다크 모드 정책 (MVP 결정)

- **MVP는 라이트 단일** 출시. `UIUserInterfaceStyle = "Light"` 강제 (Info.plist).
- 추후 다크 추가 결정 시: § 1.6 의미 토큰 레이어만 갈아끼우면 가능하도록 설계 완료.
- 시스템 다크 모드 따라가기 결정은 v1.1 이후 별도 ADR(`docs/architecture/ADR-XXX-darkmode.md`)로 결정.

---

## 10. SwiftUI 토큰 디렉토리 구조 (제안)

```
LocalPackages/DesignSystem/Sources/
├── Color+MM.swift          # § 1 토큰 + 의미 토큰
├── Font+MM.swift           # § 2.5 MMTypography
├── Spacing+MM.swift        # § 3 MMSpacing
├── Radius+MM.swift         # § 4 MMRadius
├── Shadow+MM.swift         # § 5 MMShadow
├── Motion+MM.swift         # § 6 MMMotion
└── Components/             # see components.md
```

> `ios-lead`가 본 토큰 외 색·폰트 리터럴 사용을 PR에서 차단. CodeRabbit instructions에도 추가.

---

## 11. 변경 이력

| 일자 | 변경 | 사유 | 결정자 |
|---|---|---|---|
| 2026-05-04 | 최초 작성 (MM2 v1) | Phase 1 디자인 시스템 확정 | designer-lead |
| 2026-05-04 | § 8 광고 UI 가드 6개 정책 추가 (배너 숨김 / 인터 콘텐츠 우선 / 보상형 시각 강도 / ATT / disclosure / 색 격리) | po-lead 1차 검토 보강 요청 — design-system 단계에서 광고 UX 가드 시각 명시 | po-lead 사인오프 designer-lead |

---

References:
- 정전: `_handoff/matchamap/project/MatchaMap v2.html`, `mm-shared-v2.jsx`, `mm-screens-v2.jsx`, `styles.css`
- 메모리: `.claude/memory/decisions-design.md`, `.claude/memory/refs-handoff.md`
- 사이드 카탈로그: `docs/design/components.md`, `docs/design/handoff-mapping.md`, `docs/design/icons.md`
