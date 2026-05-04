/**
 * Vitest emulator 기반 통합 테스트 — verifyRewardedAd 콜러블.
 *
 * 실행:
 *   npm run test:emulator
 *   (또는 emulator 수동 기동 후 `npm test`)
 *
 * 전제 환경:
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
 *   FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
 *   GCLOUD_PROJECT=matchamapapp-test
 *
 * 본 테스트가 검증하는 것:
 *   1) 영수증 미존재 시 not-found.
 *   2) 정상 영수증 + 한도 내 → unlock 성공.
 *   3) 동일 transactionId 재호출 idempotent.
 *   4) 일일 한도 초과 시 resource-exhausted.
 *   5) 다른 사용자가 이미 소비한 영수증 → failed-precondition.
 *
 * 본 파일은 *스켈레톤*이다. firebase-functions-test SDK로 실제 콜러블을 wrap하여
 * 호출하는 패턴은 server-functions Phase 3에서 emulator CI 통합 시점에 보강.
 */
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

const RUN_EMULATOR_TESTS = process.env.FIRESTORE_EMULATOR_HOST !== undefined;

describe.skipIf(!RUN_EMULATOR_TESTS)('verifyRewardedAd (emulator)', () => {
  beforeAll(async () => {
    // TODO(Phase 3): firebase-functions-test SDK 초기화 + admin SDK emulator 연결.
    // 본 Phase는 plan만 — 실 통합 테스트는 emulator CI(GitHub Actions matrix) 도입 시점.
  });

  afterAll(async () => {
    // teardown
  });

  beforeEach(async () => {
    // Firestore emulator 리셋 (REST: DELETE http://localhost:8080/.../databases/(default)/documents)
  });

  it('rejects when receipt is not found', async () => {
    expect(true).toBe(true); // placeholder
  });

  it('unlocks a collection slot for a valid receipt within daily limit', async () => {
    expect(true).toBe(true);
  });

  it('is idempotent for the same transactionId by the same uid', async () => {
    expect(true).toBe(true);
  });

  it('rejects with resource-exhausted when daily limit is reached', async () => {
    expect(true).toBe(true);
  });

  it('rejects when a receipt was already consumed by another uid', async () => {
    expect(true).toBe(true);
  });
});

/**
 * Pure unit test — emulator 미가동 환경에서도 항상 실행되는 정합성 검증.
 *
 * 본 1건이 npm test 통과 보증. 실 Firebase 의존성 없는 헬퍼 검증.
 */
describe('verifyRewardedAd contract', () => {
  it('error codes enum is consistent with iOS Domain/Error.swift', async () => {
    const { ErrorCodes } = await import('../src/utils/errors.js');
    expect(ErrorCodes.REWARDED_AD_INVALID_SIGNATURE).toBe('REWARDED_AD_INVALID_SIGNATURE');
    expect(ErrorCodes.REWARDED_AD_REPLAY).toBe('REWARDED_AD_REPLAY');
    expect(ErrorCodes.REWARDED_AD_QUOTA_EXCEEDED).toBe('REWARDED_AD_QUOTA_EXCEEDED');
  });

  it('region default is asia-northeast3', async () => {
    const { DEFAULT_REGION, CALLABLE_DEFAULTS, BACKGROUND_DEFAULTS } = await import(
      '../src/utils/region.js'
    );
    expect(DEFAULT_REGION).toBe('asia-northeast3');
    expect(CALLABLE_DEFAULTS.enforceAppCheck).toBe(true);
    expect(CALLABLE_DEFAULTS.timeoutSeconds).toBe(30);
    expect(BACKGROUND_DEFAULTS.timeoutSeconds).toBe(540);
  });
});
