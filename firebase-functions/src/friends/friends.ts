import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { db } from '../utils/admin.js';
import { assertAppCheck } from '../utils/appCheck.js';
import { assertAuthenticated } from '../utils/auth.js';
import { ErrorCodes } from '../utils/errors.js';
import { logInfo, logWarn } from '../utils/logger.js';
import { CALLABLE_DEFAULTS } from '../utils/region.js';
import { ulid } from '../utils/ulid.js';

/**
 * 친구 그래프 콜러블 — schema.md §6 정합.
 *
 * 양방향 doc 정합 (Functions가 SSOT):
 *   - requestFriend(targetUid):
 *       friendships/{me}/edges/{target}   = pending_outgoing
 *       friendships/{target}/edges/{me}   = pending_incoming
 *   - acceptFriend(requesterUid):
 *       두 doc → status=accepted, acceptedAt=now
 *       users/{me}.stats.friendCount += 1, users/{requester}.stats.friendCount += 1
 *       feed_events 'friend_added' fanout (양쪽 모두)
 *   - removeFriend(otherUid):
 *       두 doc 삭제 + friendCount -= 1 (양쪽)
 *
 * v1.0.0 add method = `qr`만 (schema §6.1). username/share_link/address_book은 v1.1.0.
 */

interface RequestFriendRequest {
  targetUid: string;
  addMethod: 'qr';
}
interface AcceptFriendRequest {
  requesterUid: string;
}
interface RemoveFriendRequest {
  otherUid: string;
}
interface OkResponse {
  ok: true;
}

const MAX_AUDIENCE = 500;

export const requestFriend = onCall<RequestFriendRequest, Promise<OkResponse>>(
  CALLABLE_DEFAULTS,
  async (req) => {
    assertAppCheck(req);
    const { uid } = assertAuthenticated(req);
    const data = req.data;
    if (!data || typeof data.targetUid !== 'string' || data.targetUid === uid) {
      throw new HttpsError('invalid-argument', 'Invalid target uid.', {
        code: ErrorCodes.INVALID_ARGUMENT,
      });
    }
    if (data.addMethod !== 'qr') {
      throw new HttpsError('invalid-argument', 'Only qr add method is supported in v1.0.0.', {
        code: ErrorCodes.INVALID_ARGUMENT,
      });
    }

    const meRef = db().collection('friendships').doc(uid).collection('edges').doc(data.targetUid);
    const targetRef = db()
      .collection('friendships')
      .doc(data.targetUid)
      .collection('edges')
      .doc(uid);

    await db().runTransaction(async (tx) => {
      const [meSnap, targetSnap, meUserSnap, targetUserSnap] = await Promise.all([
        tx.get(meRef),
        tx.get(targetRef),
        tx.get(db().collection('users').doc(uid)),
        tx.get(db().collection('users').doc(data.targetUid)),
      ]);
      if (!targetUserSnap.exists) {
        throw new HttpsError('not-found', 'Target user not found.', {
          code: ErrorCodes.RESOURCE_NOT_FOUND,
        });
      }
      if (meSnap.exists) {
        // 이미 요청 보냈거나 친구. idempotent.
        return;
      }
      void targetSnap;

      const me = meUserSnap.data() as { displayName?: string; photoURL?: string; country?: string };
      const target = targetUserSnap.data() as {
        displayName?: string;
        photoURL?: string;
        country?: string;
      };

      tx.set(meRef, {
        friendUid: data.targetUid,
        uid,
        status: 'pending_outgoing',
        friend: {
          uid: data.targetUid,
          displayName: target.displayName ?? 'matcha_lover',
          photoURL: target.photoURL ?? null,
          country: target.country ?? null,
        },
        requestedAt: FieldValue.serverTimestamp(),
        addMethod: 'qr',
      });
      tx.set(targetRef, {
        friendUid: uid,
        uid: data.targetUid,
        status: 'pending_incoming',
        friend: {
          uid,
          displayName: me.displayName ?? 'matcha_lover',
          photoURL: me.photoURL ?? null,
          country: me.country ?? null,
        },
        requestedAt: FieldValue.serverTimestamp(),
        addMethod: 'qr',
      });
    });

    logInfo('friend_requested', { fn: 'requestFriend', uid, targetUid: data.targetUid });
    return { ok: true };
  },
);

export const acceptFriend = onCall<AcceptFriendRequest, Promise<OkResponse>>(
  CALLABLE_DEFAULTS,
  async (req) => {
    assertAppCheck(req);
    const { uid } = assertAuthenticated(req);
    const data = req.data;
    if (!data || typeof data.requesterUid !== 'string' || data.requesterUid === uid) {
      throw new HttpsError('invalid-argument', 'Invalid requester uid.', {
        code: ErrorCodes.INVALID_ARGUMENT,
      });
    }

    const meRef = db()
      .collection('friendships')
      .doc(uid)
      .collection('edges')
      .doc(data.requesterUid);
    const requesterRef = db()
      .collection('friendships')
      .doc(data.requesterUid)
      .collection('edges')
      .doc(uid);
    const meUserRef = db().collection('users').doc(uid);
    const requesterUserRef = db().collection('users').doc(data.requesterUid);

    // friend audience 사전 조회 (트랜잭션 외부) — feed_events 작성용.
    const [myFriendsSnap, requesterFriendsSnap] = await Promise.all([
      db()
        .collection('friendships')
        .doc(uid)
        .collection('edges')
        .where('status', '==', 'accepted')
        .limit(MAX_AUDIENCE)
        .get(),
      db()
        .collection('friendships')
        .doc(data.requesterUid)
        .collection('edges')
        .where('status', '==', 'accepted')
        .limit(MAX_AUDIENCE)
        .get(),
    ]);
    const myAudience = [uid, ...myFriendsSnap.docs.map((d) => d.id)].slice(0, MAX_AUDIENCE);
    const requesterAudience = [
      data.requesterUid,
      ...requesterFriendsSnap.docs.map((d) => d.id),
    ].slice(0, MAX_AUDIENCE);

    try {
      await db().runTransaction(async (tx) => {
        const [meSnap, requesterSnap, meUserSnap, requesterUserSnap] = await Promise.all([
          tx.get(meRef),
          tx.get(requesterRef),
          tx.get(meUserRef),
          tx.get(requesterUserRef),
        ]);
        if (!meSnap.exists || !requesterSnap.exists) {
          throw new HttpsError('not-found', 'Friend request not found.', {
            code: ErrorCodes.RESOURCE_NOT_FOUND,
          });
        }
        if (
          (meSnap.data() as { status?: string }).status !== 'pending_incoming' ||
          (requesterSnap.data() as { status?: string }).status !== 'pending_outgoing'
        ) {
          throw new HttpsError('failed-precondition', 'Request not in pending state.', {
            code: ErrorCodes.PERMISSION_DENIED,
          });
        }

        tx.update(meRef, {
          status: 'accepted',
          acceptedAt: FieldValue.serverTimestamp(),
        });
        tx.update(requesterRef, {
          status: 'accepted',
          acceptedAt: FieldValue.serverTimestamp(),
        });
        tx.update(meUserRef, {
          'stats.friendCount': FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        });
        tx.update(requesterUserRef, {
          'stats.friendCount': FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        });

        const me = meUserSnap.data() as { displayName?: string; photoURL?: string };
        const requester = requesterUserSnap.data() as { displayName?: string; photoURL?: string };

        const eventForMe = ulid();
        const eventForRequester = ulid();

        tx.set(db().collection('feed_events').doc(eventForMe), {
          eventId: eventForMe,
          actorUid: uid,
          audienceUids: myAudience,
          type: 'friend_added',
          targetType: 'user',
          targetId: data.requesterUid,
          actor: {
            uid,
            displayName: me.displayName ?? 'matcha_lover',
            photoURL: me.photoURL ?? null,
          },
          target: {
            uid: data.requesterUid,
            displayName: requester.displayName ?? 'matcha_lover',
            photoURL: requester.photoURL ?? null,
          },
          visibility: 'friends',
          createdAt: FieldValue.serverTimestamp(),
        });
        tx.set(db().collection('feed_events').doc(eventForRequester), {
          eventId: eventForRequester,
          actorUid: data.requesterUid,
          audienceUids: requesterAudience,
          type: 'friend_added',
          targetType: 'user',
          targetId: uid,
          actor: {
            uid: data.requesterUid,
            displayName: requester.displayName ?? 'matcha_lover',
            photoURL: requester.photoURL ?? null,
          },
          target: {
            uid,
            displayName: me.displayName ?? 'matcha_lover',
            photoURL: me.photoURL ?? null,
          },
          visibility: 'friends',
          createdAt: FieldValue.serverTimestamp(),
        });
      });
    } catch (err) {
      if (err instanceof HttpsError) {
        logWarn('friend_accept_rejected', {
          fn: 'acceptFriend',
          uid,
          requesterUid: data.requesterUid,
          err,
        });
        throw err;
      }
      logWarn('friend_accept_failed', {
        fn: 'acceptFriend',
        uid,
        requesterUid: data.requesterUid,
        err,
      });
      throw new HttpsError('internal', 'Failed to accept friend.', { code: ErrorCodes.INTERNAL });
    }

    logInfo('friend_accepted', { fn: 'acceptFriend', uid, requesterUid: data.requesterUid });
    return { ok: true };
  },
);

export const removeFriend = onCall<RemoveFriendRequest, Promise<OkResponse>>(
  CALLABLE_DEFAULTS,
  async (req) => {
    assertAppCheck(req);
    const { uid } = assertAuthenticated(req);
    const data = req.data;
    if (!data || typeof data.otherUid !== 'string' || data.otherUid === uid) {
      throw new HttpsError('invalid-argument', 'Invalid other uid.', {
        code: ErrorCodes.INVALID_ARGUMENT,
      });
    }

    const meRef = db().collection('friendships').doc(uid).collection('edges').doc(data.otherUid);
    const otherRef = db()
      .collection('friendships')
      .doc(data.otherUid)
      .collection('edges')
      .doc(uid);

    await db().runTransaction(async (tx) => {
      const [meSnap, otherSnap] = await Promise.all([tx.get(meRef), tx.get(otherRef)]);
      if (!meSnap.exists) return; // idempotent

      const wasAccepted = (meSnap.data() as { status?: string }).status === 'accepted';

      tx.delete(meRef);
      if (otherSnap.exists) tx.delete(otherRef);

      if (wasAccepted) {
        tx.update(db().collection('users').doc(uid), {
          'stats.friendCount': FieldValue.increment(-1),
          updatedAt: FieldValue.serverTimestamp(),
        });
        tx.update(db().collection('users').doc(data.otherUid), {
          'stats.friendCount': FieldValue.increment(-1),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    });

    logInfo('friend_removed', { fn: 'removeFriend', uid, otherUid: data.otherUid });
    return { ok: true };
  },
);
