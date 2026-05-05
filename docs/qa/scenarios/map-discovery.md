# 시나리오: 지도 탐색 (Map Discovery)

> 담당 iOS: `ios-map`. 담당 QA: `qa-functional`. 다국어: `qa-localization`.
> 부속 모듈: `ios-store` (StoreDetail push 검증).

## 사용자 플로우

로그인 완료 → 지도 탭 진입 → 현재 위치 기반 카메라 → 핀 탭 → StoreDetailScreen push.

## Given (전제)

- 사용자는 Apple Sign In 또는 Passkey 로그인 완료 상태.
- `MainTabView`의 첫 번째 탭(지도)이 활성.
- iOS 26.2, iPhone 17 시뮬레이터 기준.
- Phase 3 시점: `MapKit` 기반 임시 구현 (`FeatureMap`). Google Maps SDK는 Phase 5 교체 예정.
- 매장 mock fixture ≥ 5 (서울 광화문/강남 좌표).

## When (액션)

1. 하단 탭바의 "지도" 아이콘 탭 → `MapView` 진입.
2. 위치 권한 프롬프트 → 허용.
3. 카메라가 현재 위치(또는 서울 디폴트)로 이동.
4. 매장 핀(녹색 말차 컬러) 표시 확인.
5. 핀 1개 탭 → 하프 시트 또는 StoreDetailScreen push.
6. StoreDetailScreen에서 매장명 / 메뉴 / 리뷰 첫 페이지 확인.
7. 뒤로가기 제스처 또는 닫기 버튼 → 지도로 복귀.

## Then (검증)

- [ ] 지도 카메라 줌 레벨이 도시 단위(15±2) 안에서 안정 표시.
- [ ] 마커 5개 이상이 시야 안에 클러스터링 또는 개별 표시.
- [ ] 핀 탭 시 햅틱(Light) + 마커 강조 애니메이션.
- [ ] StoreDetailScreen에 매장명, 평균 별점, 메뉴 ≥ 3, 리뷰 카드 ≥ 1 노출.
- [ ] 네트워크 요청 P95 ≤ 600ms (Phase 5 백엔드 연동 후 재측정).
- [ ] 뒤로가기 후 카메라 위치/줌 보존(상태 복원).

## Edge cases

| ID | 상황 | 기대 동작 |
|---|---|---|
| E1 | 위치 권한 거부 | 서울 디폴트 카메라(37.5665, 126.9780) + 토스트 "설정에서 권한 변경 가능" |
| E2 | 인터넷 끊김 (오프라인) | 지도 타일 캐시 표시 + 핀 0 + 배너 "네트워크 연결 후 다시 시도" |
| E3 | 핀 0개 (시야 내) | 빈 상태 카피 "이 지역에는 등록된 매장이 없습니다" + "매장 제안하기" CTA |
| E4 | 핀 1000+ (스트레스) | 클러스터링 작동, 60fps 유지(Phase 5 GMS 교체 후 재검증) |
| E5 | 매장 fetch 실패 (5xx) | 자동 재시도 1회 + 실패 시 토스트 |
| E6 | iPad 가로 모드 | 지도 + 사이드바 분할 레이아웃 |
| E7 | Dynamic Island/Notch 영역 | 지도 컨트롤(나침반/내 위치) safe area 안쪽 배치 |

## 예상 회귀 위험도

**P0** — 앱의 핵심 진입점. FAIL 시 머지 차단.

## 다국어 영향

- 빈 상태/오프라인 카피 (ko, en-US, en-GB, de-DE, ja, fr-FR) 6개 언어 String Catalog 키 존재.
- 위치 권한 프롬프트(`NSLocationWhenInUseUsageDescription`) 6개 언어.
- 독일어 카피가 가장 길음 — 토스트/배너 1줄 오버플로우 검증.

## 접근성

- VoiceOver: 핀 라벨 "{매장명}, 평균 별점 {n.n}, 두 번 탭하여 자세히 보기".
- VoiceOver: 지도 자체는 "지도, 현재 위치 {지명}".
- Dynamic Type: 토스트/배너 카피 Largest Accessibility Size까지 깨짐 없음.
- 컬러 대비: 핀 vs 지도 배경 ≥ WCAG AA (특히 다크 모드).
- Reduce Motion: 핀 탭 애니메이션 dimming만, 줌 애니메이션 1배속.

## 사인오프

| 일자 | 빌드 | 결과 | 비고 |
|---|---|---|---|
| TBD | TBD | TBD | Phase 3: mock 데이터 기준 PASS |
