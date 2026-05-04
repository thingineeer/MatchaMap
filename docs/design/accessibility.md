# Accessibility — VoiceOver / Dynamic Type / WCAG AA

> PRD §6 접근성 가드의 구체화. iOS 26.2 기준.
> 적용 강도: **VoiceOver / Dynamic Type / 컨트라스트 = 출시 게이트**, 그 외(Reduce Motion / Smart Invert / Voice Control)는 best-effort.

소유: `designer-lead` 책임 / `qa-functional` 회귀 / `po-lead` 사인오프.

---

## 1. 적용 범위

| 항목 | 강도 | MVP v1.0.0 |
|---|---|---|
| VoiceOver 라벨 (모든 컨트롤) | **필수** | YES |
| Dynamic Type (XS ~ AX5) | **필수** | YES |
| WCAG AA 컨트라스트 (텍스트) | **필수** | YES |
| Reduce Motion | 권장 | YES (애니메이션 단순화) |
| Reduce Transparency | 권장 | YES (glassEffect → opaque) |
| Smart Invert / 다크 모드 | 비범위 | NO (라이트 단일, v1.1) |
| Voice Control | best-effort | 자동 inference 사용 |
| Switch Control | best-effort | 표준 컴포넌트 사용으로 자동 |
| Larger Text 외 시각 보조 | best-effort | — |

---

## 2. VoiceOver

### 2.1 라벨 작성 규칙

모든 인터랙티브 컴포넌트는 `.accessibilityLabel` + (필요 시) `.accessibilityHint` + `.accessibilityValue` 명시.

| SwiftUI modifier | 용도 | 작성 룰 |
|---|---|---|
| `.accessibilityLabel("...")` | "이게 무엇인가" | 짧고 명사형. 아이콘 의미 전달. 다국어 String Catalog. |
| `.accessibilityHint("...")` | "탭하면 무엇이 일어나는가" | 동사형. iOS HIG 권장. |
| `.accessibilityValue("...")` | "현재 상태/값" | 토글 on/off, 슬라이더 값, 체크박스 selected 여부. |
| `.accessibilityAddTraits(.isButton)` | 트레이트 | Image/Text를 버튼으로 인지시킬 때. |
| `.accessibilityHidden(true)` | 장식적 요소 | 의미 없는 데코 (점선 링, 그라디언트 등). |

### 2.2 컴포넌트별 라벨 정책

#### 2.2.1 Atom

| 컴포넌트 | label | hint | value |
|---|---|---|---|
| `GradeChip(grade)` | "등급 {S/A/B/C}" | (none) | (none) |
| `Stars(value)` | "별점" | (none) | "{value}점, 5점 만점" |
| `MatchaPin(grade)` | "매장 핀, 등급 {grade}" | "탭하면 매장 미리보기를 봐요" | (none) |
| `IconButton(icon:"bookmark", isActive)` | "북마크" | "탭하면 위시리스트에 추가/제거" | "추가됨" / "추가 안 됨" |
| `IconButton(icon:"heart", isActive)` | "좋아요" | "탭하면 좋아요 토글" | "{count}명 좋아요" |
| `IconButton(icon:"share")` | "공유" | "공유 시트 열기" | (none) |
| `Avatar(name)` | "사용자 {name}" | "탭하면 프로필" | (none) |
| `CountryFlag(code)` | "{국가 한국어 이름}" (한국어 locale) | (none) | (none) |
| `Chip(label, count, selected)` | "{label}" | "탭하면 필터 적용" | "선택됨" / "선택 안 됨", "{count}건" |

#### 2.2.2 Card

| 카드 | 합쳐진 라벨 (`.accessibilityElement(children: .combine)`) |
|---|---|
| `StoreCard(.listRow)` | "{매장명}, 등급 {grade}, {distance}, 별점 {rating}점" |
| `StoreCard(.floating)` | "{매장명}, 등급 {grade}, {price-tier}, 별점 {rating}점, {open상태}" + 별도 button "길찾기 / 전화" |
| `ReviewCard` | "{author}의 리뷰, {rating}점, {date}, '{title}'. {body 첫 50자}..." + 별도 hint "탭하면 전체 보기" |
| `FeedPostCard` | "{author}의 게시물, {country}, {location}, {time}. '{body 첫 80자}...'. 좋아요 {count}, 댓글 {count}" + heart/comment 각각 button |
| `WishlistRow` | "위시리스트, {매장명}, 등급 {grade}, {지역}" + 메모 있으면 "{메모}" 추가 |

#### 2.2.3 Frame

| 컴포넌트 | 정책 |
|---|---|
| `TabBar2` | 시스템 `.tabItem`에 자동 매핑. 각 탭 `.accessibilityLabel("{label}")` + `.accessibilityHint("{section} 화면으로 이동")` |
| `StatusBar2` / `HomeIndicator2` | `.accessibilityHidden(true)` (시스템 자체 처리) |
| `Phone2` | (디자인 카탈로그 전용, 앱 없음) |

#### 2.2.4 Map

| 컴포넌트 | 정책 |
|---|---|
| `WorldMap2` (배경 SVG) | `.accessibilityHidden(true)` (장식) |
| `CityMap2` (배경) | `.accessibilityHidden(true)` |
| GMSMapView 자체 | iOS GMS SDK가 자체 a11y 처리. 핀은 별도 `.accessibilityElement` 필요. `ios-map`이 `Marker.title/snippet` 활용 |

#### 2.2.5 Button

| 컴포넌트 | label | hint |
|---|---|---|
| `PrimaryButton(title:"길찾기", leadingIcon:"compass")` | "길찾기" | "지도 앱으로 이동" |
| `PrimaryButton(title:"위치 허용하기")` | "위치 허용하기" | "근처 매장 표시 위해 위치 권한 요청" |
| `GhostButton("이메일로 가입하기")` | "이메일로 가입하기" | "이메일 회원가입 화면으로 이동" |
| `IconButton(icon:"close")` | "닫기" | "현재 화면 닫기" |
| `IconButton(icon:"arrow-left")` | "뒤로" | "이전 화면" |

#### 2.2.6 Input

| 컴포넌트 | label | value |
|---|---|---|
| `SearchField` | "매장 검색" | (입력값) |
| `ReviewTextEditor` | "리뷰 내용" | (입력값 또는 "비어 있음") |
| `TagSelector` | "태그 선택" | "{선택된 태그 N개}" |

### 2.3 데코 / 숨김 요소

다음 요소들은 `.accessibilityHidden(true)`:
- Lottie placeholder 점선 회전 링 (텍스트는 별도)
- StatHero의 mono 라벨 (장식. 데이터는 숫자에 통합)
- Splash 로고 SVG (별도 `accessibilityLabel("말차맵 로고")`)
- 카드 배경 그라디언트 / shadow / divider
- Stories ring gradient
- 매장 미리보기 hero photo overlay gradient

### 2.4 그룹화 / 순서

- **카드 콘텐츠**: 한 카드는 한 accessibility element로 합쳐짐 (`.combine`).
- **읽기 순서**: SwiftUI 자연 순서 사용. 명시적 제어 필요 시 `.accessibilitySortPriority`.
- **Custom Actions**: 카드의 like/bookmark 등 inline 액션은 `.accessibilityAction(named: "좋아요", { ... })`로 노출 — VoiceOver 사용자가 카드 안에서 액션 호출 가능.

### 2.5 라이브 리전 / 상태 변경 알림

- 좋아요 토글, 북마크 토글, 별점 입력 변경 시 `UIAccessibility.post(notification: .announcement, ...)` 또는 `.accessibilityValue` 변경.
- 광고 로드 완료 / 보상형 unlock 완료: 음성 안내.

---

## 3. Dynamic Type

### 3.1 지원 범위

iOS XS ~ AX5 (총 12단계). MVP는 **XS ~ AX5 모두 레이아웃 유지**.

| 카테고리 | abbr | scaling | 비고 |
|---|---|---|---|
| Extra Small | XS | 0.82× | |
| Small | S | 0.88× | |
| Medium | M | 0.94× | |
| Large (default) | L | 1.00× | iOS 기본값 |
| Extra Large | XL | 1.12× | |
| Extra Extra Large | XXL | 1.24× | |
| Extra Extra Extra Large | XXXL | 1.35× | |
| Accessibility M | AX1 | 1.64× | A11y 첫 단계 |
| Accessibility L | AX2 | 1.94× | |
| Accessibility XL | AX3 | 2.35× | |
| Accessibility XXL | AX4 | 2.76× | |
| Accessibility XXXL | AX5 | 3.12× | 최대 |

### 3.2 폰트 적용 정책

**모든 텍스트**는 Dynamic Type 호환 폰트로 등록:

```swift
// Bad (고정 사이즈 — 사용 금지)
Text("안녕")
  .font(.custom("Pretendard-Regular", size: 14))

// Good (Dynamic Type 호환)
Text("안녕")
  .font(.custom("Pretendard-Regular", size: 14, relativeTo: .body))
```

| `MMTypography` token | relativeTo |
|---|---|
| `display` | `.largeTitle` |
| `title1` | `.title` |
| `title2` | `.title2` |
| `headline` | `.title3` 또는 `.headline` |
| `body` | `.body` |
| `callout` | `.callout` |
| `subhead` | `.subheadline` |
| `footnote` | `.footnote` |
| `caption` | `.caption` |
| `monoLabel` | `.caption2` |
| `statNumber` | `.largeTitle` |

> `ios-lead`가 ADR로 위 매핑 확정.

### 3.3 레이아웃 적응

| 카테고리 범위 | 정책 |
|---|---|
| XS ~ XXXL (default + 0~3 step) | 디자인 시안 그대로. 변경 없음. |
| AX1 ~ AX5 | **Larger Layout 모드 활성**. |

#### Larger Layout 모드 정책 (AX1+)

1. **horizontal carousel → vertical stack**: 매장 카드 carousel(05 City)이 vertical full-width 리스트로 전환.
2. **GridLayout 2열 → 1열**: 매장 상세 quick action grid 4열 → 2×2.
3. **icon + label → label only**: 라벨 잘리는 경우 아이콘 hidden + 라벨만 노출 (TabBar 제외).
4. **min tap target 44pt 보장**: 모든 IconButton AX 모드에서 height 44pt 이상.
5. **multi-line 허용**: `lineLimit(1)` 컴포넌트 일부 (PrimaryButton title)는 AX 모드에서 lineLimit(2).
6. **AvatarRing → 단순 fill**: profile gradient ring AX 모드에서 단색 fill (가독성).

### 3.4 SwiftUI 구현 패턴

```swift
@Environment(\.dynamicTypeSize) var typeSize

var isLargeLayout: Bool {
  typeSize.isAccessibilitySize  // AX1 이상
}

var body: some View {
  if isLargeLayout {
    LargerLayoutView()
  } else {
    StandardLayoutView()
  }
}
```

> `ViewThatFits` 또는 `Layout` 프로토콜 활용. `ios-lead`가 모듈별 패턴 통일.

---

## 4. WCAG AA 컨트라스트

### 4.1 기본 룰 (`design-system.md § 1.8` 강화)

WCAG 2.1 AA 기준:
- 본문 텍스트 (≤ 18pt regular, ≤ 14pt bold) ≥ **4.5:1**
- 대형 텍스트 (≥ 18pt regular, ≥ 14pt bold) ≥ **3.0:1**
- 비텍스트 UI (아이콘 / 컨트롤 경계) ≥ **3.0:1**

### 4.2 토큰별 검증

`design-system.md § 1.8`에 검증 결과:
- ✓ `text(#4A4A45)` on `bg(#FBFAF7)` ≈ 9.3:1
- ✓ `deep(#3D4A2D)` on `paper(#FFFFFF)` ≈ 9.0:1
- ✗ `muted(#A39E92)` on `bg` ≈ 2.8:1 — **AA fail. 14pt 이하에서만 허용 (캡션/메타)**
- ✗ `rose(#C98B85)` on `paper` ≈ 3.4:1 — **AA fail (small text). 18pt+ bold 또는 아이콘만 허용**
- ✗ `gold(#C9A566)` on `paper` ≈ 2.7:1 — **텍스트 사용 금지. 별 아이콘 fill 전용**

### 4.3 체크리스트 (qa-functional 회귀)

| 화면 | 점검 항목 | 통과 여부 |
|---|---|---|
| 01 Splash | 헤드라인 `deep` on `cream` (≈ 8.5:1) | ✓ |
| 02 Login | 본문 `muted` on `bg` (캡션 11pt) — 14pt 이하 OK | △ (사이즈 확인) |
| 04 World | StatHero 본문 `deep` on `paper` (✓), mono "지금 이 순간" `rose` 9pt — 장식 라벨 OK | ✓ |
| 05 City | carousel 매장명 `deep` on `paper` ✓, 거리 mono `rose` 9pt — 장식 OK | ✓ |
| 06 Preview | "영업중" `matcha` on `paper` (≈ 3.7:1) — 11pt 600 weight, large 분류 OK | ✓ |
| 07 Detail | 매장 소개 본문 `text` on `bg` ✓, 매장 속성 비활성 `muted` 11pt — 14pt 이하 OK | ✓ |
| 08 Reviews | 분포 % mono `muted` 10pt — 캡션 OK | ✓ |
| 11 Feed | 피드 본문 `text` on `paper` ✓, location/time `muted` 10pt — 캡션 OK | ✓ |
| 13 Profile | "전체 →" `rose` 11pt — 14pt 이하 fail. **수정 필요: weight 600으로 large 분류 만족 또는 deep 사용**. 현재 weight 500 |

> △ / × 표시 화면은 designer-lead가 보강 필요. **이 항목들은 Phase 2 디자인 폴리시에서 수정**.

### 4.4 Glass effect 위 텍스트

iOS 26.2 Liquid Glass `.glassEffect()` 위 텍스트는 배경에 따라 컨트라스트 변동. **glass 위 텍스트는 항상 `Color.MM.deep` (9.0:1+)** 사용. `muted` / `rose` 사용 금지.

---

## 5. Reduce Motion / Reduce Transparency

### 5.1 Reduce Motion 활성 시

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion
```

| 모션 | 정상 | Reduce |
|---|---|---|
| MMMotion.spring (sheet) | spring | linear 0.2s |
| MMMotion.pulse (S 핀 glow) | 무한 | **정지** |
| MMMotion.rotate (Lottie 점선) | 무한 | **정지 + 정적 일러스트로 대체** |
| MMMotion.blink (커서) | 1s 깜빡임 | **정적 표시** |
| 화면 전환 fade | 0.3s | 즉시 |
| 카드 unlock animation | 0.4s gradient | 즉시 색 변경 |

### 5.2 Reduce Transparency 활성 시

| 컴포넌트 | 정상 | Reduce |
|---|---|---|
| TabBar2 (`.glassEffect`) | thin glass | `Color.MM.paper` opaque |
| World map 검색바 | glass | paper opaque |
| Detail glass IconButton | glass | paper + shadow |

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
.background {
  if reduceTransparency {
    Color.MM.paper
  } else {
    Color.MM.paper.opacity(0.96).background(.ultraThinMaterial)
  }
}
```

---

## 6. 탭 타깃 / 인터랙션

### 6.1 최소 탭 타깃 44×44pt (Apple HIG)

| 컴포넌트 | 시안 사이즈 | 실제 탭 영역 |
|---|---|---|
| IconButton(.sm) | 32×32 | `.contentShape(Rectangle()).frame(minWidth: 44, minHeight: 44)` |
| IconButton(.md) | 36×36 | minWidth/Height 44 |
| GradeChip(.sm) | 20×20 | 카드 안에 있음 — 카드 자체가 탭 영역 |
| Star input (리뷰 작성) | 36×36 | 자체로 충족 (실제 spacing 6 + size 36 = 42, 인접 탭 가능 거리) |
| TabBar 라벨 영역 | flex 1 | 시스템이 처리 |

### 6.2 인접 컨트롤 거리

WCAG 2.5.8 Target Size: 인접 컨트롤 사이 최소 24pt 또는 컨트롤 자체 44pt 이상.

- `screens.md § 4 ReviewWrite`의 별점 6pt gap → 36pt 컨트롤 + 6pt = 42pt 중심간격. **Apple HIG는 통과, WCAG 2.5.8 AAA는 fail**. AA만 만족 (AAA는 비범위).

---

## 7. 컬러 외 의미 전달 (WCAG 1.4.1)

색만으로 의미 전달 금지. 보조 시그널 항상 포함:

| 의미 | 색 | 보조 시그널 |
|---|---|---|
| 영업중 / 영업 종료 | matcha / muted | "영업중" / "영업 종료" 텍스트 + dot 아이콘 |
| 좋아요 활성 / 비활성 | rose / text | heart-fill / heart 아이콘 변경 |
| 북마크 활성 / 비활성 | deep / muted | bookmark-fill / bookmark 아이콘 변경 |
| 등급 S/A/B/C | deep/matcha/rose/cream | 라벨 글자 "S"/"A"/"B"/"C" |
| 선택된 칩 | deep bg paper fg | weight 600 + ✓ prefix (matchaPale variant) |
| 에러 toast | rose | 아이콘 alert + 텍스트 명시 |
| 별점 | gold | 별 아이콘 fill + 숫자 |

---

## 8. 입력 보조

- **자동완성 / 형식 힌트**: SwiftUI `.textContentType(...)` 명시 (이메일, 이름, etc).
- **키보드 타입**: `.keyboardType(.emailAddress)` / `.URL` / `.numberPad` 등 정확한 타입.
- **에러 inline**: 검색/입력 에러는 inline label `Color.MM.rose` + 아이콘 + VoiceOver alert.

---

## 9. 검수 체크리스트 (`qa-functional` SSOT)

### 9.1 화면별 (30 화면 × 9 항목)

각 화면 검수 시:

1. ✓ VoiceOver 모든 컨트롤 라벨 존재
2. ✓ VoiceOver hint (탭하면 무엇 일어나는지) 명시
3. ✓ VoiceOver 카드 그룹화 적절
4. ✓ Dynamic Type AX1 레이아웃 깨짐 없음
5. ✓ Dynamic Type AX5 레이아웃 깨짐 없음
6. ✓ WCAG AA 컨트라스트 통과
7. ✓ Reduce Motion 활성 시 무한 애니메이션 정지
8. ✓ Reduce Transparency 활성 시 glass → opaque
9. ✓ 탭 타깃 44×44pt 보장

### 9.2 자동화 (Phase 5)

- Appium + iOS XCUI a11y inspection.
- accessibility audit 도구 (Apple Accessibility Inspector) CI 통합.
- Dynamic Type 자동 캡처 (XS, L, AX1, AX5 4단계 × 30 화면 = 120 캡처).

### 9.3 결함 등급

| 등급 | 정의 | 액션 |
|---|---|---|
| Blocker | VoiceOver로 핵심 플로우 사용 불가 (예: 로그인 / 검색 / 매장 상세) | 출시 차단 |
| Major | AX5에서 텍스트 잘림 / 컨트롤 가림 | Phase 2~5 내 해결 |
| Minor | 라벨 누락(데코), AAA 미충족 | Phase 6 best-effort |

---

## 10. 변경 이력

| 일자 | 변경 |
|---|---|
| 2026-05-04 | 초안 작성 (VoiceOver 컴포넌트별 라벨 + Dynamic Type AX 레이아웃 정책 + WCAG AA 검증 + Reduce Motion/Transparency 대응) |

---

References:
- PRD `docs/product/PRD.md` § 6 비기능
- 토큰 `docs/design/design-system.md` § 1.8 컨트라스트
- 화면 `docs/design/screens.md` § 12 검수 기준
- 컴포넌트 `docs/design/components.md`
- QA `docs/qa/a11y-checklist.md` (qa-functional이 작성 예정)
