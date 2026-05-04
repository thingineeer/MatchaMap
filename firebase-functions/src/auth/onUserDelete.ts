/**
 * Auth onDelete 트리거 — 사용자 계정 삭제 시 모든 자원 일괄 삭제
 * ============================================================================
 * 작성: server-auth (ADR-303 §6)
 * SSOT: docs/server/schema.md (server-data, ADR-302)
 *
 * Apple App Store Review Guideline 5.1.1(v) 정합 — Sign in with Apple로 가입한
 * 사용자는 앱 내에서 계정 삭제 메뉴 제공 + 데이터 완전 삭제 필수.
 *
 * 흐름 (ADR-303 §6.1):
 *   1. 클라가 콜러블 confirmAccountDeletion(token) 호출 (server-functions Phase 2-3) →
 *      Functions가 Admin SDK로 Auth deleteUser(uid) 호출.
 *   2. 본 트리거(onUserDelete)가 발화하여 데이터 정리:
 *      - Firestore: 사용자 작성 reviews/* 삭제 + 연관 사진 경로 수집
 *      - Firestore: 사용자 좋아요(likes/{reviewId}/users/{uid}) 삭제 (likeCount 감소는 Functions onLikeWrite)
 *      - Firestore: 친구 양방향 doc 삭제 (friendships/{otherUid}/edges/{uid} + friendships/{uid}/edges/*)
 *      - Firestore: feed_events.audienceUids에서 uid 제거 또는 actorUid가 본인인 doc 삭제
 *      - Firestore: wishlists/{uid}/items/* 삭제
 *      - Firestore: collections/{uid}/items/* 삭제
 *      - Firestore: users/{uid}/fcmTokens/* + private/* + 본 doc 삭제
 *      - Storage: users/{uid}/, users/{uid}/collection/, reviews/{reviewId}/(자기 작성) 객체 삭제
 *
 * 트랜잭션 보장 (ADR-303 §6.2):
 *   - Firestore batch는 500 ops/batch 한도 → N개 batch chain.
 *   - 각 batch 사이 진행 상태를 users/{uid}/private/_deletion_progress 문서에 기록.
 *   - 실패 시 마지막 성공 idx부터 재시도 (idempotent).
 *   - 트리거 실패 시 scheduler/finishStaleDeletions cron(server-functions Phase 2-3)이
 *     30분마다 _deletion_progress.completed=false 인 사용자를 재처리.
 *
 * 주의: 2nd gen에서 Auth onDelete는 firebase-functions v1 API 또는 Identity Platform blocking
 * functions로 작성 가능. MVP는 v1 API 사용 (검증된 패턴, FearIndex-iOS와 동일).
 * 옵션 (b) 도입(ADR-303 §5.6) 시 Identity Platform blocking functions로 전환 검토.
 */

import * as functionsV1 from 'firebase-functions/v1';
import {
  FieldValue,
  Timestamp,
  type DocumentReference,
  type WriteBatch,
} from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { db } from '../utils/admin.js';
import { DEFAULT_REGION } from '../utils/region.js';
import { logInfo, logWarn, logError } from '../utils/logger.js';

const BATCH_LIMIT = 500;
const STORAGE_BATCH_LIMIT = 100;

interface DeletionProgress {
  uid: string;
  startedAt: Timestamp;
  lastBatchIdx: number;
  completed: boolean;
  errorCount: number;
  lastError?: string;
}

export const onUserDelete = functionsV1
  .region(DEFAULT_REGION)
  .auth.user()
  .onDelete(async (user) => {
    const { uid } = user;
    logInfo('onUserDelete:start', { fn: 'onUserDelete', uid });

    const progressRef = db()
      .collection('users')
      .doc(uid)
      .collection('private')
      .doc('_deletion_progress');

    await safeSet(progressRef, {
      uid,
      startedAt: Timestamp.now(),
      lastBatchIdx: 0,
      completed: false,
      errorCount: 0,
    } satisfies DeletionProgress);

    let batchIdx = 0;
    const reviewPhotoPaths: string[] = [];

    try {
      // 1) reviews — 사용자 작성 리뷰 삭제 + 사진 경로 수집
      batchIdx = await deleteReviewsByAuthor(uid, batchIdx, progressRef, reviewPhotoPaths);

      // 2) likes — 사용자가 누른 좋아요 마커 삭제 (reviews.likeCount 감소는 onLikeWrite 트리거)
      batchIdx = await deleteLikesByUser(uid, batchIdx, progressRef);

      // 3) friendships — 양방향 친구 edge 삭제
      batchIdx = await deleteFriendshipEdges(uid, batchIdx, progressRef);

      // 4) feed_events — actorUid == uid doc 삭제 (audience-only 갱신은 비용 ↑이므로 retention 90일에 위임)
      batchIdx = await deleteFeedEventsByActor(uid, batchIdx, progressRef);

      // 5) wishlists/{uid}/items/* + collections/{uid}/items/* 삭제
      batchIdx = await deleteUserItemsSubcollection(`wishlists/${uid}/items`, uid, batchIdx, progressRef);
      batchIdx = await deleteUserItemsSubcollection(`collections/${uid}/items`, uid, batchIdx, progressRef);

      // 6) users/{uid}/fcmTokens/* 삭제
      batchIdx = await deleteUserSubcollection(uid, 'fcmTokens', batchIdx, progressRef);

      // 7) Storage 객체 삭제
      await deleteStorageObjects(uid, reviewPhotoPaths);

      // 8) users/{uid}/private/* (progress 외) 삭제 + users/{uid} 본 doc 삭제 (마지막)
      batchIdx = await deleteUserDoc(uid, batchIdx, progressRef);

      logInfo('onUserDelete:done', { fn: 'onUserDelete', uid, batchCount: batchIdx });
    } catch (err) {
      logError('onUserDelete:fatal', { fn: 'onUserDelete', uid, err });
      await safeSet(progressRef, {
        errorCount: FieldValue.increment(1) as unknown as number,
        lastError: (err as Error).message,
      } as Partial<DeletionProgress>);
      // re-throw 해서 Functions 재시도 정책에 맡김 — scheduler/finishStaleDeletions가 추가 재시도.
      throw err;
    }
  });

// ============================================================================
// 1) 사용자 작성 리뷰 삭제 + 사진 경로 수집
// ============================================================================
async function deleteReviewsByAuthor(
  uid: string,
  startBatchIdx: number,
  progressRef: DocumentReference,
  outPhotoPaths: string[],
): Promise<number> {
  let batchIdx = startBatchIdx;
  const reviewsRef = db().collection('reviews');

  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await reviewsRef.where('uid', '==', uid).limit(BATCH_LIMIT).get();
    if (snap.empty) break;

    const batch = db().batch();
    snap.docs.forEach((doc) => {
      const data = doc.data();
      const photos = data.photos;
      if (Array.isArray(photos)) {
        for (const p of photos) {
          if (typeof p === 'string') outPhotoPaths.push(stripGsPrefix(p));
        }
      }
      batch.delete(doc.ref);
    });
    await commitWithRetry(batch, 'reviews', uid, progressRef);

    batchIdx += 1;
    await advanceProgress(progressRef, batchIdx);

    if (snap.size < BATCH_LIMIT) break;
  }
  return batchIdx;
}

// ============================================================================
// 2) 사용자가 누른 좋아요 마커 삭제
// ============================================================================
async function deleteLikesByUser(
  uid: string,
  startBatchIdx: number,
  progressRef: DocumentReference,
): Promise<number> {
  let batchIdx = startBatchIdx;

  // collection group "users" 중 likes/{reviewId}/users/{uid} 패턴.
  // schema.md §0.3 patterns — doc.id == uid + data.uid == uid (P6).
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await db()
      .collectionGroup('users')
      .where('uid', '==', uid)
      .where('reviewId', '!=', null)
      .limit(BATCH_LIMIT)
      .get()
      .catch((err) => {
        logWarn('onUserDelete:likes:queryFail', { fn: 'onUserDelete', uid, err });
        return null;
      });

    if (!snap || snap.empty) break;

    const batch = db().batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await commitWithRetry(batch, 'likes', uid, progressRef);

    batchIdx += 1;
    await advanceProgress(progressRef, batchIdx);

    if (snap.size < BATCH_LIMIT) break;
  }
  return batchIdx;
}

// ============================================================================
// 3) friendships — 양방향 edge 삭제
//   - friendships/{uid}/edges/{*}: 본인 노드의 모든 edge
//   - friendships/{otherUid}/edges/{uid}: 다른 사용자가 본인을 가진 edge (collection group)
// ============================================================================
async function deleteFriendshipEdges(
  uid: string,
  startBatchIdx: number,
  progressRef: DocumentReference,
): Promise<number> {
  let batchIdx = startBatchIdx;

  // a) friendships/{uid}/edges/* (본인 노드)
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await db()
      .collection('friendships')
      .doc(uid)
      .collection('edges')
      .limit(BATCH_LIMIT)
      .get();
    if (snap.empty) break;

    const batch = db().batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await commitWithRetry(batch, 'friendships(self)', uid, progressRef);

    batchIdx += 1;
    await advanceProgress(progressRef, batchIdx);

    if (snap.size < BATCH_LIMIT) break;
  }

  // b) friendships/*/edges/{uid} 패턴 — collection group "edges" 중 friendUid == uid
  //    (schema.md §6: edges/{friendUid} doc.id == friendUid, data.friendUid == friendUid)
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await db()
      .collectionGroup('edges')
      .where('friendUid', '==', uid)
      .limit(BATCH_LIMIT)
      .get();
    if (snap.empty) break;

    const batch = db().batch();
    // 친구 측 stats.friendCount 감소도 함께 수행 (status==accepted였던 경우만)
    snap.docs.forEach((doc) => {
      const data = doc.data();
      if (data.status === 'accepted' && typeof data.uid === 'string' && data.uid !== uid) {
        const ownerRef = db().collection('users').doc(data.uid);
        batch.update(ownerRef, { 'stats.friendCount': FieldValue.increment(-1) });
      }
      batch.delete(doc.ref);
    });
    await commitWithRetry(batch, 'friendships(reverse)', uid, progressRef);

    batchIdx += 1;
    await advanceProgress(progressRef, batchIdx);

    if (snap.size < BATCH_LIMIT) break;
  }
  return batchIdx;
}

// ============================================================================
// 4) feed_events — actorUid == uid 삭제
//   audienceUids에 uid가 포함된 doc은 삭제하지 않음 (다른 사용자의 피드 흐름 보존,
//   본 사용자가 삭제되었으므로 audience filter에서 자연스럽게 빠짐 — 90일 retention으로 정리).
// ============================================================================
async function deleteFeedEventsByActor(
  uid: string,
  startBatchIdx: number,
  progressRef: DocumentReference,
): Promise<number> {
  let batchIdx = startBatchIdx;

  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await db()
      .collection('feed_events')
      .where('actorUid', '==', uid)
      .limit(BATCH_LIMIT)
      .get();
    if (snap.empty) break;

    const batch = db().batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await commitWithRetry(batch, 'feed_events', uid, progressRef);

    batchIdx += 1;
    await advanceProgress(progressRef, batchIdx);

    if (snap.size < BATCH_LIMIT) break;
  }
  return batchIdx;
}

// ============================================================================
// 5) wishlists/{uid}/items/* + collections/{uid}/items/* — 사용자 자원
// ============================================================================
async function deleteUserItemsSubcollection(
  collectionPath: string,
  uid: string,
  startBatchIdx: number,
  progressRef: DocumentReference,
): Promise<number> {
  let batchIdx = startBatchIdx;
  const ref = db().collection(collectionPath);

  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await ref.limit(BATCH_LIMIT).get();
    if (snap.empty) break;

    const batch = db().batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await commitWithRetry(batch, collectionPath, uid, progressRef);

    batchIdx += 1;
    await advanceProgress(progressRef, batchIdx);

    if (snap.size < BATCH_LIMIT) break;
  }
  return batchIdx;
}

// ============================================================================
// 6) users/{uid}/{sub}/* (fcmTokens 등)
// ============================================================================
async function deleteUserSubcollection(
  uid: string,
  sub: string,
  startBatchIdx: number,
  progressRef: DocumentReference,
): Promise<number> {
  let batchIdx = startBatchIdx;
  const userRef = db().collection('users').doc(uid);

  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await userRef.collection(sub).limit(BATCH_LIMIT).get();
    if (snap.empty) break;

    const batch = db().batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await commitWithRetry(batch, `users/${uid}/${sub}`, uid, progressRef);

    batchIdx += 1;
    await advanceProgress(progressRef, batchIdx);

    if (snap.size < BATCH_LIMIT) break;
  }
  return batchIdx;
}

// ============================================================================
// 8) users/{uid}/private/* + users/{uid} 본 doc 삭제 (마지막)
// ============================================================================
async function deleteUserDoc(
  uid: string,
  startBatchIdx: number,
  progressRef: DocumentReference,
): Promise<number> {
  const userRef = db().collection('users').doc(uid);

  // private 서브컬렉션의 _deletion_progress 외 다른 doc은 매우 드물지만 예방
  const privateSnap = await userRef.collection('private').get();
  for (const doc of privateSnap.docs) {
    if (doc.id === '_deletion_progress') continue;
    await doc.ref.delete().catch(() => undefined);
  }

  // 진행 추적 doc 삭제 + users/{uid} 본 doc 삭제
  const batch = db().batch();
  batch.delete(progressRef);
  batch.delete(userRef);
  await commitWithRetry(batch, 'users(root)', uid, progressRef);

  return startBatchIdx + 1;
}

// ============================================================================
// Storage 일괄 삭제
// ============================================================================
async function deleteStorageObjects(uid: string, reviewPhotoPaths: string[]): Promise<void> {
  const bucket = getStorage().bucket();

  // a) users/{uid}/ — 프로필 사진 + 도감 사진(users/{uid}/collection/{itemId}/{n}.jpg, schema.md §5.1)
  await bucket.deleteFiles({ prefix: `users/${uid}/` }).catch((err) => {
    logWarn('onUserDelete:storage:users:fail', { fn: 'onUserDelete', uid, err });
  });

  // b) thumbnails/users/{uid}/
  await bucket.deleteFiles({ prefix: `thumbnails/users/${uid}/` }).catch(() => undefined);

  // c) 사용자 작성 리뷰 사진 — reviews/{reviewId}/{n}.jpg (개별 삭제, 다른 사용자 리뷰 사진과 path가 분리됨)
  const chunks = chunk(reviewPhotoPaths, STORAGE_BATCH_LIMIT);
  for (const c of chunks) {
    await Promise.allSettled(
      c.map((path) =>
        bucket
          .file(path)
          .delete()
          .catch((err) => {
            logWarn('onUserDelete:storage:reviewPhoto:fail', {
              fn: 'onUserDelete',
              uid,
              path,
              err,
            });
          }),
      ),
    );
    // 썸네일도 함께
    await Promise.allSettled(
      c.map((path) =>
        bucket
          .file(`thumbnails/${path}`)
          .delete()
          .catch(() => undefined),
      ),
    );
  }
}

// ============================================================================
// 헬퍼
// ============================================================================
async function commitWithRetry(
  batch: WriteBatch,
  scope: string,
  uid: string,
  progressRef: DocumentReference,
  retries = 3,
): Promise<void> {
  for (let attempt = 1; attempt <= retries; attempt += 1) {
    try {
      await batch.commit();
      return;
    } catch (err) {
      if (attempt === retries) {
        logError('onUserDelete:batch:fail', { fn: 'onUserDelete', uid, scope, attempt, err });
        await safeSet(progressRef, {
          errorCount: FieldValue.increment(1) as unknown as number,
          lastError: `${scope}: ${(err as Error).message}`,
        } as Partial<DeletionProgress>);
        throw err;
      }
      await new Promise((r) => setTimeout(r, 250 * attempt));
    }
  }
}

async function advanceProgress(
  progressRef: DocumentReference,
  batchIdx: number,
): Promise<void> {
  await safeSet(progressRef, { lastBatchIdx: batchIdx } as Partial<DeletionProgress>);
}

async function safeSet(
  ref: DocumentReference,
  data: Partial<DeletionProgress> | DeletionProgress,
): Promise<void> {
  try {
    await ref.set(data, { merge: true });
  } catch (err) {
    // private 서브컬렉션이 이미 삭제된 경우 등 비치명적 — warn만 기록
    logWarn('onUserDelete:progressSet:nonfatal', {
      fn: 'onUserDelete',
      err,
    });
  }
}

function chunk<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) {
    out.push(arr.slice(i, i + size));
  }
  return out;
}

function stripGsPrefix(path: string): string {
  if (path.startsWith('gs://')) {
    // gs://bucket/path/to/file → path/to/file
    const idx = path.indexOf('/', 'gs://'.length);
    if (idx > 0) return path.substring(idx + 1);
  }
  return path;
}
