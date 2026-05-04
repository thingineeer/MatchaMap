import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { db } from '../utils/admin.js';
import { assertAppCheck } from '../utils/appCheck.js';
import { assertAuthenticated } from '../utils/auth.js';
import { ErrorCodes } from '../utils/errors.js';
import { logInfo, logWarn } from '../utils/logger.js';
import { CALLABLE_DEFAULTS } from '../utils/region.js';
import { ulid } from '../utils/ulid.js';

/**
 * 도감 항목 추가 (트랜잭션 fanout 책임자).
 *
 * schema.md §5.5 fanout 흐름:
 *   1) `collections/{uid}/items/{itemId}` create
 *   2) `users/{uid}.stats.collectionCount` += 1
 *   3) `feed_events/{eventId}` create with audienceUids = [uid, ...accepted friends]
 *   4) (선택) analytics_events audit
 *
 * 클라는 본 콜러블만 호출. 보안 규칙은 collections write를 Functions only로 차단.
 *
 * 도감 등록률 SSOT (observability §3.4 ↔ schema §5.4):
 *   - via_review = 본 콜러블 입력 `viaReview`
 *   - country = stores doc에서 서버가 복제 (클라 입력 신뢰 X)
 *   - createdAt = serverTimestamp (D4)
 *   - time_since_view_min은 클라 측 analytics 발화 시 계산 (Functions는 doc만)
 */

interface AddCollectionItemRequest {
  storeId: string;
  drink: 'usucha' | 'koicha' | 'matcha_latte' | 'iced_matcha' | 'matcha_dessert' | 'other';
  grade?: 'ceremonial' | 'premium' | 'cooking' | 'unknown';
  originRegion?: string;
  colorHex?: string;
  note?: string;
  photos?: string[];
  visitedAt?: number; // epoch ms, optional (클라 입력 허용 — schema §5.1)
  viaReview?: boolean;
  linkedReviewId?: string;
}

interface AddCollectionItemResponse {
  itemId: string;
  collectionCount: number;
}

const MAX_AUDIENCE = 500;

export const addCollectionItem = onCall<
  AddCollectionItemRequest,
  Promise<AddCollectionItemResponse>
>(CALLABLE_DEFAULTS, async (req) => {
  assertAppCheck(req);
  const { uid } = assertAuthenticated(req);
  const data = req.data;

  if (!data || typeof data.storeId !== 'string' || typeof data.drink !== 'string') {
    throw new HttpsError('invalid-argument', 'Missing storeId or drink.', {
      code: ErrorCodes.INVALID_ARGUMENT,
    });
  }

  const storeRef = db().collection('stores').doc(data.storeId);
  const storeSnap = await storeRef.get();
  if (!storeSnap.exists) {
    throw new HttpsError('not-found', 'Store not found.', {
      code: ErrorCodes.RESOURCE_NOT_FOUND,
    });
  }
  const store = storeSnap.data() as StoreDoc;

  // 친구 audience 조회 — accepted only, ≤ 500.
  const friendsSnap = await db()
    .collection('friendships')
    .doc(uid)
    .collection('edges')
    .where('status', '==', 'accepted')
    .limit(MAX_AUDIENCE + 1)
    .get();
  const friendUids = friendsSnap.docs.map((d) => d.id);
  const audienceUids =
    friendUids.length >= MAX_AUDIENCE ? [] : [uid, ...friendUids.slice(0, MAX_AUDIENCE - 1)];

  const itemId = ulid();
  const eventId = ulid();
  const itemRef = db().collection('collections').doc(uid).collection('items').doc(itemId);
  const userRef = db().collection('users').doc(uid);
  const feedRef = db().collection('feed_events').doc(eventId);

  try {
    await db().runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      const author = userSnap.data() as UserDoc | undefined;

      const visitedAt = data.visitedAt
        ? Timestamp.fromMillis(data.visitedAt)
        : FieldValue.serverTimestamp();

      tx.set(itemRef, {
        itemId,
        uid,
        storeId: data.storeId,
        drink: data.drink,
        grade: data.grade ?? null,
        originRegion: data.originRegion ?? null,
        colorHex: data.colorHex ?? null,
        note: data.note ?? null,
        photos: data.photos ?? [],
        country: store.country,
        store: {
          placeId: store.placeId,
          name: store.name,
          city: store.city,
          country: store.country,
          primaryPhoto: store.primaryPhoto ?? null,
        },
        viaReview: data.viaReview ?? false,
        linkedReviewId: data.linkedReviewId ?? null,
        visitedAt,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      tx.update(userRef, {
        'stats.collectionCount': FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      });

      tx.set(feedRef, {
        eventId,
        actorUid: uid,
        audienceUids,
        type: 'collection',
        targetType: 'collection_item',
        targetId: itemId,
        actor: {
          uid,
          displayName: author?.displayName ?? 'matcha_lover',
          photoURL: author?.photoURL ?? null,
        },
        target: {
          placeId: store.placeId,
          name: store.name,
          city: store.city,
          country: store.country,
          primaryPhoto: store.primaryPhoto ?? null,
        },
        payload: {
          drink: data.drink,
          grade: data.grade ?? null,
          colorHex: data.colorHex ?? null,
        },
        country: store.country,
        visibility: 'friends',
        createdAt: FieldValue.serverTimestamp(),
      });
    });

    const userSnapAfter = await userRef.get();
    const collectionCount =
      ((userSnapAfter.data()?.stats as { collectionCount?: number } | undefined)
        ?.collectionCount as number | undefined) ?? 0;

    logInfo('collection_item_added', {
      fn: 'addCollectionItem',
      uid,
      itemId,
      storeId: data.storeId,
      audienceSize: audienceUids.length,
      viaReview: data.viaReview ?? false,
    });

    return { itemId, collectionCount };
  } catch (err) {
    if (err instanceof HttpsError) {
      logWarn('collection_item_rejected', { fn: 'addCollectionItem', uid, err });
      throw err;
    }
    logWarn('collection_item_failed', { fn: 'addCollectionItem', uid, err });
    throw new HttpsError('internal', 'Failed to add collection item.', {
      code: ErrorCodes.INTERNAL,
    });
  }
});

interface StoreDoc {
  placeId: string;
  name: string;
  city: string;
  country: string;
  primaryPhoto?: string;
}

interface UserDoc {
  uid: string;
  displayName: string;
  photoURL?: string;
}
