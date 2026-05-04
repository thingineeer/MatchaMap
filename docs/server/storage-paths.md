# Storage Paths — Cloud Storage 경로 컨벤션

- **작성**: `server-auth` · 2026-05-04
- **상태**: Phase 2 — ADR-303 §3 산출물
- **SSOT**: docs/server/schema.md (`reviews.photos`, `collections/items.photos`)
- **rules 파일**: [storage.rules](../../storage.rules)

## 1. 버킷

- 단일 버킷: `matchamapapp.firebasestorage.app` (Firebase 기본).
- 리전: `asia-northeast3` (ADR-301 정합).
- 무료 한도 적용 안 됨(Storage 무료 quota는 us-* 버킷만). 비용 = $0.026/GB·월.

## 2. 경로 명세

| 경로 | 용도 | 사이즈 | MIME | 소유권 | 한도 |
|---|---|---|---|---|---|
| `users/{uid}/profile.jpg` | 프로필 사진(jpeg) | 1 MB | image/jpeg | self | 1장 |
| `users/{uid}/profile.png` | 프로필 사진(png) | 1 MB | image/png | self | 1장 |
| `users/{uid}/collection/{itemId}/{n}.jpg` | 도감 사진 (n=0..2) | 3 MB | image/jpeg \| image/heic | self | 3장/도감 |
| `reviews/{reviewId}/{n}.jpg` (n=0..3) | 리뷰 사진 | 5 MB | image/jpeg \| image/heic | 작성자 (signed URL) | 4장/리뷰 (schema.md §3.1) |
| `stores/{placeId}/cover/{n}.jpg` | 매장 커버 | 5 MB | image/jpeg | Admin SDK only | 큐레이터 입력 |
| `thumbnails/{path}/256.jpg` | 썸네일 (Functions 자동 생성) | 200 KB | image/jpeg | 읽기 전용 | 1장/원본 |

## 3. 업로드 흐름

### 3.1 프로필 사진 (직접 업로드)

```
iOS 클라: UIImage → JPEGData(compressionQuality: 0.8) → Firebase Storage upload(path: "users/{uid}/profile.jpg")
Storage Rules: isSelf(uid) + sizeUnder(1MB) + isImageJpeg() 검증.
완료 후: users/{uid}.photoURL = "gs://.../users/{uid}/profile.jpg" 갱신.
```

### 3.2 도감 사진 (직접 업로드)

```
iOS 클라: 사진 선택 → 1024px 리사이즈(클라) → JPEG/HEIC → upload("users/{uid}/collection/{itemId}/{n}.jpg")
완료 후: 콜러블 addCollectionItem 호출 시 photos[] 배열에 gs:// path 포함.
```

### 3.3 리뷰 사진 (signed URL 패턴 — ADR-303 §3.2 옵션 A)

```
iOS 클라: 콜러블 requestReviewPhotoUploadURL(reviewId, photoIdx)
  → server-functions가 reviewId 작성자 == auth.uid 확인 + 5분 TTL signed URL 발급
iOS 클라: signed URL로 PUT 업로드
완료 후: 콜러블 submitReview에서 photos[] 배열로 gs:// path 포함.
```

→ Storage Rules는 사이즈/MIME만 검증 (작성자 검증은 signed URL 발급 시 Functions가 1회).

### 3.4 매장 커버 (관리자 업로드)

- 큐레이터가 Firebase Console 또는 별도 어드민 도구로 Admin SDK 업로드.
- 클라 직접 write 차단.

## 4. 썸네일 자동 생성 (server-functions Phase 2-3)

`onObjectFinalized` 트리거 (Storage extension 또는 자체 Functions):

- 입력: `reviews/{reviewId}/{n}.jpg`, `users/{uid}/profile.jpg`, `users/{uid}/collection/{itemId}/{n}.jpg`.
- 출력: `thumbnails/<원본 path>` (256px, JPEG, ~30KB).
- 트리거 조건: contentType이 image/* 이고 path가 `thumbnails/`로 시작하지 않음.
- 비용: 사진당 1회 invocation + 30KB 추가 storage. cost-projection.md § 8 추가.

## 5. 사이즈 정책 근거

### 5.1 프로필 1MB

- iPhone 카메라 원본 ~3MB. 1024px 리사이즈 후 JPEG 0.8 품질 ≈ 200~600KB.
- 1MB 한도는 안전 마진 + UX 품질 보장.

### 5.2 도감 3MB

- 사용자 메모리 가치(시그니처 카드) → 약간 큰 사이즈 허용.
- 1280px 리사이즈 후 HEIC ≈ 800KB~2MB.

### 5.3 리뷰 5MB

- 매장 분위기/메뉴 사진은 풍부한 디테일 필요.
- 1920px 리사이즈 후 HEIC ≈ 1.5~4MB.

## 6. 보존 정책

| 자원 | 보존 |
|---|---|
| `users/{uid}/profile.{jpg,png}` | 사용자 변경 시 덮어쓰기, 계정 삭제 시 삭제 |
| `users/{uid}/collection/{itemId}/...` | 사용자 명시 삭제 또는 계정 삭제 시 삭제 |
| `reviews/{reviewId}/...` | 리뷰 삭제 또는 계정 삭제 시 삭제 |
| `stores/{placeId}/cover/...` | 매장 deactivate 시에만 admin이 정리 (자동 삭제 X) |
| `thumbnails/{path}/256.jpg` | 원본 삭제 시 onObjectDeleted 트리거가 함께 삭제 |

## 7. CDN / Cache-Control

- Firebase Storage는 자동 CDN 제공 (Cloud CDN).
- 업로드 시 metadata `cacheControl: public, max-age=86400` 설정 (1일).
- 변경 시 새 path 사용 (예: 프로필 변경은 같은 path 덮어쓰기 → 캐시 invalidation 필요할 경우 `?v=<ts>` query 추가).

## 8. 비용 (cost-projection.md §3 정합)

| 시나리오 | Storage 누적 | 월 비용 |
|---|---|---|
| MAU 1K (TestFlight) | ~130 MB | $0.00 |
| MAU 10K | ~2.6 GB (2개월) | $0.07 |
| MAU 100K | ~79 GB (6개월) | $2.05 |

→ Storage 자체는 비용 영향 미미. 주된 비용은 download bandwidth ($0.15/GB).

## 9. Open Items

- [ ] **STO-1**: 썸네일 변환 함수 구현 (server-functions Phase 2-3).
- [ ] **STO-2**: HEIC → JPEG 자동 변환 정책 (브라우저/구형 디바이스에서 HEIC read 호환성).
- [ ] **STO-3**: 사용자 데이터 export (GDPR Right to Portability) — Storage 객체를 zip으로 묶어 사용자에 다운로드 제공 (Phase 3+).

## 10. 변경 이력

| 일자 | 변경 | 작성자 |
|---|---|---|
| 2026-05-04 | 초안 (5개 경로 + 썸네일) | server-auth |
| 2026-05-04 | 도감 사진 경로를 schema.md SSOT 정합으로 `users/{uid}/collection/...`로 정정 | server-auth |
