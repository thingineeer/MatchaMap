---
name: decisions-design
description: 디자인 시스템 결정 — v2 화이트톤 팔레트(matcha/deep/rose) + Pretendard. 핸드오프의 v2가 정전(canon)
type: project
---

**정전(canon)**: `_handoff/matchamap/project/MatchaMap v2.html` + `mm-shared-v2.jsx`. v1(MatchaMap MVP.html)의 진한 톤은 **폐기**.

**팔레트 (MM2 토큰)**:
- bg `#fbfaf7` / paper `#ffffff` / cream `#f5f1ea`
- matcha `#7a9560` (먼지 톤) / matchaSoft `#a8b994` / matchaPale `#e6ecde`
- deep `#3d4a2d` (소프트 매차)
- rose `#c98b85` (더스티 로즈, 액센트) / rosePale `#f0d9d5` / blush `#e8c4c0`
- ink `#2a2a2a` / text `#4a4a45` / muted `#a39e92` / line `#ebe7dc`
- gold `#c9a566`

**타이포**: Pretendard → -apple-system → system-ui.

**탭바 4개**: 지도 / 피드 / 위시리스트 / 내정보.

**아이콘**: Apple SF Symbols 의존 금지. 직접 SVG로 픽셀 단위 정렬된 컴포넌트 제작 (`designer-icon` 책임).

**Why:**
- v2가 사용자 마지막 의도. 흰 톤이 글로벌(여행자) 타깃에 더 친화적이고 광고 슬롯과의 충돌 적음.
- 더스티 로즈 액센트는 "여성 친화 + 말차 보색" 조합.

**How to apply:**
- 모든 SwiftUI Color는 DesignSystem 모듈 토큰을 통해서만 접근. 색상 리터럴 금지.
- 디자이너가 SVG 산출물을 `MatchaMap/Assets.xcassets/Symbols/` 또는 `LocalPackages/DesignSystem/Sources/Resources/`에 납품.
