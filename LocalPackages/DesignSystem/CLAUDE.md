# LocalPackages/DesignSystem

> SwiftUI만 의존. **Domain import 금지**.

## 책임

- MM2 화이트톤 팔레트 토큰(`MMColor`).
- Pretendard 타이포그래피 토큰(`MMTypography`).
- 스페이싱 토큰(`MMSpacing`).
- 공통 컴포넌트: `MMButton`, `MMCard`, `MMTag`, `MMRatingBadge`, `MMSearchBar`, `MMEmptyState` 등 (`docs/design/components.md` 카탈로그).
- 매장 핀 SVG (`MatchaPinView`) — `_design_assets/svg/pin/`을 Asset Catalog로 변환.
- Liquid Glass 머터리얼 헬퍼.

## 금지

- 비즈니스 로직.
- `import Domain` / `import Data` / `import Feature/*`.
- 네트워크.

## 디자이너 핸드오프 SSOT

- `docs/design/handoff-mapping.md` — 토큰 ↔ Figma 컴포넌트 매핑.
- `docs/design/design-system.md` — 전체 디자인 시스템.

## Public API 규약

- 컴포넌트는 `public struct ... : View`.
- 토큰은 `public enum`의 정적 프로퍼티.
- 모든 타입 `Sendable` 가능하면 채택.

## 리소스

- `Sources/DesignSystem/Resources/` 디렉토리에 Asset Catalog/폰트 적재.
- Phase 3에서 `Package.swift`의 `resources: [.process("Resources")]` 활성화.
