import { onSchedule } from 'firebase-functions/v2/scheduler';

import { db } from '../utils/admin.js';
import { logInfo, logWarn } from '../utils/logger.js';
import { DEFAULT_REGION } from '../utils/region.js';

/**
 * `feed_events` 90일 retention (schema §7.5 + SCH-3).
 *
 * 매일 KST 03:00 실행. 90일 지난 feed_events doc 삭제 (배치 500개씩, 한 번 실행에 최대 25,000건).
 *
 * 비용 영향:
 *   - cost-projection.md §3 시나리오 B 기준 일 ~10K feed_events 생성 → 90일 후 삭제 동률.
 *   - delete write 1건당 $0.000002 → 일 0.02 USD 수준.
 *
 * 도감/리뷰 본체는 영구 보관 (피드는 derived).
 */
export const cleanupFeedEvents = onSchedule(
  {
    schedule: 'every day 03:00',
    timeZone: 'Asia/Seoul',
    region: DEFAULT_REGION,
    timeoutSeconds: 540,
    memory: '512MiB',
  },
  async () => {
    const cutoff = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
    let deleted = 0;
    try {
      for (let iter = 0; iter < 50; iter++) {
        const snap = await db()
          .collection('feed_events')
          .where('createdAt', '<', cutoff)
          .limit(500)
          .get();
        if (snap.empty) break;
        const batch = db().batch();
        for (const d of snap.docs) batch.delete(d.ref);
        await batch.commit();
        deleted += snap.size;
        if (snap.size < 500) break;
      }
      logInfo('feed_events_cleanup_done', { fn: 'cleanupFeedEvents', deleted });
    } catch (err) {
      logWarn('feed_events_cleanup_failed', { fn: 'cleanupFeedEvents', deleted, err });
    }
  },
);
