import { onSchedule } from 'firebase-functions/v2/scheduler';

import { auth, db } from '../utils/admin.js';
import { logInfo, logWarn } from '../utils/logger.js';
import { DEFAULT_REGION } from '../utils/region.js';

/**
 * 30일 soft-delete → hard-delete (schema §1.1 deletedAt + cost-projection §4.2 GDPR).
 *
 * 매일 KST 02:00 실행.
 *
 * 흐름:
 *   1) `users` where deletedAt < (now - 30d) limit 100 조회.
 *   2) 각 사용자에 대해:
 *      - reviews uid==X soft-delete (deletedAt set) — 본체 삭제 시 매장 평점 drift 발생.
 *      - collections/{uid}/items 삭제 (서브 컬렉션 일괄).
 *      - wishlists/{uid}/items 삭제.
 *      - friendships/{uid}/edges 삭제 (양방향 정합).
 *      - feed_events where actorUid==X 삭제.
 *      - users/{uid} 삭제.
 *      - Firebase Auth 사용자 삭제(`auth().deleteUser(uid)`).
 *
 * 정책:
 *   - 한 번 실행에 최대 100명 처리 (안정성 우선).
 *   - 실패 시 다음 실행에서 재시도 (deletedAt 그대로 → 다시 후보).
 */
export const purgeDeletedUsers = onSchedule(
  {
    schedule: 'every day 02:00',
    timeZone: 'Asia/Seoul',
    region: DEFAULT_REGION,
    timeoutSeconds: 540,
    memory: '512MiB',
  },
  async () => {
    const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    try {
      const usersSnap = await db()
        .collection('users')
        .where('deletedAt', '<', cutoff)
        .limit(100)
        .get();

      let purged = 0;
      for (const doc of usersSnap.docs) {
        const uid = doc.id;
        try {
          await purgeOne(uid);
          purged++;
        } catch (err) {
          logWarn('user_purge_failed', { fn: 'purgeDeletedUsers', uid, err });
        }
      }
      logInfo('users_purged', { fn: 'purgeDeletedUsers', purged, candidates: usersSnap.size });
    } catch (err) {
      logWarn('users_purge_iteration_failed', { fn: 'purgeDeletedUsers', err });
    }
  },
);

async function purgeOne(uid: string): Promise<void> {
  // 사용자 서브컬렉션 일괄 삭제 (recursive delete는 admin SDK firestore.recursiveDelete).
  const firestore = db();
  await firestore.recursiveDelete(firestore.collection('collections').doc(uid));
  await firestore.recursiveDelete(firestore.collection('wishlists').doc(uid));
  await firestore.recursiveDelete(firestore.collection('friendships').doc(uid));

  // feed_events
  const feedSnap = await firestore
    .collection('feed_events')
    .where('actorUid', '==', uid)
    .limit(500)
    .get();
  if (!feedSnap.empty) {
    const batch = firestore.batch();
    for (const d of feedSnap.docs) batch.delete(d.ref);
    await batch.commit();
  }

  // reviews soft-delete (보존 — 매장 평점 보존 목적). hard-delete는 GDPR 요청 수신 시.
  const reviewsSnap = await firestore.collection('reviews').where('uid', '==', uid).get();
  if (!reviewsSnap.empty) {
    const batch = firestore.batch();
    for (const d of reviewsSnap.docs) {
      batch.update(d.ref, {
        deletedAt: new Date(),
        'author.displayName': '[deleted]',
        'author.photoURL': null,
      });
    }
    await batch.commit();
  }

  // users doc + Auth 본체 삭제.
  await firestore.collection('users').doc(uid).delete();
  try {
    await auth().deleteUser(uid);
  } catch (err) {
    // 이미 삭제되었거나 미존재: 무시.
    void err;
  }
}
