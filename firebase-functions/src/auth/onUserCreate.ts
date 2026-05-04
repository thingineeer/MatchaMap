import { setGlobalOptions } from 'firebase-functions/v2';
import { beforeUserCreated } from 'firebase-functions/v2/identity';

import { db } from '../utils/admin.js';
import { logError, logInfo } from '../utils/logger.js';
import { DEFAULT_REGION } from '../utils/region.js';

setGlobalOptions({ region: DEFAULT_REGION });

/**
 * Firebase Auth blocking trigger — 사용자 가입 직후 `users/{uid}` 문서 시드.
 *
 * 스키마 정합 (server-data ADR-302):
 *   users/{uid} = {
 *     uid: string,
 *     authProvider: 'apple' | 'passkey',
 *     createdAt: Timestamp,
 *     homeCountry?: string,        // device locale 기반, 클라가 첫 호출에 갱신
 *     locale?: string,
 *     friendCount: 0,
 *     collectionSlotsUnlocked: 0,
 *     debugUser: boolean,
 *   }
 *
 * blocking trigger를 사용하는 이유:
 *   - 가입 직후 첫 콜러블 호출 시점에 users 문서가 보장되어야 race-condition 회피.
 *   - on-create(non-blocking) 트리거는 처리 지연이 있을 수 있음.
 *
 * 주의: blocking trigger는 콜드 스타트가 사용자 경험에 직접 영향. min instances는
 * server-lead가 트래픽 측정 후 결정.
 */
export const onUserCreated = beforeUserCreated(
  { region: DEFAULT_REGION },
  async (event) => {
    const user = event.data;
    if (!user) {
      return;
    }
    const uid = user.uid;
    const provider = resolveProvider(user.providerData?.[0]?.providerId);

    try {
      await db()
        .collection('users')
        .doc(uid)
        .set(
          {
            uid,
            authProvider: provider,
            createdAt: new Date(),
            friendCount: 0,
            collectionSlotsUnlocked: 0,
            debugUser: false,
          },
          { merge: true },
        );
      logInfo('user_seed_created', { fn: 'onUserCreated', uid, provider });
    } catch (err) {
      logError('user_seed_failed', { fn: 'onUserCreated', uid, err });
      // blocking trigger에서 throw하면 가입이 거부됨. 가입은 막지 않고 로그만.
    }
  },
);

function resolveProvider(raw: string | undefined): 'apple' | 'passkey' | 'unknown' {
  if (raw === 'apple.com') return 'apple';
  if (raw === 'passkey' || raw === 'webauthn.io') return 'passkey';
  return 'unknown';
}
