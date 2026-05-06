# ADR-304 — Guest Mode + Auth Gating Policy (Phase 3.5)

| 항목 | 값 |
|---|---|
| Status | Accepted |
| Date | 2026-05-05 |
| Owner | ios-lead |
| Reviewers | po-lead, server-lead, server-auth |
| Supersedes | (none — extends ADR-303 §App Check / Auth) |

## 1. Context

기존 1.0.0 RootView는 `splash → login → main` 강제 라우팅. 미로그인 사용자는 지도조차 볼 수 없음.

PO/Growth 검토 결과:
- "지도 보기 → 매장 검색 → 위시리스트 N개 추가"까지 **로그인 없이** 체험시켜야 D0 활성화·전환율이 의미 있는 수준이 됨.
- 다만 **소셜·기록형(리뷰/도감/친구/푸시)** 기능은 식별된 사용자 자원이라 익명 허용 시 무결성·moderation·랭킹 abuse 우려.
- AdMob 보상형(도감 슬롯 unlock)은 대가 지급 자원이라 영구 식별 필요(rewardedReceipts replay 방지).

## 2. Decision — 옵션 B (관대한 게이팅 + 사용자 관련 = 로그인) + 미세조정

### 2.1 매트릭스

| 기능 | 게스트 | 로그인 필요 |
|---|---|---|
| 지도 + 마커 + 클러스터링 | OK | — |
| 매장 상세 / 메뉴 / 사진 / 영업시간 | OK | — |
| 매장 사진 풀스크린 | OK | — |
| 검색 / 필터 | OK | — |
| 매장 리뷰 **읽기** (작성자 이름·아바타 노출) | OK (read-only) | — |
| 매장 리뷰 **작성/수정/삭제** | — | YES |
| 위시리스트 (1~5개, 로컬) | OK (cap 5) | — |
| 위시리스트 6번째 추가 | — | YES |
| 도감 (수집/메모리/뱃지) | — | YES |
| 친구 / 친구요청 / 피드 | — | YES |
| 푸시 토큰 등록 | — | YES |
| 보상형 광고 (도감 잠금 해제) | — | YES |
| 다른 사용자 프로필 페이지 | — | YES |
| 4번째 탭 (내정보) | — | YES |

### 2.2 위시리스트 게스트 cap

`guestCap = 5`. 6번째 추가 시 LoginIntent.wishlistCap 시트 트리거. 로컬 저장은 `UserDefaults(suiteName: "matchamap.guest")` Codable. 로그인 직후 `migrateLocalToFirestore()`가 `WishlistRepository.batchAdd(storeIds:)`로 일괄 전환.

### 2.3 Firebase Anonymous Auth — 사용 (권장)

- 게스트도 Firebase 익명 UID 발급 → Firestore에 게스트 위시리스트가 **언젠가** 동기화 가능 (선택 기능; v1.0.0은 로컬만, v1.1+에서 익명 클라우드 미러링 검토).
- Apple 로그인 시 `Auth.auth().currentUser?.link(with:appleCredential)` (= `linkWithCredential`)로 **익명 UID 그대로 정식 사용자 전환** → 데이터 보존 + UID 안정성.
- 익명 UID 발급은 비용 0, App Check 통과 가능.

### 2.4 정식/익명 구분 가드 — Functions

JWT 클레임 `req.auth.token.firebase.sign_in_provider`가 `'anonymous'`이면 식별자원 변경 거부. `assertNotAnonymous(req)` 헬퍼 신설. 다음 5개 콜러블에 적용:

1. `submitReview`
2. `addCollectionItem`
3. `requestFriend`
4. `acceptFriend`
5. `verifyRewardedAd`

(`removeFriend`는 동일 가드 추가 — 친구 관계는 정식 사용자 자원.)

새 `ErrorCodes.AUTH_ANONYMOUS_FORBIDDEN` 추가. 클라는 본 코드 수신 시 `LoginIntent`를 띄움.

### 2.5 Firestore Rules 업데이트

| 컬렉션 | 익명 read | 익명 write | 정식 read | 정식 write |
|---|---|---|---|---|
| `users/{uid}` | self | self (create는 onCreate 트리거가 함) | self | self |
| `stores/{placeId}` | OK | — | OK | — |
| `reviews/{reviewId}` | OK | **거부** (정식 only) | OK | self-author |
| `wishlists/{uid}/items` | self | self | self | self |
| `collections/{uid}/items` | **거부** | — | self | onCall only |
| `likes/{reviewId}/users/{uid}` | OK | **거부** | OK | self |
| `friendships/*` | **거부** | — | self | onCall |
| `feed_events/*` | **거부** | — | audience | — |
| `rewardedReceipts/*` | — | — | — | onCall |

`anonymous` 분기 룰: `request.auth.token.firebase.sign_in_provider != 'anonymous'`를 `isFullyAuthed()` 헬퍼로 도입.

### 2.6 LoginIntent — 시트 띄우는 컨텍스트

```swift
public enum LoginIntent: String, Identifiable, Sendable, CaseIterable {
    case review            // 리뷰 작성/수정/삭제
    case collectionUnlock  // 도감 시작/슬롯 해제
    case wishlistCap       // 위시리스트 6번째
    case friend            // 친구 요청
    case profile           // 내정보 탭 / 다른 프로필
    case push              // 푸시 권한
    case rewarded          // 보상형 광고
    public var id: String { rawValue }
}
```

각 intent별로 LoginView 헤더 카피 변경.

## 3. Migration 패턴

```
[Anonymous UID: "anon_abc"]
   → Apple Sign In success
   → Auth.auth().currentUser.link(with: appleCredential)
   → 결과: 동일 UID "anon_abc"가 Apple 자격증명을 보유
   → users/anon_abc 도큐먼트 onCreate 트리거 발화 (authMethod=apple)
   → wishlists/anon_abc/items/* 그대로 보존
   → 클라 메모리에서 isAuthenticated=true로 전환
```

Apple identityToken으로 이미 로그인된 사용자가 게스트 모드로 다시 진입할 경우(드물): `unlink` 미지원 — `signOut` 후 `signInAnonymously` 새 UID 발급.

## 4. Domain 모델

```swift
public enum AuthState: Sendable, Equatable {
    case loading
    case guest(anonymousUid: String?)
    case authenticated(AppUser)
}
```

`AuthRepository`에 추가:
- `currentAuthState() async -> AuthState`
- `signInAnonymously() async throws -> String` (익명 UID 반환)
- `linkAnonymousToApple(identityToken:nonce:fullName:) async throws -> AppUser`

## 5. Firebase Console 활성화

본 ADR 적용 전제: **Firebase Console → Authentication → Sign-in method → Anonymous = Enabled**. 활성화는 사용자(human) 수동 1클릭. iOS 코드는 enabled 상태 가정.

## 6. Test Plan

- `WishlistViewModelTests`: 게스트 + 5개일 때 `add()` 호출 → `onRequireLogin` 콜백 발화, items 미증가.
- `WishlistViewModelTests`: 게스트 시 UserDefaults에 저장된 items 복원.
- `ReviewWriteViewModelTests`: `authState=.guest` 시 `canSubmit == false` + `submit()` 시 `onRequireLogin(.review)` 호출.
- `CollectionGridViewModelTests`: 게스트 시 `onAppear` 즉시 `state == .guestRequired` (네트워크 호출 없음).
- `firestore.rules` emulator: 익명 토큰으로 `reviews` create 시 거부, `wishlists/{uid}/items` create는 통과.
- Functions emulator: `submitReview` with `sign_in_provider=anonymous` → `permission-denied` + `code=AUTH_ANONYMOUS_FORBIDDEN`.

## 7. Rollout

- v1.0.0 출시 시 본 정책 활성. 게스트 cap=5는 분석 후 v1.0.1에서 ±조정 가능 (코드 상수만 변경, ADR 갱신 필요).
- 익명 UID에 대한 BigQuery cohort 분리 키: `users.authMethod` 외 `is_anonymous` boolean 컬럼 추가 검토 (v1.1).

## 8. References

- ADR-303 App Check & Security Rules
- Apple HIG iOS 26 — Onboarding & Account
- Firebase Auth: Anonymous + linkWithCredential docs
- handoff/handoff-mapping.md §1, §10, §13
