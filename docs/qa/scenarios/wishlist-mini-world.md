# 시나리오: 위시리스트 + 미니 세계지도 (Wishlist & Mini World Map)

> 담당 iOS: `ios-social-collection`. 담당 QA: `qa-functional`. 다국어: `qa-localization`.

## 사용자 플로우

탭바 "위시리스트" → 매장 추가/삭제 → 국가별 그룹 → 상단 미니 세계지도(국가 핀 클러스터링).

## Given (전제)

- 사용자 로그인.
- `users/{uid}/wishlist/*` 컬렉션이 0~N개 보유 가능.
- 매장 fixture에 `country` 필드 존재 (KR/JP/US/GB/DE/FR).

## When (액션)

1. 탭바 "위시리스트" 탭 → `WishlistScreen` 진입.
2. 빈 상태 — "아직 위시 매장이 없습니다 + 지도에서 추가" CTA 표시 (E2).
3. 사용자가 별도 플로우(StoreDetail의 하트 버튼)로 매장 5개 위시 추가:
   - 한국 매장 2개, 일본 매장 2개, 미국 매장 1개.
4. 위시리스트 화면 새로고침.
5. 상단에 미니 세계지도 — 국가별 카운트 핀(KR:2 / JP:2 / US:1) 클러스터링.
6. 하단 리스트는 국가별 섹션 (KR → JP → US, alphabetic 또는 카운트 desc).
7. 한 매장의 하트 토글 → 즉시 제거(낙관적) → 카운트 갱신.

## Then (검증)

- [ ] 미니 세계지도가 상단 1/3 영역에 표시.
- [ ] 국가 핀이 클러스터링 — 국가에 매장 2개면 핀 라벨 "2".
- [ ] 핀 탭 시 해당 국가 섹션으로 스크롤 (앵커 점프).
- [ ] 매장 카드는 이름/평균/주소/하트(채움).
- [ ] 위시 제거 시 즉시 UI 반영 + Firestore delete (낙관적 + 실패 롤백).
- [ ] 위시리스트는 자동 동기화 (Firestore listener).

## Edge cases

| ID | 상황 | 기대 동작 |
|---|---|---|
| E1 | 위시 0개 | 빈 상태 카피 + "지도에서 매장 둘러보기" CTA, 미니지도 hide |
| E2 | 같은 국가 다중 (KR 10개) | 클러스터 핀 라벨 "10", 탭 시 KR 섹션 점프 |
| E3 | 6개 국가 모두 | 미니지도 핀 6개, 시야는 world fit |
| E4 | 위시 100+ | 페이지네이션 (50씩 lazy load) |
| E5 | 네트워크 끊김 중 추가 | 큐 보관 + 복구 시 sync |
| E6 | 같은 매장 더블 탭(중복 추가) | 멱등 — Firestore set이 동일 ID 덮어씀 |
| E7 | 다른 디바이스에서 변경 | listener로 5초 내 자동 갱신 |
| E8 | 국가 미상(`country == nil`) | "기타" 섹션으로 분류 |

## 예상 회귀 위험도

**P1** — 핵심 retention 기능. FAIL 시 머지 가능, 다음 스프린트 fix.

## 다국어 영향

- 국가명 6개 언어: KR/JP/US/GB/DE/FR (시스템 locale 기반 `Locale.localizedString(forRegionCode:)`).
- 빈 상태 카피, 섹션 헤더 카운트 ("매장 N개"), 토스트 6개 언어.
- 독일어 "Wunschliste"가 가장 길음 — 탭 라벨 잘림 검증.

## 접근성

- VoiceOver: 미니지도 핀 "{국가명} 위시 매장 {n}개, 두 번 탭하여 섹션 보기".
- VoiceOver: 매장 카드 "{매장명}, {국가}, 별점 {n.n}, 하트 채움, 두 번 탭하여 제거".
- Dynamic Type: 카드 높이 확장.
- 하트 버튼은 최소 44x44pt 터치 영역.

## 사인오프

| 일자 | 빌드 | 결과 | 비고 |
|---|---|---|---|
| TBD | TBD | TBD | Phase 3: WishlistView mock — 국가 그룹/미니지도 PASS |
