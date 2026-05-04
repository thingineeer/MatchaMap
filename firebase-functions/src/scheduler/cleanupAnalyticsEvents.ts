import { onSchedule } from 'firebase-functions/v2/scheduler';

import { db } from '../utils/admin.js';
import { logInfo, logWarn } from '../utils/logger.js';
import { DEFAULT_REGION } from '../utils/region.js';

/**
 * `analytics/events` 30일 retention (schema §9 — GA4 export가 SSOT, 본 컬렉션은 보조).
 *
 * 매일 KST 04:00 실행.
 */
export const cleanupAnalyticsEvents = onSchedule(
  {
    schedule: 'every day 04:00',
    timeZone: 'Asia/Seoul',
    region: DEFAULT_REGION,
    timeoutSeconds: 540,
    memory: '512MiB',
  },
  async () => {
    const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    let deleted = 0;
    try {
      for (let iter = 0; iter < 50; iter++) {
        const snap = await db()
          .collection('analytics')
          .doc('events')
          .collection('items')
          .where('serverTs', '<', cutoff)
          .limit(500)
          .get();
        if (snap.empty) break;
        const batch = db().batch();
        for (const d of snap.docs) batch.delete(d.ref);
        await batch.commit();
        deleted += snap.size;
        if (snap.size < 500) break;
      }
      logInfo('analytics_events_cleanup_done', { fn: 'cleanupAnalyticsEvents', deleted });
    } catch (err) {
      logWarn('analytics_events_cleanup_failed', { fn: 'cleanupAnalyticsEvents', deleted, err });
    }
  },
);
