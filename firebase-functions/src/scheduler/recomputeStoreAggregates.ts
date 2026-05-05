import { FieldValue } from 'firebase-admin/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { db } from '../utils/admin.js';
import { logInfo, logWarn } from '../utils/logger.js';
import { derivePinTier } from '../utils/pinTier.js';
import { DEFAULT_REGION } from '../utils/region.js';

/**
 * `stores.{reviewCount, ratingAvg, ratingHistogram}` drift 보정.
 *
 * 매시 정각 실행 (cost-projection §5 절감 레버 — 디노멀 drift 보정).
 *
 * 트리거 시나리오:
 *   - submitReview 트랜잭션 실패가 부분 성공으로 끝나 stores aggregate가 drift된 경우.
 *   - 리뷰 삭제(soft delete)가 stores aggregate에 반영 안 된 경우.
 *
 * 정책:
 *   - 모든 매장 일괄 재계산은 비용 高 → 직전 1시간 활성 매장만 (reviews.createdAt > 1h ago의
 *     storeId distinct).
 *   - 비활성 매장은 일 1회 KST 05:00에 별도 풀 스캔 (TODO Phase 3).
 */
export const recomputeStoreAggregates = onSchedule(
  {
    schedule: 'every 1 hours',
    timeZone: 'Asia/Seoul',
    region: DEFAULT_REGION,
    timeoutSeconds: 540,
    memory: '512MiB',
  },
  async () => {
    const since = new Date(Date.now() - 60 * 60 * 1000);
    try {
      const recentReviewsSnap = await db()
        .collection('reviews')
        .where('createdAt', '>=', since)
        .limit(2000)
        .get();
      const storeIds = new Set<string>();
      for (const d of recentReviewsSnap.docs) {
        const r = d.data() as { storeId?: string };
        if (r.storeId) storeIds.add(r.storeId);
      }

      let recomputed = 0;
      for (const storeId of storeIds) {
        await recomputeOne(storeId);
        recomputed++;
      }
      logInfo('store_aggregates_recomputed', {
        fn: 'recomputeStoreAggregates',
        recomputed,
        scannedReviews: recentReviewsSnap.size,
      });
    } catch (err) {
      logWarn('store_aggregates_recompute_failed', { fn: 'recomputeStoreAggregates', err });
    }
  },
);

async function recomputeOne(storeId: string): Promise<void> {
  const storeRef = db().collection('stores').doc(storeId);
  const [reviewsSnap, storeSnap] = await Promise.all([
    db()
      .collection('reviews')
      .where('storeId', '==', storeId)
      .where('flagged', '==', false)
      .get(),
    storeRef.get(),
  ]);

  let count = 0;
  let sum = 0;
  const histogram: Record<string, number> = { '1': 0, '2': 0, '3': 0, '4': 0, '5': 0 };
  for (const d of reviewsSnap.docs) {
    const r = d.data() as { rating?: number; deletedAt?: unknown };
    if (r.deletedAt) continue;
    const rating = r.rating ?? 0;
    if (rating < 1 || rating > 5) continue;
    count++;
    sum += rating;
    histogram[String(rating)] = (histogram[String(rating)] ?? 0) + 1;
  }
  const avg = count > 0 ? sum / count : 0;

  // ADR-302 v1.2 — pinTier도 같이 derive (matchaScore 갱신 직후).
  const store = storeSnap.data() as
    | { verified?: boolean; pinTier?: string }
    | undefined;
  const newPinTier = derivePinTier(avg, store?.verified ?? false);

  const patch: Record<string, unknown> = {
    reviewCount: count,
    ratingAvg: avg,
    ratingHistogram: histogram,
    matchaScore: avg, // SCH-5 (가중평균 도입)는 Phase 3.
    updatedAt: FieldValue.serverTimestamp(),
  };
  if (store?.pinTier !== newPinTier) {
    patch.pinTier = newPinTier;
  }
  await storeRef.update(patch);
}
