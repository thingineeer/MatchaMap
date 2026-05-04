# App Icon Decision — 후보 비교 + 채택

> Owner: `designer-icon` · Reviewers: `designer-lead`, `po-lead`
> **Status: ACCEPTED** — **B (단일 잎 글래스) 채택**. PO 사인오프: 2026-05-04 by `po-lead`.
> **Canon (정전)**: `_design_assets/svg/appicon/B-glass-leaf.svg` — v1.0.0 마스터.
> 후보 A/C 마스터는 회수성 자료로 보존(추후 시즌 변형 참고).
> 마스터 SVG: `_design_assets/svg/appicon/{A,B,C}.svg` (각 1024×1024, cx=512 기준 좌우 대칭).
> 디자인 토큰 출처: `.claude/memory/decisions-design.md` (MM2 팔레트).

---

## 1. 컨셉 후보 (3개)

### A. 거품 위 잎 (Foam-on-Cup with Leaf)
> 진한 매차 컵 위에 떠오른 거품, 그 위에 띄워진 잎.

- 마스터: `_design_assets/svg/appicon/A-foam-leaf.svg`
- 모티프: 컵(`MM2.deep #3d4a2d`) + 거품(`MM2.matchaPale #e6ecde`) + 잎(`MM2.matcha #7a9560`).
- 좌우 대칭: cx=512. 컵 양쪽 반지름 동일, 거품 ellipse 가운데 정렬, 잎 중앙 정렬 + 좌우 vein 미러링.
- 카메라: 정면(top-down으로 컵 안을 들여다보는 시점이 아닌 측면 상단 약간).

```svg
<!-- 미리보기는 _design_assets/svg/appicon/A-foam-leaf.svg를 직접 열어 확인 -->
```

### B. 단일 잎 글래스 (Liquid Glass Single Leaf)
> 매차 잎 1장을 iOS 26 Liquid Glass 시트로 감싼 미니멀 형태.

- 마스터: `_design_assets/svg/appicon/B-glass-leaf.svg`
- 모티프: 매차 그라데이션 잎 1장(`#7a9560 → #3d4a2d`) + 반투명 유리 라운드 사각 + 배경 색채 보케(matcha/gold/rose).
- 좌우 대칭: cx=512. 잎 중앙 vein이 정확히 x=512에 위치, 좌우 sub-vein 6개 미러링.
- iOS 26 Liquid Glass 가이드와 가장 자연스럽게 맞물림 — 자체가 layered transparent stack.

```svg
<!-- 미리보기는 _design_assets/svg/appicon/B-glass-leaf.svg를 직접 열어 확인 -->
```

### C. MM 모노그램 (M+M as Leaf)
> 두 개의 M을 잎 모양 백플레이트 위에 올려, "MatchaMap"의 이니셜이 식물처럼 자라난 형상.

- 마스터: `_design_assets/svg/appicon/C-mm-monogram.svg`
- 모티프: 매차 그라데이션 M+M (`#7a9560 → #3d4a2d`) + 잎 모양 backplate(`#e6ecde`).
- 좌우 대칭: cx=512. M 두 봉우리가 정확히 동일한 x 거리(216)로 미러. 가운데 작은 잎 flourish.
- 워드마크 인지성 최고. 단, 식음료/장소 앱이라는 카테고리 시그널은 약함.

```svg
<!-- 미리보기는 _design_assets/svg/appicon/C-mm-monogram.svg를 직접 열어 확인 -->
```

---

## 2. 비교표

| 평가 축 (가중치) | A. 거품 위 잎 | B. 단일 잎 글래스 | C. MM 모노그램 |
|---|---|---|---|
| **말차 모티프 강도** (×3) — 카테고리 즉시 인지 | 5 (컵+거품+잎 모두 명시) | 4 (잎만, 단 매우 명확) | 2 (식물 아닌 글자) |
| **iOS 26 Liquid Glass 호환** (×3) — multi-layer Tinted/Dark 변형 용이성 | 3 (컵 입체감이 Tinted에서 단조롭게 무너짐) | 5 (자체가 glass + 단일 실루엣) | 3 (모노그램은 Tinted에서 평면 OK, Dark에서 콘트라스트 약함) |
| **축소 가독성 60→29pt** (×3) — Spotlight/Notifications 슬롯 | 3 (잎+거품+컵 3요소가 작아지면 뭉침) | 5 (단일 실루엣) | 4 (M 두 개의 골이 작아져도 보임) |
| **글로벌 확장성** (×2) — 6개 언어 외 시장 동결 가능성 | 4 (cup은 보편) | 5 (잎은 차/말차 글로벌 시그널) | 3 (영문 이니셜 의존) |
| **회수성** (×2) — 다음 버전에서도 진화 가능한가 | 4 (거품 모티프는 변형 풍부) | 5 (잎 디테일/색만으로 시즌별 변형) | 3 (글자 자체 변형 어려움) |
| **광고/배너 등 작은 이미지에서 식별** (×1) | 3 | 5 | 4 |
| **합계 (가중)** | 15+9+9+8+8+3 = **52** | 12+15+15+10+10+5 = **67** | 6+9+12+6+6+4 = **43** |

> 합계 산식
> - **A** = (5×3)+(3×3)+(3×3)+(4×2)+(4×2)+(3×1) = **52**
> - **B** = (4×3)+(5×3)+(5×3)+(5×2)+(5×2)+(5×1) = **67**
> - **C** = (2×3)+(3×3)+(4×3)+(3×2)+(3×2)+(4×1) = **43**
> 결과: **B (67) > A (52) > C (43)** → B 추천.

---

## 3. 추천: **B. 단일 잎 글래스**

**근거**
1. **iOS 26.2 Liquid Glass와 자연스러운 정합** — 우리 앱이 사용하는 디자인 토큰 자체가 v2 화이트톤 + 반투명 layered 구조(`decisions-design.md`). 앱 아이콘이 OS 디자인 언어와 다른 결을 띠면 스프링보드에서 시각적 부조화.
2. **축소 가독성** — 잎 단일 실루엣은 29pt까지 무너지지 않음. A는 컵+거품+잎 3개 요소가 겹쳐 작은 사이즈에서 식별 어려움.
3. **카테고리 시그널** — "잎=차/말차"는 글로벌 6개 언어/지역에서 학습된 시그널. C는 영문 이니셜이라 한·일·중 시장에서 즉각 인지가 약함.
4. **회수성** — 잎 색/그라데이션/광택만 바꿔도 시즌별 변형(예: 가을 한정 골드 베인)을 만들 수 있어, 1.x → 2.x 진화 여지가 큼.

**B의 약점과 대응**
- **모티프가 한 가지뿐** — 컵 모티프가 빠져 "음료" 시그널이 다소 약함. → 대응: 첫 출시 마케팅 키 비주얼(스토어 스크린샷·온보딩)에서 컵+잎 컴포지션을 보여 컵 시그널을 보강. 앱 아이콘은 "잎=식별성"에 올인.
- **잎이 흔한 모티프** — Starbucks·Tealeaves 등 차/식음료 앱과 차별화 약할 수 있음. → 대응: vein 6개의 비대칭 길이/굵기를 MM 시그니처 패턴으로 고정. 잎 끝 좌측 spec highlight를 시그니처로 유지.

---

## 4. iOS 26 Liquid Glass 변형 가이드 (B 채택 시)

> Apple Liquid Glass 다층 구조: Background / Mid / Foreground 3 레이어. 각 레이어는 Light/Dark/Tinted 3 모드.

| 레이어 | Light | Dark | Tinted |
|---|---|---|---|
| **Background** | `#fbfaf7 → #e6ecde` (cream → matchaPale) | `#1a1f15 → #2a3520` | `accent` 단색 |
| **Mid (glass)** | `#ffffff @ 0.55→0.18` | `#3d4a2d @ 0.45→0.15` | `accent @ 0.35→0.10` |
| **Foreground (잎)** | `#7a9560 → #3d4a2d` | `#a8b994 → #7a9560` | `white` (Tinted은 단색 마스크) |

- 잎 vein은 Foreground 위에 별도 레이어로 두어 Tinted에서도 구조가 유지되도록.
- 마스터 1024는 Apple HIG 기준 안전 영역 824×824 안에 핵심 모티프 (잎)이 들어가도록 설계 → 본 SVG의 잎은 (260..820) 영역에 위치, 안전 영역 통과.

---

## 5. 슬롯 생성 계획 (Asset Catalog)

채택 시 자동 export 슬롯 (1024 마스터에서 다운샘플):

| Idiom | Size | Scale | 파일명 |
|---|---|---|---|
| ios-marketing | 1024×1024 | 1x | `AppIcon-1024.png` |
| iphone | 60×60 | 2x | `AppIcon-60@2x.png` (120) |
| iphone | 60×60 | 3x | `AppIcon-60@3x.png` (180) |
| iphone | 40×40 | 2x | `AppIcon-40@2x.png` (80) |
| iphone | 40×40 | 3x | `AppIcon-40@3x.png` (120) |
| iphone | 29×29 | 2x | `AppIcon-29@2x.png` (58) |
| iphone | 29×29 | 3x | `AppIcon-29@3x.png` (87) |
| ipad | 76×76 | 2x | `AppIcon-76@2x.png` (152) |
| ipad | 83.5×83.5 | 2x | `AppIcon-83.5@2x.png` (167) |
| ipad | 40×40 | 1x/2x | `AppIcon-40.png` (40,80) |
| ipad | 29×29 | 1x/2x | `AppIcon-29.png` (29,58) |

PNG export는 PO 사인오프 이후 fastlane lane(`generate_appicon_slots`)으로 일괄 생성 — 본 단계에서는 마스터 SVG만 납품.

---

## 6. 결정 흐름

1. **본 문서 + 3개 SVG 마스터** → `designer-lead`/`po-lead`에게 SendMessage. [완료]
2. **PO 사인오프 — B 채택 (2026-05-04)**. [완료]
3. PNG 슬롯 생성 + `MatchaMap/Assets.xcassets/AppIcon.appiconset/` 적재 — Phase 2 시작 시 `ios-lead` 슬롯 이름 규약 합의 후 fastlane lane(`generate_appicon_slots`)에서 일괄 export. [대기]
4. `MatchaMap.xcodeproj` 빌드 설정의 `ASSETCATALOG_COMPILER_APPICON_NAME`은 `AppIcon` 그대로 유지.
5. Liquid Glass 변형 가이드(§4) 검증은 Phase 3 시뮬레이터 캡처(`qa-functional` 협업) 단계에서 수행.

---

## 7. 약점 보강 정책 (PO 사인오프 시 합의)

B의 약점 "음료/카테고리 시그널 약함"을 보강하기 위한 정책:

- **스토어 스크린샷 + 온보딩 키비주얼**에서 컵+잎 컴포지션을 명시 노출. 상세 명세는 `docs/design/store-screenshots-spec.md` 참조 (`designer-icon` 작성).
- **잎 vein 6개의 비대칭 길이/굵기**를 MM 시그니처 패턴으로 고정. v2.x에서도 vein 패턴은 동결, 색/그라데이션만 시즌 변형.
- B 채택 후에도 A의 "거품" 모티프는 마케팅/온보딩 일러스트에서 재사용 (앱 아이콘 외부 채널).

---

## 8. Changelog

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-04 | 초안 작성 (3 후보 + 가중 매트릭스 + 추천 B) | designer-icon |
| 2026-05-04 | **PO 사인오프 — B 채택. canon 등록.** | po-lead, designer-icon |
| 2026-05-04 | §7 약점 보강 정책 추가 (스토어 스크린샷 + vein 시그니처 동결) | designer-icon |

---

생성: 2026-05-04 · Owner: `designer-icon` · Status: ACCEPTED
