import { FieldValue } from 'firebase-admin/firestore';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';

import { db } from '../utils/admin.js';
import { logInfo, logWarn } from '../utils/logger.js';
import { BACKGROUND_DEFAULTS } from '../utils/region.js';

/**
 * `users/{uid}/fcmTokens/{tokenId}` create/update 시 부모 user doc의
 * `notification.lastTokenAt`을 max로 갱신. server-data ADR-302 v1.3.
 *
 * delete 케이스는 무시 (lastTokenAt은 monotonic — 토큰이 사라져도 과거 시점 기록 유지).
 */
export const onWriteFcmToken = onDocumentWritten(
  {
    ...BACKGROUND_DEFAULTS,
    document: 'users/{uid}/fcmTokens/{tokenId}',
  },
  async (event) => {
    const after = event.data?.after?.data();
    if (!after) return; // delete 케이스 — no-op
    const uid = event.params.uid;
    try {
      await db()
        .collection('users')
        .doc(uid)
        .update({
          'notification.lastTokenAt': after.updatedAt ?? FieldValue.serverTimestamp(),
        });
      logInfo('fcm_token_written', {
        fn: 'onWriteFcmToken',
        uid,
        tokenId: event.params.tokenId,
      });
    } catch (err) {
      logWarn('fcm_token_lastSeen_update_failed', {
        fn: 'onWriteFcmToken',
        uid,
        tokenId: event.params.tokenId,
        err,
      });
    }
  },
);
