/**
 * ULID 생성 — 시간 정렬 가능한 26자 식별자.
 *
 * 외부 의존성 없이 inline 구현 (firebase-functions 환경의 cold-start 비용 최소화).
 * RFC: https://github.com/ulid/spec
 *
 * Crockford Base32 인코딩.
 */
import { randomBytes } from 'node:crypto';

const ENCODING = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
const ENCODING_LEN = ENCODING.length;
const TIME_LEN = 10;
const RANDOM_LEN = 16;

export function ulid(seed = Date.now()): string {
  return encodeTime(seed) + encodeRandom();
}

function encodeTime(now: number): string {
  let mod: number;
  let str = '';
  for (let i = TIME_LEN - 1; i >= 0; i--) {
    mod = now % ENCODING_LEN;
    str = ENCODING.charAt(mod) + str;
    now = (now - mod) / ENCODING_LEN;
  }
  return str;
}

function encodeRandom(): string {
  const bytes = randomBytes(RANDOM_LEN);
  let str = '';
  for (let i = 0; i < RANDOM_LEN; i++) {
    str += ENCODING.charAt(bytes[i] % ENCODING_LEN);
  }
  return str;
}
