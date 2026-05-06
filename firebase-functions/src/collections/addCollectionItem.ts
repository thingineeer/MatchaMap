import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { db } from '../utils/admin.js';
import { assertAppCheck } from '../utils/appCheck.js';
import { assertAuthenticated, assertNotAnonymous } from '../utils/auth.js';
import { colorHexForTier, ColorTier, isColorTier } from '../utils/colorTier.js';
import {
  COLLECTION_DRINKS,
  COLLECTION_GRADES,
  CollectionDrink,
  CollectionGrade,
  isOneOf,
  ORIGIN_REGIONS,
  OriginRegion,
} from '../utils/enums.js';
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
 *
 * 클라는 본 콜러블만 호출. 보안 규칙은 collections write를 Functions only로 차단.
 *
 * v1.1 enum 정합 (server-data):
 *   - drink: matcha_dessert (collections는 'matcha_dessert', reviews는 'dessert' — 의도된 차이)
 *   - grade: ceremonial / premium / standard / culinary / unknown ('cooking' 거부)
 *   - originRegion: uji / nishio / kagoshima / shizuoka / boseong / hadong / jeju / other / unknown
 *   - colorTier: matchaSoft / matchaPale / matcha / deepMatcha / deep — 입력은 enum만 받고
 *     `colorHex`는 서버가 design-system.md § 1.5.1 매핑으로 자동 채움.
 *
 * 도감 등록률 SSOT (observability §3.4 ↔ schema §5.4):
 *   - via_review = 본 콜러블 입력 `viaReview`
 *   - country = stores doc에서 서버가 복제 (클라 입력 신뢰 X)
 *   - createdAt = serverTimestamp (D4)
 *   - time_since_view_min은 클라 측 analytics 발화 시 계산
 */

interface AddCollectionItemRequest {
  storeId: string;
  drink: CollectionDrink;
  grade?: CollectionGrade;
  originRegion?: OriginRegion;
  colorTier?: ColorTier;            // v1.1: 입력은 enum만. colorHex 직접 입력 금지.
  note?: string;
  photos?: string[];
  visitedAt?: number;               // epoch ms (과거 시음 입력 허용 — schema §5.1)
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
  assertNotAnonymous(req);
  const data = req.data;

  if (
    !data ||
    typeof data.storeId !== 'string' ||
    !isOneOf(COLLECTION_DRINKS, data.drink)
  ) {
    throw new HttpsError('invalid-argument', 'Missing or invalid storeId/drink.', {
      code: ErrorCodes.INVALID_ARGUMENT,
    });
  }
  if (data.grade !== undefined && !isOneOf(COLLECTION_GRADES, data.grade)) {
    throw new HttpsError('invalid-argument', 'Invalid grade enum.', {
      code: ErrorCodes.INVALID_ARGUMENT,
    });
  }
  if (data.originRegion !== undefined && !isOneOf(ORIGIN_REGIONS, data.originRegion)) {
    throw new HttpsError('invalid-argument', 'Invalid originRegion enum.', {
      code: ErrorCodes.INVALID_ARGUMENT,
    });
  }
  if (data.colorTier !== undefined && !isColorTier(data.colorTier)) {
    throw new HttpsError('invalid-argument', 'Invalid colorTier enum.', {
      code: ErrorCodes.INVALID_ARGUMENT,
    });
  }
  if (data.viaReview === true && typeof data.linkedReviewId !== 'string') {
    throw new HttpsError('invalid-argument', 'viaReview=true requires linkedReviewId.', {
      code: ErrorCodes.INVALID_ARGUMENT,
    });
  }

  const colorTier = data.colorTier ?? null;
  const colorHex = colorTier ? colorHexForTier(colorTier) : null;

  const storeRef = db().collection('stores').doc(data.storeId);
  const storeSnap = await storeRef.get();
  if (!storeSnap.exists) {
    throw new HttpsError('not-found', 'Store not found.', {
      code: ErrorCodes.RESOURCE_NOT_FOUND,
    });
  }
  const store = storeSnap.data() as StoreDoc;

  // 친구 audience 조회 — accepted only, ≤ 500 (ADR-302 § fanout 임계).
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
        colorTier,
        colorHex,
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
          colorTier,
          colorHex,
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
      colorTier: colorTier ?? 'none',
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
