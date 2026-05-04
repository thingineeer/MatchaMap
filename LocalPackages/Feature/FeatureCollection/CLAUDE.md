# LocalPackages/Feature/FeatureCollection

> 도감, 위시리스트, 랭킹. **소유: `ios-social-collection`**.

## 책임

- 도감 (`CollectionScreen`) — 방문/등록한 매장 카드 그리드.
- 위시리스트.
- 랭킹 (지역별/친구).
- 도감 잠금 해제 보상형 광고 트리거 (FeatureMonetize 협업).

## 의존

- 내부: `Domain`, `DesignSystem`.

## 금지

- `import Data`. 다른 `Feature/*` 모듈 import (Monetize 보상형 트리거는 Composition Root에서 콜백 주입).

## 가설 매핑

- H1 도감 등록률.
- H6 랭킹 노출 시 D7 retention 영향.
