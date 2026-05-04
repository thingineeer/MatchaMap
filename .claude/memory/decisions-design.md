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

**앱 아이콘 (2026-05-04 ACCEPTED, po-lead 사인오프)**:
- 채택 = **B 단일 잎 글래스** (`_design_assets/svg/appicon/B-glass-leaf.svg`). 1024 마스터, cx=512 좌우 대칭.
- canon: B만. A/C는 회수성/시즌 변형 참고용으로 보존.
- vein 시그니처(6 비대칭) = MM 동결 패턴 — v2.x까지 vein 좌표 변경 금지, 색/그라데이션만 시즌 변형.
- 약점 보강: 음료 시그널은 스토어 스크린샷 + 온보딩 키비주얼에서 컵+잎 컴포지션으로 보강 (`docs/design/store-screenshots-spec.md`).
- 참고: `docs/design/app-icon-decision.md` 가중 매트릭스 합계 B=67 / A=52 / C=43.

**Why:**
- v2가 사용자 마지막 의도. 흰 톤이 글로벌(여행자) 타깃에 더 친화적이고 광고 슬롯과의 충돌 적음.
- 더스티 로즈 액센트는 "여성 친화 + 말차 보색" 조합.

**How to apply:**
- 모든 SwiftUI Color는 DesignSystem 모듈 토큰을 통해서만 접근. 색상 리터럴 금지.
- 디자이너가 SVG 산출물을 `MatchaMap/Assets.xcassets/Symbols/` 또는 `LocalPackages/DesignSystem/Sources/Resources/`에 납품.
