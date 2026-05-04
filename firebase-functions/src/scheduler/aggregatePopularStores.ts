import { FieldValue } from 'firebase-admin/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { db } from '../utils/admin.js';
import { logError, logInfo } from '../utils/logger.js';
import { DEFAULT_REGION } from '../utils/region.js';

/**
 * 인기 매장 집계 스케줄러. 매시 정각 실행.
 *
 * 집계 윈도우: 직전 24시간 기준 (review_submitted + collection_added 합산 가중치).
 *   score = (collection_added × 2) + (review_submitted × 3) + (rating_avg × 1.5)
 *
 * 결과: `aggregations/popularStores/byCountry/{country}` 도큐먼트에 top 50 매장 ID 배열 + 점수.
 *
 * 사용:
 *   - iOS Map 화면 "지금 핫한 말차" 카루셀.
 *   - 검색 결과의 default sort.
 *
 * 비용:
 *   - 매시 1회 × 매장 수 (~수천) read = MVP 규모 무시 가능.
 *   - 집계 결과 write = 6개 국가 × 50 = 300 docs/h.
 *
 * 주의:
 *   - 24h 윈도우는 KST 기준 timestamp 비교. 클라가 보내는 `country`는 매장 doc에서 복제된 값.
 *   - 신규 매장 콜드 스타트 보호: 매장 생성 후 48h 동안은 score에 +5 보정 (TODO Phase 3).
 */
export const aggregatePopularStores = onSchedule(
  {
    schedule: 'every 1 hours',
    timeZone: 'Asia/Seoul',
    region: DEFAULT_REGION,
    timeoutSeconds: 540,
    memory: '512MiB',
  },
  async () => {
    const since = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const countries = ['KR', 'JP', 'US', 'GB', 'DE', 'FR'] as const;

    try {
      for (const country of countries) {
        const scores = await scoreStoresFor(country, since);
        const top = Array.from(scores.entries())
          .sort((a, b) => b[1] - a[1])
          .slice(0, 50)
          .map(([storeId, score]) => ({ storeId, score }));

        await db()
          .collection('aggregations')
          .doc('popularStores')
          .collection('byCountry')
          .doc(country)
          .set(
            {
              country,
              top,
              computedAt: FieldValue.serverTimestamp(),
              windowHours: 24,
            },
            { merge: false },
          );
      }
      logInfo('popular_stores_aggregated', {
        fn: 'aggregatePopularStores',
        countries: countries.join(','),
      });
    } catch (err) {
      logError('popular_stores_aggregation_failed', { fn: 'aggregatePopularStores', err });
    }
  },
);

async function scoreStoresFor(country: string, since: Date): Promise<Map<string, number>> {
  const scores = new Map<string, number>();

  const reviewsSnap = await db()
    .collection('reviews')
    .where('country', '==', country)
    .where('createdAt', '>=', since)
    .get();
  for (const doc of reviewsSnap.docs) {
    const r = doc.data() as { storeId: string; rating?: number };
    const cur = scores.get(r.storeId) ?? 0;
    scores.set(r.storeId, cur + 3 + (r.rating ?? 0) * 1.5);
  }

  const collectionsSnap = await db()
    .collectionGroup('collection')
    .where('country', '==', country)
    .where('addedAt', '>=', since)
    .get();
  for (const doc of collectionsSnap.docs) {
    const c = doc.data() as { storeId: string };
    const cur = scores.get(c.storeId) ?? 0;
    scores.set(c.storeId, cur + 2);
  }

  return scores;
}
