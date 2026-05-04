import { onDocumentUpdated } from 'firebase-functions/v2/firestore';

import { db } from '../utils/admin.js';
import { logInfo, logWarn } from '../utils/logger.js';
import { BACKGROUND_DEFAULTS } from '../utils/region.js';

/**
 * 디노멀 fanout — `users/{uid}.{displayName, photoURL}` 변경 시 모든 디노멀 복제 갱신.
 *
 * 갱신 대상 (schema.md §0.3):
 *   - reviews where uid == X → author.{displayName, photoURL}
 *   - feed_events where actorUid == X → actor.{displayName, photoURL}
 *   - friendships/{*}/edges/{X} → friend.{displayName, photoURL}
 *
 * 정책:
 *   - 사용자가 displayName 변경하는 빈도는 ≤ 1회/월/사용자 가정 (ADR-302 D2 근거).
 *   - 갱신 doc 수가 많을 수 있음. paginate + batch (500/iter) 처리.
 *   - 콜드 스타트 보호용으로 백그라운드 timeout 540s. 한도 초과 시 다음 트리거 사이클로 이연.
 *
 * 비용 영향:
 *   - 사용자 평균 reviews 50개 + feed_events 100개 + friends 10개 = 160 writes/변경.
 *   - 월 1회 변경 가정 시 사용자당 월 160 writes 추가. 무시 가능.
 */
export const onUpdateUser = onDocumentUpdated(
  {
    ...BACKGROUND_DEFAULTS,
    document: 'users/{uid}',
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const nameChanged = before.displayName !== after.displayName;
    const photoChanged = (before.photoURL ?? null) !== (after.photoURL ?? null);
    if (!nameChanged && !photoChanged) return;

    const uid = event.params.uid;
    const patch = {
      'author.displayName': after.displayName,
      'author.photoURL': after.photoURL ?? null,
    };
    const actorPatch = {
      'actor.displayName': after.displayName,
      'actor.photoURL': after.photoURL ?? null,
    };
    const friendPatch = {
      'friend.displayName': after.displayName,
      'friend.photoURL': after.photoURL ?? null,
    };

    let updated = 0;
    try {
      updated += await fanoutUpdate('reviews', 'uid', uid, patch);
      updated += await fanoutUpdate('feed_events', 'actorUid', uid, actorPatch);
      updated += await fanoutFriendsEdges(uid, friendPatch);

      logInfo('user_denorm_fanout', {
        fn: 'onUpdateUser',
        uid,
        nameChanged,
        photoChanged,
        docsUpdated: updated,
      });
    } catch (err) {
      logWarn('user_denorm_fanout_failed', { fn: 'onUpdateUser', uid, err });
    }
  },
);

async function fanoutUpdate(
  collection: string,
  whereField: string,
  value: string,
  patch: Record<string, unknown>,
): Promise<number> {
  let total = 0;
  let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  // paginate 500/iter
  for (let i = 0; i < 50; i++) {
    let q = db().collection(collection).where(whereField, '==', value).limit(500);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    if (snap.empty) break;
    const batch = db().batch();
    for (const d of snap.docs) batch.update(d.ref, patch);
    await batch.commit();
    total += snap.size;
    last = snap.docs[snap.docs.length - 1];
    if (snap.size < 500) break;
  }
  return total;
}

async function fanoutFriendsEdges(
  uid: string,
  patch: Record<string, unknown>,
): Promise<number> {
  // 사용자 X의 친구 N명 각각의 `friendships/{N}/edges/{X}` doc 갱신.
  // schema §6: 양방향 doc 저장. uid 본인의 edges에서 친구 목록 조회 후, 각 친구 doc의
  // `edges/{uid}` 갱신.
  const myEdgesSnap = await db()
    .collection('friendships')
    .doc(uid)
    .collection('edges')
    .limit(500)
    .get();
  if (myEdgesSnap.empty) return 0;

  const batch = db().batch();
  for (const edge of myEdgesSnap.docs) {
    const friendUid = edge.id;
    const ref = db()
      .collection('friendships')
      .doc(friendUid)
      .collection('edges')
      .doc(uid);
    batch.update(ref, patch);
  }
  await batch.commit();
  return myEdgesSnap.size;
}
