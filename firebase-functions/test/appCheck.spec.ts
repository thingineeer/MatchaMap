/**
 * 단위 테스트 — App Check 헬퍼.
 *
 * 외부 의존성 없이 fakeRequest로 검증.
 */
import { afterEach, beforeEach, describe, expect, it } from 'vitest';

import { assertAppCheck } from '../src/utils/appCheck.js';

interface FakeReq {
  app?: unknown;
  rawRequest?: { headers: Record<string, string> };
  data: unknown;
}

function fakeRequest(opts: { withAppCheck: boolean }): FakeReq {
  return {
    app: opts.withAppCheck ? { token: 'fake', appId: 'fake' } : undefined,
    rawRequest: { headers: { 'user-agent': 'vitest' } },
    data: {},
  };
}

describe('assertAppCheck', () => {
  const originalMode = process.env.MATCHAMAP_APPCHECK_MODE;

  afterEach(() => {
    if (originalMode === undefined) {
      delete process.env.MATCHAMAP_APPCHECK_MODE;
    } else {
      process.env.MATCHAMAP_APPCHECK_MODE = originalMode;
    }
  });

  it('passes when app check token is present (enforce mode)', () => {
    process.env.MATCHAMAP_APPCHECK_MODE = 'enforce';
    const req = fakeRequest({ withAppCheck: true });
    expect(() => assertAppCheck(req as never)).not.toThrow();
  });

  it('throws failed-precondition when token is missing (enforce mode)', () => {
    process.env.MATCHAMAP_APPCHECK_MODE = 'enforce';
    const req = fakeRequest({ withAppCheck: false });
    expect(() => assertAppCheck(req as never)).toThrow(/App Check verification failed/);
  });

  it('does not throw when token is missing (monitor mode)', () => {
    process.env.MATCHAMAP_APPCHECK_MODE = 'monitor';
    const req = fakeRequest({ withAppCheck: false });
    expect(() => assertAppCheck(req as never)).not.toThrow();
  });
});

describe('assertAuthenticated', () => {
  it('rejects unauthenticated requests', async () => {
    const { assertAuthenticated } = await import('../src/utils/auth.js');
    const req = { auth: undefined } as never;
    expect(() => assertAuthenticated(req)).toThrow(/Sign-in required/);
  });

  it('returns uid for authenticated requests', async () => {
    const { assertAuthenticated } = await import('../src/utils/auth.js');
    const req = { auth: { uid: 'test-uid' } } as never;
    expect(assertAuthenticated(req)).toEqual({ uid: 'test-uid' });
  });
});
