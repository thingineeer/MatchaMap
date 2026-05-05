# 시나리오: 도감 + 메모리 페이지 (Collection Grid & Memory)

> 담당 iOS: `ios-social-collection`. 담당 QA: `qa-functional`. 다국어: `qa-localization`.
> 부속 모듈: `ios-auth-monetize` (보상형 광고 트리거).

## 사용자 플로우

탭바 "내 정보" → 도감 탭 → grid 빈 칸 탭 → 보상형 광고 → 칸 잠금 해제 → 메모리 작성.

## Given (전제)

- 사용자 로그인.
- 도감 fixture: 30칸 grid (5×6). 사용자가 5칸 잠금 해제 상태.
- AdMob SDK Phase 5 통합 — Phase 3은 stub fallback.

## When (액션)

1. 탭바 "내 정보" 탭 → `ProfileScreen` 진입.
2. 상단 사용자 헤더(아바타/이름/통계) + "도감 N/30" 진행률 카드.
3. "도감" 섹션 탭 → `CollectionGridView` push.
4. 5×6 grid — 잠금된 칸은 흐림(silhouette) + 자물쇠 아이콘.
5. 빈 칸 1개 탭 → "잠금 해제" 다이얼로그 표시 ("광고 시청 후 도감 칸 1개 잠금 해제하시겠어요?").
6. "광고 시청" 탭 → 보상형 광고 로드/재생 → 완료 콜백.
7. 칸이 reveal 애니메이션과 함께 잠금 해제 (silhouette → 매장 사진).
8. 해제된 칸 탭 → `MemoryPageView` 진입.
9. 메모리 작성: 매장명(자동) + 별점 + 한줄 메모 + 사진 1장 + 방문일.
10. "저장" → 도감 grid의 해당 칸이 "메모리 있음" 인디케이터로 갱신.

## Then (검증)

- [ ] 잠금 칸 silhouette + 자물쇠 정확히 표시.
- [ ] 광고 트리거는 사용자 명시 동의 후만 (자발적 시청).
- [ ] 광고 시청 완료 콜백 → reveal 애니메이션 (크로스페이드 600ms).
- [ ] 잠금 해제 카운트 +1 (`users/{uid}/collection/{id}.unlocked = true`).
- [ ] 메모리 페이지 저장 시 `users/{uid}/collection/{id}/memory` 문서 생성.
- [ ] grid 인디케이터가 즉시 갱신 (낙관적).

## Edge cases

| ID | 상황 | 기대 동작 |
|---|---|---|
| E1 | 광고 로드 실패 (No fill) | fallback — 다이얼로그 "광고 로드 실패. 잠시 후 다시 시도" + 잠금 유지 |
| E2 | 광고 시청 중도 이탈 | 보상 미지급 + "끝까지 시청해야 잠금 해제" 안내 |
| E3 | 도감 0칸 잠금 해제 | 진행률 0/30, "지도에서 매장 방문 시 도감 후보 추가" 안내 |
| E4 | 도감 30/30 만점 | "마스터 배지" 노출 + 광고 비활성 |
| E5 | 메모리 작성 중 네트워크 끊김 | 로컬 저장 + 복구 시 sync |
| E6 | 같은 칸을 두 번 잠금 해제 시도 | UI상 잠금 해제 칸은 "잠금 해제" 다이얼로그 미표시 — 메모리 페이지 직접 진입 |
| E7 | 첫 60초 이내 광고 호출 | App Store 정책 준수 — 호출 차단 + "조금 후 다시 시도" |
| E8 | iPad 가로 모드 | grid 8×N 재배치 |
| E9 | 메모리 사진 업로드 실패 | E4 of store-detail-review와 동일 — 부분 성공 |

## 예상 회귀 위험도

**P0** (광고 정책) / **P1** (도감 자체) — 광고 정책 위반은 출시 차단.

## 다국어 영향

- 도감 진행률 ("도감 {n}/30", "{n} of 30 unlocked", "Sammlung {n}/30", "図鑑 {n}/30", "Collection {n}/30").
- 잠금 해제 다이얼로그 카피, 광고 시청 CTA, reveal 후 토스트.
- 메모리 페이지: 별점, "한줄 메모", "방문일" 입력 필드 라벨.

## 접근성

- VoiceOver: 잠금 칸 "잠금 칸 {i}, 광고 시청 후 잠금 해제 가능, 두 번 탭".
- VoiceOver: 잠금 해제 칸 "도감 {n}: {매장명}, 메모리 {유/무}, 두 번 탭하여 보기".
- Reduce Motion: reveal 애니메이션 dimming만 (크로스페이드 1배속).
- Dynamic Type: grid 칸은 셀 사이즈 고정이지만 라벨은 확장.
- 광고 시청 동의 카피 명확 (오해 방지).

## 사인오프

| 일자 | 빌드 | 결과 | 비고 |
|---|---|---|---|
| TBD | TBD | TBD | Phase 3: CollectionGridView/MemoryPageView mock PASS, 보상형 stub |
