import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

/**
 * Lazy admin SDK 초기화. 콜드 스타트마다 1회만 실행되도록 idempotent.
 * 테스트(emulator)는 환경변수 `FIRESTORE_EMULATOR_HOST` 등으로 자동 라우팅.
 */
function ensureApp() {
  if (getApps().length === 0) {
    initializeApp();
  }
}

export function db() {
  ensureApp();
  return getFirestore();
}

export function auth() {
  ensureApp();
  return getAuth();
}
