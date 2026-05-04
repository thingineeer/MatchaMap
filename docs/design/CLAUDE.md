# Design 허브 (docs/design)

> `designer-lead` + `designer-icon` 소유.

## 인덱스

- [design-system.md](design-system.md) — MM2 토큰(색/타이포/스페이싱/라운드/그림자)
- [components.md](components.md) — Phone2/StatusBar2/TabBar2/MatchaPin/Stars/GradeChip 등
- [handoff-mapping.md](handoff-mapping.md) — `_handoff/matchamap/v2.html` ↔ SwiftUI 매핑표
- [icons.md](icons.md) — 자체 SVG 아이콘 카탈로그
- [app-icon-decision.md](app-icon-decision.md) — 앱 아이콘 후보 비교 + 최종 선정

## 정전(canon)

- `_handoff/matchamap/project/MatchaMap v2.html`
- `_handoff/matchamap/project/mm-shared-v2.jsx` (MM2 팔레트)
- `_handoff/matchamap/project/mm-screens-v2.jsx` (13개 화면)

## 토큰 매핑 (확정)

| 의미 | hex | SwiftUI |
|---|---|---|
| Background | `#FBFAF7` | `Color.MM.bg` |
| Paper | `#FFFFFF` | `Color.MM.paper` |
| Cream | `#F5F1EA` | `Color.MM.cream` |
| Matcha | `#7A9560` | `Color.MM.matcha` |
| Matcha Soft | `#A8B994` | `Color.MM.matchaSoft` |
| Matcha Pale | `#E6ECDE` | `Color.MM.matchaPale` |
| Deep | `#3D4A2D` | `Color.MM.deep` |
| Rose (Accent) | `#C98B85` | `Color.MM.rose` |
| Rose Pale | `#F0D9D5` | `Color.MM.rosePale` |
| Blush | `#E8C4C0` | `Color.MM.blush` |
| Ink | `#2A2A2A` | `Color.MM.ink` |
| Text | `#4A4A45` | `Color.MM.text` |
| Muted | `#A39E92` | `Color.MM.muted` |
| Line | `#EBE7DC` | `Color.MM.line` |
| Gold | `#C9A566` | `Color.MM.gold` |

## 탭바 (4개)

지도 · 피드 · 위시리스트 · 내정보 (활성 색: `Color.MM.deep`, 비활성: `Color.MM.muted`).
