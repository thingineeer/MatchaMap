import { onDocumentUpdated } from 'firebase-functions/v2/firestore';

import { db } from '../utils/admin.js';
import { logInfo, logWarn } from '../utils/logger.js';
import { BACKGROUND_DEFAULTS } from '../utils/region.js';

/**
 * 디노멀 fanout — `stores/{placeId}.{name, primaryPhoto, origin}` 변경 시 복제 갱신.
 *
 * 갱신 대상 (schema.md §0.3 + ADR-302 § Functions 표):
 *   - reviews where storeId == X → store.{name, city, country, primaryPhoto}
 *   - wishlists/*/items/{X} → store.{...}
 *   - collections/*/items where storeId == X (collection group) → store.{...}
 *   - feed_events where target.placeId == X → target.{...}
 *
 * 정책:
 *   - origin은 매장 SSOT만 — 디노멀 안 함. origin 변경 시 fanout 대상 아님 (사용자 도감
 *     카드 grade/originRegion 별도, schema §5.1).
 *   - 단, ADR-302 § Functions 표에서 origin 변경도 fanout 대상으로 명시 (po-lead 요청).
 *     해석: origin 변경 = "큐레이터가 매장 메타 갱신" = 향후 화면 노출 위해 디노멀 필드를
 *     함께 표기할 수도 있음. 현 schema.md는 origin을 reviews/etc에 디노멀 안 했으므로,
 *     본 트리거는 origin 변경 시 명시적으로 *no-op*하고 로그만 남김. server-data와 합의 후
 *     디노멀 추가 시 본 함수 보강.
 */
export const onUpdateStore = onDocumentUpdated(
  {
    ...BACKGROUND_DEFAULTS,
    document: 'stores/{placeId}',
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    const placeId = event.params.placeId;

    const nameChanged = before.name !== after.name;
    const photoChanged = (before.primaryPhoto ?? null) !== (after.primaryPhoto ?? null);
    const originChanged = JSON.stringify(before.origin ?? null) !== JSON.stringify(after.origin ?? null);

    if (!nameChanged && !photoChanged && !originChanged) return;

    const storePatch = {
      'store.name': after.name,
      'store.city': after.city,
      'store.country': after.country,
      'store.primaryPhoto': after.primaryPhoto ?? null,
    };
    const targetPatch = {
      'target.name': after.name,
      'target.city': after.city,
      'target.country': after.country,
      'target.primaryPhoto': after.primaryPhoto ?? null,
    };

    let updated = 0;
    try {
      if (nameChanged || photoChanged) {
        updated += await fanoutWhereField('reviews', 'storeId', placeId, storePatch);
        updated += await fanoutCollectionGroup('items', 'storeId', placeId, storePatch);
        updated += await fanoutWishlistItems(placeId, storePatch);
        updated += await fanoutFeedTarget(placeId, targetPatch);
      }
      if (originChanged) {
        // origin 변경은 현재 디노멀 안 됨. server-data 합의 후 본 함수 갱신.
        logInfo('store_origin_changed_noop', {
          fn: 'onUpdateStore',
          placeId,
          before: before.origin ?? null,
          after: after.origin ?? null,
        });
      }
      logInfo('store_denorm_fanout', {
        fn: 'onUpdateStore',
        placeId,
        nameChanged,
        photoChanged,
        originChanged,
        docsUpdated: updated,
      });
    } catch (err) {
      logWarn('store_denorm_fanout_failed', { fn: 'onUpdateStore', placeId, err });
    }
  },
);

async function fanoutWhereField(
  collection: string,
  whereField: string,
  value: string,
  patch: Record<string, unknown>,
): Promise<number> {
  let total = 0;
  let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;
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

async function fanoutCollectionGroup(
  groupName: string,
  whereField: string,
  value: string,
  patch: Record<string, unknown>,
): Promise<number> {
  let total = 0;
  let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  for (let i = 0; i < 50; i++) {
    let q = db().collectionGroup(groupName).where(whereField, '==', value).limit(500);
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

async function fanoutWishlistItems(
  placeId: string,
  patch: Record<string, unknown>,
): Promise<number> {
  // wishlists/{uid}/items/{storeId == placeId}. 모든 사용자에 대해 doc.id가 placeId인 doc.
  // collection group 사용 + storeId 필드 매치.
  return fanoutCollectionGroup('items', 'storeId', placeId, patch);
}

async function fanoutFeedTarget(
  placeId: string,
  patch: Record<string, unknown>,
): Promise<number> {
  // feed_events.target.placeId == X. 인덱스가 필요. server-data와 인덱스 합의 (Phase 3).
  // 현 Phase는 placeId가 단일 키 검색 가능하도록 별도 필드 `targetId`로 매치 (schema §7.1).
  return fanoutWhereField('feed_events', 'targetId', placeId, patch);
}
