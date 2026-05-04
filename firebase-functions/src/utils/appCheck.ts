import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';

/**
 * 콜러블 함수에서 App Check를 강제 검증. 실패 시 `failed-precondition` 에러 throw.
 *
 * 정책 (server-auth ADR-303):
 *   - `enforceAppCheck: true` 옵션과 본 헬퍼는 **둘 다** 적용. SDK 레벨 거부와 더불어
 *     서버에서도 명시적으로 token presence를 확인하여 실수로 옵션이 빠진 경우 fail-safe.
 *   - 모니터링 모드(Phase 2 진입 직후 1주) 동안에는 `MATCHAMAP_APPCHECK_MODE=monitor` 환경변수로
 *     warn-only 모드 전환. 그 후 `enforce` 모드 디폴트.
 *   - Debug token은 시뮬레이터 빌드 한정 (~/.env-vault/.../appcheck-debug.txt).
 */
export function assertAppCheck(req: CallableRequest<unknown>): void {
  const mode = process.env.MATCHAMAP_APPCHECK_MODE ?? 'enforce';
  const hasToken = req.app !== undefined;

  if (hasToken) {
    return;
  }

  if (mode === 'monitor') {
    // Cloud Logging에 missing 토큰 기록. 거부하지 않음.
    console.warn(
      JSON.stringify({
        kind: 'app_check_missing',
        mode,
        rawRequest: req.rawRequest?.headers['user-agent'] ?? 'unknown',
      }),
    );
    return;
  }

  throw new HttpsError(
    'failed-precondition',
    'App Check verification failed. Client must attach a valid App Check token.',
  );
}
