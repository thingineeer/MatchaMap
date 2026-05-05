import { getMessaging, MulticastMessage } from 'firebase-admin/messaging';

import { db } from '../utils/admin.js';
import { logInfo, logWarn } from '../utils/logger.js';

/**
 * Push 발송 헬퍼 — server-data ADR-302 v1.3.
 *
 * 흐름:
 *   1) `users/{uid}/fcmTokens` where pushPermission ∈ ['granted','provisional'] read.
 *   2) admin SDK sendEachForMulticast(...).
 *   3) 401/404 응답 토큰 doc 삭제 (만료/디바이스 분리 — push-payload.md 정책).
 *   4) lastSeenAt 갱신 X (push 수신 ≠ 앱 활성, 클라가 포그라운드 시 별도 갱신).
 *
 * push-payload.md (server-auth 작성)와 정합. 친구 피드 / 친구 요청 / 도감 알림 등
 * 모든 push는 본 헬퍼 경유.
 */

export interface PushPayload {
  notification?: { title?: string; body?: string };
  data?: Record<string, string>;
  /** category — push-payload.md analytics 분류용. */
  category: 'friend_request' | 'friend_accepted' | 'feed_collection' | 'feed_review' | 'system';
}

export interface SendResult {
  delivered: number;
  failed: number;
  pruned: number; // 만료 토큰 삭제 개수
}

const PRUNE_ERROR_CODES = new Set([
  'messaging/invalid-argument',
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);

export async function sendNotificationToUser(
  uid: string,
  payload: PushPayload,
): Promise<SendResult> {
  const tokensSnap = await db()
    .collection('users')
    .doc(uid)
    .collection('fcmTokens')
    .where('pushPermission', 'in', ['granted', 'provisional'])
    .get();

  const tokens: { tokenId: string; token: string }[] = [];
  for (const doc of tokensSnap.docs) {
    const t = doc.data() as { token?: string };
    if (typeof t.token === 'string' && t.token.length > 0) {
      tokens.push({ tokenId: doc.id, token: t.token });
    }
  }

  if (tokens.length === 0) {
    return { delivered: 0, failed: 0, pruned: 0 };
  }

  const message: MulticastMessage = {
    tokens: tokens.map((t) => t.token),
    notification: payload.notification,
    data: { ...(payload.data ?? {}), category: payload.category },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          'mutable-content': 1,
        },
      },
    },
  };

  let delivered = 0;
  let failed = 0;
  let pruned = 0;
  try {
    const result = await getMessaging().sendEachForMulticast(message);
    const stale: { tokenId: string }[] = [];
    result.responses.forEach((resp, idx) => {
      if (resp.success) {
        delivered++;
      } else {
        failed++;
        const code = resp.error?.code;
        if (code && PRUNE_ERROR_CODES.has(code)) {
          stale.push({ tokenId: tokens[idx].tokenId });
        }
      }
    });
    if (stale.length > 0) {
      const batch = db().batch();
      for (const s of stale) {
        batch.delete(
          db().collection('users').doc(uid).collection('fcmTokens').doc(s.tokenId),
        );
      }
      await batch.commit();
      pruned = stale.length;
    }
    logInfo('push_sent', {
      fn: 'sendNotificationToUser',
      uid,
      category: payload.category,
      delivered,
      failed,
      pruned,
    });
  } catch (err) {
    logWarn('push_send_failed', {
      fn: 'sendNotificationToUser',
      uid,
      category: payload.category,
      err,
    });
    failed = tokens.length;
  }

  return { delivered, failed, pruned };
}
