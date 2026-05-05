# 시나리오: 피드 + 친구 활동 (Feed & Friend Activity)

> 담당 iOS: `ios-social-collection`. 담당 QA: `qa-functional`. 다국어: `qa-localization`.
> 부속 모듈: `server-functions` (fanout), `server-data` (feed events).

## 사용자 플로우

탭바 "피드" → 친구 활동(리뷰/도감 잠금 해제/위시 추가) feed event → 카드 탭 → 댓글/좋아요.

## Given (전제)

- 사용자 로그인 + 친구 fixture ≥ 1 (양방향 follow `users/{uid}/friends/*`).
- 친구의 피드 이벤트 fixture (리뷰 작성, 도감 unlock, 위시 추가, 메모리 작성).
- Cloud Functions fanout이 친구의 활동을 본인 `users/{uid}/feed`에 복제.

## When (액션)

1. 탭바 "피드" 탭 → `FeedScreen` 진입.
2. 상단 새로고침 인디케이터 → 최신 이벤트 fetch.
3. 카드 형태로 친구 활동 표시:
   - 리뷰 카드: 친구 아바타 + "님이 {매장명}에 리뷰를 썼어요" + 별점/본문 발췌 + 사진 1.
   - 도감 카드: "님이 {매장명}을 도감에 등록했어요" + 매장 이미지.
   - 위시 카드: "님이 {매장명}을 위시리스트에 담았어요".
4. 카드 1개 탭 → 매장 상세로 이동.
5. 카드 좋아요 버튼 탭 → 카운트 +1 (낙관적 + 햅틱).
6. 카드 댓글 입력창 탭 → 인풋 시트 → "맛있겠다" 입력 → 등록.
7. 댓글이 카드 하단에 즉시 prepend.

## Then (검증)

- [ ] 피드 이벤트는 시간 desc 정렬 (최신 먼저).
- [ ] 카드 타입 4종 모두 정상 렌더 (리뷰/도감/위시/메모리).
- [ ] 좋아요/댓글 낙관적 업데이트 + 실패 롤백.
- [ ] 무한 스크롤 — 20개씩 lazy load.
- [ ] 새로고침 pull-to-refresh 동작.
- [ ] 자기 활동은 피드에 미노출 (또는 별도 "내 활동" 탭).

## Edge cases

| ID | 상황 | 기대 동작 |
|---|---|---|
| E1 | 친구 0명 | 빈 상태 "친구를 추가하면 활동이 보입니다 + 친구 찾기" CTA |
| E2 | fanout 지연 (10s+) | "잠시 후 새 활동이 표시됩니다" 안내 + 폴링 |
| E3 | 차단된 친구 활동 | 피드에서 자동 제외 |
| E4 | 본인이 차단당한 경우 | 해당 친구 카드 숨김 |
| E5 | 친구가 삭제한 매장/리뷰 | 카드 자동 숨김 또는 "삭제됨" 처리 |
| E6 | 100+ 친구 | fanout 큐가 N개로 분배 (server-functions 책임) |
| E7 | 네트워크 끊김 | 캐시된 마지막 페이지 + 배너 |
| E8 | 댓글 1000자 초과 | 1000자 캡 |
| E9 | 부적절 댓글 | 모더레이션 함수 hide 처리 |
| E10 | 좋아요 빠른 연타 | debounce 200ms — 1회만 적용 |

## 예상 회귀 위험도

**P1** — Day-7 retention 핵심. FAIL 시 머지 가능, 다음 스프린트 fix.

## 다국어 영향

- 카드 카피 6개 언어:
  - "{name}님이 {store}에 리뷰를 썼어요" / "{name} reviewed {store}" / ...
  - 일본어/프랑스어 어순 다름 — 자연스러운 i18n 패턴 (`String.localizedStringWithFormat`).
- 빈 상태 카피, 좋아요/댓글 라벨, 시간 표기 ("3분 전", "3 min ago", "vor 3 Min").
- RelativeDateTimeFormatter 6개 언어.

## 접근성

- VoiceOver: 카드는 "{name}, {활동 타입}, {매장명}, 좋아요 {n}개, 댓글 {n}개, 두 번 탭하여 자세히".
- VoiceOver: 좋아요 버튼 상태(눌림/안눌림).
- Dynamic Type: 카드 높이 확장.
- Reduce Motion: 카드 등장 애니메이션 즉시 표시.

## 사인오프

| 일자 | 빌드 | 결과 | 비고 |
|---|---|---|---|
| TBD | TBD | TBD | Phase 3: FeedView mock — 카드 4종 렌더 PASS, fanout은 Phase 5 |
