import { onSchedule } from 'firebase-functions/v2/scheduler';

import { db } from '../utils/admin.js';
import { logInfo, logWarn } from '../utils/logger.js';
import { DEFAULT_REGION } from '../utils/region.js';

/**
 * `users/{uid}/fcmTokens/{tokenId}` 60일 retention — server-data ADR-302 v1.3.
 *
 * 매일 KST 04:30 실행. `lastSeenAt < now-60d` 일괄 삭제 (collection_group 쿼리).
 *
 * 인덱스: `fcmTokens` (collection_group) `lastSeenAt` ASC — schema §1A 정합.
 */
export const cleanupStaleFcmTokens = onSchedule(
  {
    schedule: '30 4 * * *',
    timeZone: 'Asia/Seoul',
    region: DEFAULT_REGION,
    timeoutSeconds: 540,
    memory: '512MiB',
  },
  async () => {
    const cutoff = new Date(Date.now() - 60 * 24 * 60 * 60 * 1000);
    let deleted = 0;
    let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;

    try {
      for (let iter = 0; iter < 100; iter++) {
        let q = db()
          .collectionGroup('fcmTokens')
          .where('lastSeenAt', '<', cutoff)
          .orderBy('lastSeenAt')
          .limit(400);
        if (last) q = q.startAfter(last);
        const snap = await q.get();
        if (snap.empty) break;
        const batch = db().batch();
        for (const d of snap.docs) batch.delete(d.ref);
        await batch.commit();
        deleted += snap.size;
        last = snap.docs[snap.docs.length - 1];
        if (snap.size < 400) break;
      }
      logInfo('fcm_tokens_cleanup_done', { fn: 'cleanupStaleFcmTokens', deleted });
    } catch (err) {
      logWarn('fcm_tokens_cleanup_failed', { fn: 'cleanupStaleFcmTokens', deleted, err });
    }
  },
);
