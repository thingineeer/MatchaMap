import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';

/**
 * Auth 토큰 검증. 익명 호출 거부 + uid 반환.
 *
 * 정책 (server-auth ADR-303):
 *   - 모든 콜러블은 Apple Sign In 또는 Passkey로 발급된 Firebase ID 토큰 필수.
 *   - 익명 Auth는 MVP에서 비활성 (firebase-setup-checklist.md § 3).
 *   - 토큰의 sign-in provider가 `apple.com` 또는 `passkey` (custom token)만 허용.
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
