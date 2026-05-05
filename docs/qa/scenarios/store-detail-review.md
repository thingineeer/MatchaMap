# 시나리오: 매장 상세 + 리뷰 작성 (Store Detail & Review)

> 담당 iOS: `ios-store`. 담당 QA: `qa-functional`. 다국어: `qa-localization`.
> 부속 모듈: `server-data` (Firestore review write), `server-functions` (모더레이션 함수).

## 사용자 플로우

지도 핀 → StoreDetailScreen → "리뷰 쓰기" → 별점/본문/사진/태그 입력 → 등록 → 리뷰 카드 첫 번째 표시.

## Given (전제)

- 사용자는 로그인 + 위치 권한 부여 완료.
- 매장 fixture(`storeId = "ST-DEMO-001"`)에 기존 리뷰 ≥ 1 존재.
- 사용자 본인은 같은 매장에 미리뷰 상태.
- 사진 라이브러리에 jpeg 3장 이상 존재.

## When (액션)

1. 지도 핀 탭 → StoreDetailScreen 진입.
2. 매장 헤더(이름/평균/카테고리) + 메뉴 ≥ 3 + 리뷰 리스트 표시 확인.
3. 우상단 "리뷰 쓰기" CTA 탭 → `ReviewWriteScreen` push.
4. 별점 5개 탭 (애니메이션 + 햅틱).
5. 본문 입력: "오모테나시 진하고 그릇 따뜻함" (32자).
6. 사진 추가 버튼 탭 → 시스템 시트 → 3장 선택 → 썸네일 표시.
7. 태그 칩 탭(예: "#진한맛", "#좌석많음", "#와이파이").
8. "등록" 버튼 탭.
9. 진행 인디케이터 → 성공 토스트 → StoreDetailScreen 복귀.

## Then (검증)

- [ ] 리뷰 카드 리스트 첫 번째에 신규 리뷰 표시 (별 5, 본문, 사진 3, 태그 3).
- [ ] 매장 평균 별점이 즉시 갱신(낙관적 업데이트).
- [ ] Firestore `stores/{storeId}/reviews/{reviewId}` 문서 생성.
- [ ] Storage `reviews/{reviewId}/{0..2}.jpg` 업로드 완료.
- [ ] 모더레이션 함수가 비동기로 실행 (Phase 5 검증).
- [ ] 작성 직후 다른 디바이스/계정에서 새로고침 시 동일 리뷰 노출.

## Edge cases

| ID | 상황 | 기대 동작 |
|---|---|---|
| E1 | 별점 0 | "등록" 버튼 disabled, 별점 그룹에 inline 안내 |
| E2 | 본문 빈칸 (또는 < 5자) | "등록" 버튼 disabled, 본문 필드 inline 안내 |
| E3 | 사진 0장 | 등록 가능 (사진은 옵션) |
| E4 | 사진 3장 중 1장 업로드 실패 | 부분 성공 — 실패 사진만 재시도 다이얼로그 + 리뷰 본체는 성공 |
| E5 | 사진 5장 초과 시도 | 5번째 추가 시 에러 토스트 + 4장 캡 |
| E6 | 본문 1000자 초과 | 카운터 빨강 + 등록 disabled |
| E7 | 부적절 콘텐츠(욕설) | 모더레이션 함수가 hide 플래그 → 본인은 보이나 타인은 hidden |
| E8 | 네트워크 끊김 중 등록 | 큐에 보관 + 복구 시 자동 재전송 (Phase 5 OfflineQueue) |
| E9 | 같은 매장에 두 번째 리뷰 시도 | "이미 작성한 리뷰가 있습니다 — 수정하시겠어요?" 다이얼로그 |
| E10 | 별점만 5, 본문 빈칸 | E2 적용 — disabled |

## 예상 회귀 위험도

**P0** — 핵심 작성 플로우. FAIL 시 머지 차단.

## 다국어 영향

- 6개 언어 String Catalog: 별점 안내, 본문 placeholder, 태그 칩 라벨, 사진 추가 라벨, 진행/성공/에러 토스트.
- 태그 칩은 i18n 카탈로그 또는 매장 자체가 다국어 mapping 보유 (`tags.localized.{locale}`).
- 독일어/프랑스어 본문 placeholder가 1줄 내 fit하는지 검증.

## 접근성

- VoiceOver: 별점은 "별점, 5개 중 {n}개 선택, 두 번 탭하여 변경".
- VoiceOver: 사진 썸네일은 "사진 {i}/3, 두 번 탭하여 삭제".
- Dynamic Type: 본문 입력창은 텍스트 크기에 따라 높이 확장.
- Reduce Motion: 별점 애니메이션 즉시 반영(스프링 제거).
- Voice Control: 모든 CTA가 음성 라벨 일치 ("등록", "사진 추가", "별점 5").

## 사인오프

| 일자 | 빌드 | 결과 | 비고 |
|---|---|---|---|
| TBD | TBD | TBD | Phase 3: ReviewWriteScreen mock 등록 동작만 PASS |
