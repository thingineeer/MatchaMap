import { FieldValue } from 'firebase-admin/firestore';
import { defineSecret } from 'firebase-functions/params';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { db } from '../utils/admin.js';
import { assertAppCheck } from '../utils/appCheck.js';
import { assertAuthenticated, assertNotAnonymous } from '../utils/auth.js';
import { ErrorCodes } from '../utils/errors.js';
import { logError, logInfo, logWarn } from '../utils/logger.js';
import { CALLABLE_DEFAULTS } from '../utils/region.js';

/**
 * AdMob 보상형 광고 SSV(Server-Side Verification) 검증.
 *
 * 흐름:
 *   1) 클라가 보상형 광고 시청 완료.
 *   2) AdMob SDK가 SSV callback URL로 GET 요청 → (별도 HTTPS 함수 또는 Cloud Run)에서 1회성
 *      서명 검증 + Firestore `rewardedReceipts/{transactionId}` 도큐 작성.
 *   3) 클라가 광고 콜백 onUserEarnedReward 후 본 콜러블 호출 → 영수증 매칭 + 도감 슬롯 해제.
 *
 * 본 콜러블의 역할:
 *   - SSV 영수증의 존재 + 유효성(만료/replay) 확인.
 *   - 도감 슬롯 잠금 해제 트랜잭션 (`users/{uid}.collectionSlotsUnlocked` ++).
 *   - 일일 보상 한도 검증 (남용 방지, monetization.md 가드레일).
 *
 * 주의:
 *   - SSV signature 검증 자체는 별도 HTTPS 함수(verifyAdMobSsvCallback)에서 수행.
 *     본 콜러블은 그 결과 영수증을 신뢰. 본 콜러블은 SSV 키를 직접 다루지 않는다.
 *   - 동일 transactionId 재호출은 idempotent (이미 unlock된 영수증은 OK 응답).
 *
 * 일일 한도 정책 (ios-auth-monetize 합의):
 *   - 사용자당 일 5회 보상형 광고 시청 가능.
 *   - users/{uid}/rewardedQuota/{YYYYMMDD} = { count: int }.
 */
const ADMOB_SSV_PUBLIC_KEY = defineSecret('ADMOB_SSV_PUBLIC_KEY');

const DAILY_REWARD_LIMIT = 5;

interface VerifyRewardedAdRequest {
  transactionId: string;
  adUnitId: string;
  rewardType: 'collection_slot';
  rewardAmount: number;
}

interface VerifyRewardedAdResponse {
  ok: true;
  collectionSlotsUnlocked: number;
  remainingDailyRewards: number;
}

export const verifyRewardedAd = onCall<VerifyRewardedAdRequest, Promise<VerifyRewardedAdResponse>>(
  {
    ...CALLABLE_DEFAULTS,
    secrets: [ADMOB_SSV_PUBLIC_KEY],
  },
  async (req) => {
    assertAppCheck(req);
    const { uid } = assertAuthenticated(req);
    assertNotAnonymous(req);

    const data = req.data;
    if (
      !data ||
      typeof data.transactionId !== 'string' ||
      typeof data.adUnitId !== 'string' ||
      data.rewardType !== 'collection_slot' ||
      typeof data.rewardAmount !== 'number' ||
      data.rewardAmount < 1
    ) {
      throw new HttpsError('invalid-argument', 'Invalid rewarded ad payload.', {
        code: ErrorCodes.INVALID_ARGUMENT,
      });
    }

    const today = todayKey();
    const receiptRef = db().collection('rewardedReceipts').doc(data.transactionId);
    const userRef = db().collection('users').doc(uid);
    const quotaRef = userRef.collection('rewardedQuota').doc(today);

    try {
      const result = await db().runTransaction(async (tx) => {
        const [receiptSnap, userSnap, quotaSnap] = await Promise.all([
          tx.get(receiptRef),
          tx.get(userRef),
          tx.get(quotaRef),
        ]);

        if (!receiptSnap.exists) {
          throw new HttpsError('not-found', 'Rewarded ad receipt not found.', {
            code: ErrorCodes.REWARDED_AD_INVALID_SIGNATURE,
          });
        }
        const receipt = receiptSnap.data() as RewardedReceipt;

        if (receipt.consumedByUid && receipt.consumedByUid !== uid) {
          throw new HttpsError('failed-precondition', 'Receipt already consumed by another user.', {
            code: ErrorCodes.REWARDED_AD_REPLAY,
          });
        }
        if (receipt.consumedByUid === uid) {
          // idempotent — 이미 처리된 영수증 재호출.
          const slots = (userSnap.data()?.collectionSlotsUnlocked as number | undefined) ?? 0;
          const used = (quotaSnap.data()?.count as number | undefined) ?? 0;
          return { slots, remaining: Math.max(0, DAILY_REWARD_LIMIT - used) };
        }

        const used = (quotaSnap.data()?.count as number | undefined) ?? 0;
        if (used >= DAILY_REWARD_LIMIT) {
          throw new HttpsError('resource-exhausted', 'Daily rewarded ad limit reached.', {
            code: ErrorCodes.REWARDED_AD_QUOTA_EXCEEDED,
          });
        }

        tx.update(receiptRef, {
          consumedByUid: uid,
          consumedAt: FieldValue.serverTimestamp(),
        });
        tx.set(
          userRef,
          {
            collectionSlotsUnlocked: FieldValue.increment(data.rewardAmount),
          },
          { merge: true },
        );
        tx.set(
          quotaRef,
          {
            count: FieldValue.increment(1),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );

        const slots =
          ((userSnap.data()?.collectionSlotsUnlocked as number | undefined) ?? 0) +
          data.rewardAmount;
        return { slots, remaining: DAILY_REWARD_LIMIT - used - 1 };
      });

      logInfo('rewarded_ad_verified', {
        fn: 'verifyRewardedAd',
        uid,
        transactionId: data.transactionId,
        adUnitId: data.adUnitId,
      });

      return {
        ok: true,
        collectionSlotsUnlocked: result.slots,
        remainingDailyRewards: result.remaining,
      };
    } catch (err) {
      if (err instanceof HttpsError) {
        logWarn('rewarded_ad_rejected', {
          fn: 'verifyRewardedAd',
          uid,
          transactionId: data.transactionId,
          err,
        });
        throw err;
      }
      logError('rewarded_ad_internal', {
        fn: 'verifyRewardedAd',
        uid,
        transactionId: data.transactionId,
        err,
      });
      throw new HttpsError('internal', 'Failed to verify rewarded ad.', {
        code: ErrorCodes.INTERNAL,
      });
    }
  },
);

interface RewardedReceipt {
  transactionId: string;
  adUnitId: string;
  signedAt: FirebaseFirestore.Timestamp;
  consumedByUid?: string;
  consumedAt?: FirebaseFirestore.Timestamp;
}

function todayKey(): string {
  // KST 기준 YYYYMMDD. 보상 한도 일일 컷오프는 KST 자정.
  const now = new Date();
  const kst = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  const y = kst.getUTCFullYear();
  const m = String(kst.getUTCMonth() + 1).padStart(2, '0');
  const d = String(kst.getUTCDate()).padStart(2, '0');
  return `${y}${m}${d}`;
}
