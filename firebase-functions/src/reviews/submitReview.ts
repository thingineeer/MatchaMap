import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { db } from '../utils/admin.js';
import { assertAppCheck } from '../utils/appCheck.js';
import { assertAuthenticated, assertNotAnonymous } from '../utils/auth.js';
import { ErrorCodes } from '../utils/errors.js';
import { logInfo, logWarn } from '../utils/logger.js';
import { CALLABLE_DEFAULTS } from '../utils/region.js';
import { ulid } from '../utils/ulid.js';

/**
 * 리뷰 작성 (트랜잭션 fanout).
 *
 * schema.md §3 + §5.5 + §7 정합:
 *   1) `reviews/{reviewId}` create (디노멀 author + store 포함).
 *   2) `users/{uid}.stats.reviewCount` += 1.
 *   3) `stores/{storeId}.{reviewCount, ratingAvg, ratingHistogram}` 갱신.
 *   4) `viaReview === true`인 경우 `addCollectionItem`과 동일한 fanout으로 도감 자동 생성.
 *   5) `feed_events/{eventId}` create.
 *
 * 모더레이션:
 *   - 본 콜러블은 reviews doc create만. 모더레이션은 `checkReviewContent` 트리거가 비동기.
 *   - 거부 시 `feed_events`는 트리거가 fanoutStatus=invalidated로 마킹.
 */

interface SubmitReviewRequest {
  storeId: string;
  rating: 1 | 2 | 3 | 4 | 5;
  body: string;
  photos?: string[];
  tags?: string[];
  drink?: 'usucha' | 'koicha' | 'matcha_latte' | 'iced_matcha' | 'dessert' | 'other';
  viaReview?: boolean; // 도감 자동 생성 여부 (디폴트 true)
}

interface SubmitReviewResponse {
  reviewId: string;
  collectionItemId?: string;
}

const MAX_AUDIENCE = 500;

export const submitReview = onCall<SubmitReviewRequest, Promise<SubmitReviewResponse>>(
  CALLABLE_DEFAULTS,
  async (req) => {
    assertAppCheck(req);
    const { uid } = assertAuthenticated(req);
    assertNotAnonymous(req);
    const data = req.data;

    if (
      !data ||
      typeof data.storeId !== 'string' ||
      typeof data.rating !== 'number' ||
      data.rating < 1 ||
      data.rating > 5 ||
      typeof data.body !== 'string' ||
      data.body.length < 1 ||
      data.body.length > 2000
    ) {
      throw new HttpsError('invalid-argument', 'Invalid review payload.', {
        code: ErrorCodes.INVALID_ARGUMENT,
      });
    }

    const reviewId = ulid();
    const reviewRef = db().collection('reviews').doc(reviewId);
    const storeRef = db().collection('stores').doc(data.storeId);
    const userRef = db().collection('users').doc(uid);

    const storeSnap = await storeRef.get();
    if (!storeSnap.exists) {
      throw new HttpsError('not-found', 'Store not found.', {
        code: ErrorCodes.RESOURCE_NOT_FOUND,
      });
    }
    const store = storeSnap.data() as {
      placeId: string;
      name: string;
      city: string;
      country: string;
      primaryPhoto?: string;
    };

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

    const viaReview = data.viaReview ?? true;
    const collectionItemId = viaReview ? ulid() : undefined;
    const eventId = ulid();

    try {
      await db().runTransaction(async (tx) => {
        const [userSnap, storeAggSnap] = await Promise.all([tx.get(userRef), tx.get(storeRef)]);
        const author = userSnap.data() as
          | { displayName?: string; photoURL?: string }
          | undefined;
        const agg = storeAggSnap.data() as
          | { reviewCount?: number; ratingAvg?: number; ratingHistogram?: Record<string, number> }
          | undefined;

        const prevCount = agg?.reviewCount ?? 0;
        const prevAvg = agg?.ratingAvg ?? 0;
        const newCount = prevCount + 1;
        const newAvg = (prevAvg * prevCount + data.rating) / newCount;
        const histKey = String(data.rating);
        const histInc = (agg?.ratingHistogram?.[histKey] ?? 0) + 1;

        tx.set(reviewRef, {
          reviewId,
          storeId: data.storeId,
          uid,
          rating: data.rating,
          body: data.body,
          photos: data.photos ?? [],
          tags: data.tags ?? [],
          drink: data.drink ?? null,
          country: store.country,
          author: {
            uid,
            displayName: author?.displayName ?? 'matcha_lover',
            photoURL: author?.photoURL ?? null,
          },
          store: {
            placeId: store.placeId,
            name: store.name,
            city: store.city,
            country: store.country,
            primaryPhoto: store.primaryPhoto ?? null,
          },
          likeCount: 0,
          flagged: false,
          flagCount: 0,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          moderationStatus: 'pending',
        });

        tx.update(userRef, {
          'stats.reviewCount': FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        });

        tx.update(storeRef, {
          reviewCount: newCount,
          ratingAvg: newAvg,
          [`ratingHistogram.${histKey}`]: histInc,
          updatedAt: FieldValue.serverTimestamp(),
        });

        if (viaReview && collectionItemId) {
          const itemRef = db()
            .collection('collections')
            .doc(uid)
            .collection('items')
            .doc(collectionItemId);
          tx.set(itemRef, {
            itemId: collectionItemId,
            uid,
            storeId: data.storeId,
            drink: data.drink ?? 'other',
            country: store.country,
            store: {
              placeId: store.placeId,
              name: store.name,
              city: store.city,
              country: store.country,
              primaryPhoto: store.primaryPhoto ?? null,
            },
            viaReview: true,
            linkedReviewId: reviewId,
            visitedAt: FieldValue.serverTimestamp(),
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
          tx.update(userRef, {
            'stats.collectionCount': FieldValue.increment(1),
          });
        }

        const feedRef = db().collection('feed_events').doc(eventId);
        tx.set(feedRef, {
          eventId,
          actorUid: uid,
          audienceUids,
          type: 'review',
          targetType: 'review',
          targetId: reviewId,
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
            rating: data.rating,
            body_excerpt: data.body.slice(0, 140),
            photo: (data.photos ?? [])[0] ?? null,
          },
          country: store.country,
          visibility: 'friends',
          createdAt: FieldValue.serverTimestamp(),
        });
      });

      logInfo('review_submitted', {
        fn: 'submitReview',
        uid,
        reviewId,
        storeId: data.storeId,
        viaReview,
      });

      return { reviewId, collectionItemId };
    } catch (err) {
      if (err instanceof HttpsError) {
        logWarn('review_rejected', { fn: 'submitReview', uid, reviewId, err });
        throw err;
      }
      logWarn('review_failed', { fn: 'submitReview', uid, reviewId, err });
      throw new HttpsError('internal', 'Failed to submit review.', {
        code: ErrorCodes.INTERNAL,
      });
    }
  },
);
