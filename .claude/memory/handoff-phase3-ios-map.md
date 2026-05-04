---
name: handoff-phase3-ios-map
description: Phase 3 ios-map 시작 시 즉시 처리할 합의 의제 — 매장 핀 SVG 명세, anchor, 등급 매핑, Asset 이름 규약 + S핀 glow 정책 6건
type: project
---

**대상 에이전트**: `ios-map` (Phase 3에서 spawn 예정)

**Why:** Phase 1에 designer-icon이 매장 핀 SVG 3종(basic/premium/iconic)과 명세를 완성했지만, ios-map은 Phase 3까지 비활성. designer-icon이 본인 mailbox로 합의 요청을 보내둠 → 정상이지만 누락 방지를 위해 메모리로 백업.

**합의 의제 5건** (designer-icon → ios-map):

1. **viewBox + 사이즈**: 36×44, retina 1x/2x/3x → SwiftUI에서 `Image` resizable 또는 GMSMarker.icon으로 UIImage 변환.
2. **anchor = tip(18, 42)**: 핀 끝점이 좌표에 정확히 닿도록 `GMSMarker.groundAnchor = CGPoint(x: 0.5, y: 1.0)`.
3. **그림자**: SVG 본체와 별도 레이어 (CAShapeLayer 또는 GMSMarker.opacity로 처리). designer-icon SVG에는 그림자 미포함.
4. **등급 매핑**: 매장 등급 S/A/B/C → 핀 종류 iconic/premium/premium/basic 또는 별도 합의. server-data의 store schema의 `matchaScore` 또는 별도 `grade` 필드와 정합 필요.
5. **Asset 이름 규약**: `Pin/basic.svg → AssetCatalog "MatchaPin/Basic"` 또는 `MatchaMap/Assets.xcassets/Pin.symbolset/` 후보 — ios-lead가 결정.
6. **S핀 glow 15초 후 정지** (po-lead 결정, designer-lead 회신 2026-05-04): 지도 화면 onAppear 시 S핀(iconic) 마커에 `MMMotion.pulse` 애니메이션 적용 → 15초 타이머 → expire 시 정지. 사용자가 카메라 이동/줌 시 타이머 리셋. 정책은 components.md § 2.3 MatchaPin 스펙 + decisions-design.md 동기화. ios-map이 ADR-101에 최종 결정.

**위치**:
- 명세 본문: `docs/design/icons.md` § 3 매장 핀
- SVG 원본: `_design_assets/svg/pin/{basic,premium,iconic}.svg`

**How to apply (ios-map Phase 3 시작 시):**
1. 본 메모 + designer-icon mailbox 메시지 둘 다 수령.
2. 5건에 답변하여 designer-icon, ios-lead, server-data와 합의.
3. `docs/architecture/ADR-101-google-maps-integration.md`에 핀 통합 섹션 추가.
