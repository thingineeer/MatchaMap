# LocalPackages/Feature/FeatureStore

> 매장 상세, 메뉴, 리뷰, 검색·필터. **소유: `ios-store`**.

## 책임

- 매장 상세 (`StoreDetailScreen`).
- 메뉴 / 리뷰 작성·조회.
- 검색 / 필터 / 정렬.
- 리뷰 작성 → `RegisterStoreToCollectionUseCase` 트리거 (도감 자동 추가 가설 H1).

## 의존

- 내부: `Domain`, `DesignSystem`.

## 금지

- `import Data`. 다른 `Feature/*` 모듈 import.

## 가설 매핑

- H1 도감 등록률 — `register_store_to_collection` 이벤트.
- H4 평균 평점 신뢰성 — review_count ≥ N 게이트.
