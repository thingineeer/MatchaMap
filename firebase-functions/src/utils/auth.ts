import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';

import { ErrorCodes } from './errors.js';

/**
 * Auth 토큰 검증. 미인증 호출 거부 + uid 반환.
 *
 * 정책 (server-auth ADR-303 + ADR-304):
 *   - 모든 콜러블은 Apple Sign In / Passkey / Anonymous 중 하나의 Firebase ID 토큰 필수.
 *   - Anonymous는 게스트 모드 진입용으로 ADR-304부터 허용.
 *   - 정식 사용자 자원을 변경하는 콜러블은 별도로 `assertNotAnonymous(req)`도 호출.
 */
export function assertAuthenticated(req: CallableRequest<unknown>): { uid: string } {
  const uid = req.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Sign-in required.');
  }
  return { uid };
}

/**
 * 호출자 uid가 리소스 owner와 일치하는지 검증. 본인 자원만 수정 가능한 콜러블에 사용.
 */
export function assertOwner(req: CallableRequest<unknown>, ownerUid: string): { uid: string } {
  const { uid } = assertAuthenticated(req);
  if (uid !== ownerUid) {
    throw new HttpsError('permission-denied', 'Only the resource owner may perform this action.');
  }
  return { uid };
}

/**
 * ADR-304 — 익명 사용자(sign_in_provider='anonymous') 호출 거부.
 * 적용 콜러블: submitReview / addCollectionItem / requestFriend / acceptFriend / verifyRewardedAd.
 *
 * 클라(iOS)는 details.code === AUTH_ANONYMOUS_FORBIDDEN 수신 시 LoginIntent 시트 표시.
 */
export function assertNotAnonymous(req: CallableRequest<unknown>): void {
  const provider = (req.auth?.token as { firebase?: { sign_in_provider?: string } } | undefined)
    ?.firebase?.sign_in_provider;
  if (provider === 'anonymous') {
    throw new HttpsError(
      'permission-denied',
      'Anonymous users cannot perform this action.',
      { code: ErrorCodes.AUTH_ANONYMOUS_FORBIDDEN }
    );
  }
}
