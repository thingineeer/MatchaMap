/**
 * MatchaMap Cloud Functions entry — 모든 함수 re-export.
 *
 * 정책:
 *   - region: asia-northeast3 (ADR-301).
 *   - 콜러블: enforceAppCheck=true + Auth 토큰 강제.
 *   - 백그라운드: 540s timeout, 512MiB memory.
 *
 * 배포:
 *   firebase deploy --only functions
 *
 * 부분 배포 (특정 함수만):
 *   firebase deploy --only functions:verifyRewardedAd
 */
import { setGlobalOptions } from 'firebase-functions/v2';

import { DEFAULT_REGION } from './utils/region.js';

setGlobalOptions({ region: DEFAULT_REGION });

// Auth blocking trigger
export { onUserCreated } from './auth/onUserCreate.js';

// Feed fanout
export { fanoutFeedEvent } from './feed/fanoutFeedEvent.js';

// Ads — server-side rewarded verification
export { verifyRewardedAd } from './ads/verifyRewardedAd.js';

// Moderation
export { checkReviewContent } from './moderation/checkReviewContent.js';

// Search
export { mergeStoreSearch } from './search/mergeStoreSearch.js';

// Scheduler
export { aggregatePopularStores } from './scheduler/aggregatePopularStores.js';
