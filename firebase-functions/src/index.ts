/**
 * MatchaMap Cloud Functions entry — 모든 함수 re-export.
 *
 * 정책:
 *   - region: asia-northeast3 (ADR-301).
 *   - 콜러블: enforceAppCheck=true + Auth 토큰 강제.
 *   - 백그라운드: 540s timeout.
 *   - schema.md §0~§9 / ADR-302 § Functions 표 1:1 정합.
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

// Domain callables (트랜잭션 fanout 책임자)
export { addCollectionItem } from './collections/addCollectionItem.js';
export { submitReview } from './reviews/submitReview.js';
export { acceptFriend, removeFriend, requestFriend } from './friends/friends.js';

// Ads — server-side rewarded verification
export { verifyRewardedAd } from './ads/verifyRewardedAd.js';

// Search
export { mergeStoreSearch } from './search/mergeStoreSearch.js';

// Background — feed audit + 디노멀 fanout + pinTier derive
export { fanoutFeedEvent } from './feed/fanoutFeedEvent.js';
export { onUpdateUser } from './fanout/onUpdateUser.js';
export { onUpdateStore } from './fanout/onUpdateStore.js';
export {
  onCreateStorePinTier,
  onUpdateStorePinTier,
} from './stores/derivePinTierTriggers.js';

// Notifications (FCM)
export { onWriteFcmToken } from './notifications/onWriteFcmToken.js';
// sendNotificationToUser: 헬퍼 (트리거 X). reviews/friends/feed 콜러블이 호출.

// Moderation
export { checkReviewContent } from './moderation/checkReviewContent.js';

// Schedulers
export { aggregatePopularStores } from './scheduler/aggregatePopularStores.js';
export { cleanupFeedEvents } from './scheduler/cleanupFeedEvents.js';
export { cleanupAnalyticsEvents } from './scheduler/cleanupAnalyticsEvents.js';
export { cleanupStaleFcmTokens } from './scheduler/cleanupStaleFcmTokens.js';
export { recomputeStoreAggregates } from './scheduler/recomputeStoreAggregates.js';
export { purgeDeletedUsers } from './scheduler/purgeDeletedUsers.js';
