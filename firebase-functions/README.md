# MatchaMap — Cloud Functions for Firebase

> 2nd gen, TypeScript, region `asia-northeast3` (Seoul). Owner: `server-functions`.

말차맵 서버 사이드 trust-boundary 로직. 클라이언트가 직접 Firestore에 접근 가능한
read 작업은 Functions를 거치지 않는다. **fanout / 검색 보강 / 광고 검증 / 모더레이션 /
스케줄러**만 본 디렉토리에 둔다.

## 디렉토리 구조

```
firebase-functions/
├── src/
│   ├── auth/       onUserCreate.ts          # Auth blocking trigger → users/{uid} 시드
│   ├── feed/       fanoutFeedEvent.ts       # feedEvents → friends fanout
│   ├── ads/        verifyRewardedAd.ts      # AdMob SSV 영수증 검증 + 도감 슬롯 해제
│   ├── moderation/ checkReviewContent.ts    # 리뷰 모더레이션(텍스트/사진)
│   ├── search/     mergeStoreSearch.ts      # 자사 + Google Places 머지
│   ├── scheduler/  aggregatePopularStores.ts# 매시 인기 매장 집계
│   ├── utils/      region.ts logger.ts admin.ts appCheck.ts auth.ts errors.ts
│   └── index.ts                              # 모든 함수 re-export
├── test/                                     # vitest 테스트
├── package.json
├── tsconfig.json
├── vitest.config.ts
└── .eslintrc.json .prettierrc
```

## 정책 (변경 시 ADR-301 + server-lead 사인오프 필요)

- **리전**: `asia-northeast3`. `setGlobalOptions({ region })` + 각 함수 옵션 모두 강제.
- **콜러블**: `enforceAppCheck: true` + 본문에서 `assertAppCheck` + `assertAuthenticated` 호출.
- **타임아웃**: 콜러블 30s, 백그라운드 540s. 콜러블에서 ≥ 10s 작업은 백그라운드 큐로 분리.
- **로깅**: `utils/logger.ts`의 `logInfo/logWarn/logError`만 사용. PII 금지(`uid`만 OK).
- **시크릿**: `defineSecret(...)` 패턴. 코드 하드코딩 금지. 등록은
  `firebase functions:secrets:set <NAME>`.

## 시작 절차 (로컬 개발)

```bash
# 1) 의존성
npm install

# 2) 타입 체크 + lint
npm run typecheck
npm run lint

# 3) 단위 테스트 (emulator 불필요)
npm test

# 4) emulator 통합 테스트
firebase emulators:start --only firestore,auth
# 다른 터미널:
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
GCLOUD_PROJECT=matchamapapp-test \
  npm test

# 또는 한 번에:
npm run test:emulator
```

## 배포

```bash
# 빌드
npm run build

# 전체 배포
firebase deploy --only functions

# 부분 배포 (특정 함수만)
firebase deploy --only functions:verifyRewardedAd
```

> 배포 권한은 `server-lead` 사인오프 후. CI/CD 통합은 Phase 3 (fastlane 또는 GitHub Actions).

## 시크릿 관리

- 모든 외부 API 키는 Functions Secret Manager.
- 등록 (배포 환경):
  ```bash
  firebase functions:secrets:set ADMOB_SSV_PUBLIC_KEY
  firebase functions:secrets:set GOOGLE_PLACES_API_KEY
  ```
- 함수에서 사용:
  ```ts
  const KEY = defineSecret('ADMOB_SSV_PUBLIC_KEY');
  export const fn = onCall({ secrets: [KEY] }, async (req) => {
    const value = KEY.value(); // 런타임에만 평문
  });
  ```
- 로컬 emulator는 시크릿 무시. mock 또는 .env로 우회 (실키 절대 금지).

## App Check

- Phase 2 진입 직후 1주는 **monitor 모드**: `MATCHAMAP_APPCHECK_MODE=monitor` 환경변수.
- Cloud Logging의 `app_check_missing` 카운터로 거부율 측정.
- 정상 거부율 확인 후 `enforce` 모드로 전환 (server-auth ADR-303).

## 함수 카탈로그

상세는 [`docs/server/api-contract.md`](../docs/server/api-contract.md) 참조.

| 함수 | 종류 | 트리거 | 책임 |
|---|---|---|---|
| `onUserCreated` | Auth blocking | beforeUserCreated | users/{uid} 문서 시드 |
| `fanoutFeedEvent` | Firestore trigger | feedEvents/{eventId} onCreate | 친구 피드 fanout (≤ 500) |
| `verifyRewardedAd` | Callable | client | 보상형 광고 영수증 검증 + 도감 슬롯 해제 |
| `mergeStoreSearch` | Callable | client | 자사 매장 + Places 머지 |
| `checkReviewContent` | Firestore trigger | reviews/{reviewId} onCreate | 텍스트/이미지 모더레이션 |
| `aggregatePopularStores` | Scheduler | every 1 hours (KST) | 24h 윈도우 인기 매장 집계 |

## 협업

| 대상 | 합의 항목 |
|---|---|
| `server-data` | feedEvents/users/reviews/stores 컬렉션 시그니처, 인덱스 (ADR-302) |
| `server-auth` | App Check enforce 시점, Auth provider, blocking trigger 정책 (ADR-303) |
| `ios-auth-monetize` | AdMob SSV callback URL, 영수증 transactionId 포맷 |
| `ios-social-collection` | feedEvents 작성 트리거 (클라 직접 vs 서버 콜러블) |

## TODO (Phase 3+)

- [ ] AdMob SSV callback HTTPS 함수(`verifyAdMobSsvCallback`) — 본 콜러블의 사전 단계.
- [ ] Perspective API + Vision SafeSearch 통합 (checkReviewContent).
- [ ] Storage `onObjectFinalized` — 사진 모더레이션 + EXIF 제거.
- [ ] Google Places 통합 (mergeStoreSearch) + placesCache TTL.
- [ ] 신규 매장 콜드 스타트 보정 (aggregatePopularStores +5 보정).
- [ ] 친구 ≥ 500 large-fanout 패턴 (worker queue).
- [ ] emulator CI 통합 (GitHub Actions, firebase-functions-test SDK 활용).
