import { FieldValue } from 'firebase-admin/firestore';
import { beforeUserCreated } from 'firebase-functions/v2/identity';

import { db } from '../utils/admin.js';
import { logError, logInfo } from '../utils/logger.js';
import { DEFAULT_REGION } from '../utils/region.js';

/**
 * Firebase Auth blocking trigger — 사용자 가입 직후 `users/{uid}` 문서 시드.
 *
 * schema.md §1 정합:
 *   - uid == doc.id == auth.uid (3중 invariant)
 *   - displayName: Apple displayName 또는 자동 생성("matcha_lover_<6 hex>")
 *   - locale / homeCountry: 첫 콜러블 호출 시 클라가 갱신 (가입 시점에는 미상)
 *   - cohortD0: 가입 일자 KST 자정 기준 — observability `cohort_d0` user property SSOT
 *   - authMethod: providerId 매핑
 *   - stats.{collectionCount, reviewCount, wishlistCount, friendCount} = 0
 *
 * blocking trigger를 사용하는 이유:
 *   - 가입 직후 첫 콜러블 호출 시점에 users 문서가 보장되어야 race-condition 회피.
 *
 * 실패 정책:
 *   - blocking trigger에서 throw 시 가입 거부 → 사용자 경험 악화.
 *   - 본 함수는 throw하지 않고 로그만. 가입은 항상 성공.
 *   - 후속 시드 보정: 첫 콜러블 호출 시 누락 시 자동 생성 fallback (Phase 3).
 */
export const onUserCreated = beforeUserCreated(
  { region: DEFAULT_REGION },
  async (event) => {
    const user = event.data;
    if (!user) return;

    const uid = user.uid;
    const provider = resolveProvider(user.providerData?.[0]?.providerId);
    const cohortD0 = computeCohortD0(new Date());
    const displayName = user.displayName ?? `matcha_lover_${uid.slice(0, 6)}`;

    try {
      await db()
        .collection('users')
        .doc(uid)
        .set(
          {
            uid,
            displayName,
            photoURL: user.photoURL ?? null,
            locale: 'ko-KR',
            homeCountry: 'KR',
            travelMode: false,
            cohortD0,
            authMethod: provider,
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
            stats: {
              collectionCount: 0,
              reviewCount: 0,
              wishlistCount: 0,
              friendCount: 0,
            },
          },
          { merge: true },
        );
      logInfo('user_seed_created', { fn: 'onUserCreated', uid, provider });
    } catch (err) {
      logError('user_seed_failed', { fn: 'onUserCreated', uid, err });
    }
  },
);

function resolveProvider(raw: string | undefined): 'apple' | 'passkey' {
  if (raw === 'apple.com') return 'apple';
  if (raw === 'passkey' || raw === 'webauthn.io') return 'passkey';
  return 'apple';
}

function computeCohortD0(now: Date): Date {
  const kst = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  kst.setUTCHours(0, 0, 0, 0);
  return new Date(kst.getTime() - 9 * 60 * 60 * 1000);
}
