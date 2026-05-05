import { FieldValue } from 'firebase-admin/firestore';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';

import { logInfo, logWarn } from '../utils/logger.js';
import { derivePinTier, PinTier } from '../utils/pinTier.js';
import { BACKGROUND_DEFAULTS } from '../utils/region.js';

/**
 * `stores.pinTier` derive — server-data ADR-302 v1.2 정합.
 *
 * 트리거 2종:
 *   1) onCreate stores/{placeId}: 시드 생성 또는 큐레이터 추가 시 derive + set.
 *      seedStores.ts 마이그레이션에서 직접 set하는 경우 본 트리거가 idempotent로 통과(skip).
 *   2) onUpdate stores/{placeId}: matchaScore 또는 verified 변경 시 재 derive.
 *      다른 필드만 변경 시 skip(write 비용 절감).
 *
 * `recomputeStoreAggregates`(매시 정각)도 매장 doc 갱신 시 직접 pinTier를 함께 set하므로
 * 본 트리거가 무한 루프하지 않도록 idempotent skip 로직 필수.
 */

export const onCreateStorePinTier = onDocumentCreated(
  {
    ...BACKGROUND_DEFAULTS,
    document: 'stores/{placeId}',
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data() as StoreFields;
    const computed = derivePinTier(data.matchaScore ?? 0, data.verified ?? false);
    if (data.pinTier === computed) return; // idempotent skip

    try {
      await snap.ref.update({
        pinTier: computed,
        updatedAt: FieldValue.serverTimestamp(),
      });
      logInfo('pin_tier_set_on_create', {
        fn: 'onCreateStorePinTier',
        placeId: event.params.placeId,
        pinTier: computed,
      });
    } catch (err) {
      logWarn('pin_tier_set_on_create_failed', {
        fn: 'onCreateStorePinTier',
        placeId: event.params.placeId,
        err,
      });
    }
  },
);

export const onUpdateStorePinTier = onDocumentUpdated(
  {
    ...BACKGROUND_DEFAULTS,
    document: 'stores/{placeId}',
  },
  async (event) => {
    const before = event.data?.before.data() as StoreFields | undefined;
    const after = event.data?.after.data() as StoreFields | undefined;
    if (!before || !after) return;

    const scoreChanged = (before.matchaScore ?? 0) !== (after.matchaScore ?? 0);
    const verifiedChanged = (before.verified ?? false) !== (after.verified ?? false);
    if (!scoreChanged && !verifiedChanged) return;

    const computed = derivePinTier(after.matchaScore ?? 0, after.verified ?? false);
    if (after.pinTier === computed) return; // idempotent — 무한 루프 방지

    try {
      await event.data!.after.ref.update({
        pinTier: computed,
        updatedAt: FieldValue.serverTimestamp(),
      });
      logInfo('pin_tier_set_on_update', {
        fn: 'onUpdateStorePinTier',
        placeId: event.params.placeId,
        before: after.pinTier ?? null,
        after: computed,
      });
    } catch (err) {
      logWarn('pin_tier_set_on_update_failed', {
        fn: 'onUpdateStorePinTier',
        placeId: event.params.placeId,
        err,
      });
    }
  },
);

interface StoreFields {
  matchaScore?: number;
  verified?: boolean;
  pinTier?: PinTier;
}
