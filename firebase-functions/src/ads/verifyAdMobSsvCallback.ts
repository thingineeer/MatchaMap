import * as crypto from 'node:crypto';

import { FieldValue } from 'firebase-admin/firestore';
import { onRequest } from 'firebase-functions/v2/https';

import { db } from '../utils/admin.js';
import { logError, logInfo, logWarn } from '../utils/logger.js';
import { DEFAULT_REGION } from '../utils/region.js';

interface VerifierKey {
  keyId: number;
  pem: string;
  base64: string;
}

interface VerifierKeysResponse {
  keys: VerifierKey[];
}

const VERIFIER_KEYS_URL = 'https://www.gstatic.com/admob/reward/verifier-keys.json';
const KEY_CACHE_TTL_MS = 60 * 60 * 1000;
const RECEIPT_TTL_MS = 24 * 60 * 60 * 1000;

interface CachedKeys {
  fetchedAt: number;
  keys: Map<number, string>;
}

let cache: CachedKeys | null = null;

async function getVerifierKeys(): Promise<Map<number, string>> {
  const now = Date.now();
  if (cache && now - cache.fetchedAt < KEY_CACHE_TTL_MS) {
    return cache.keys;
  }
  const res = await fetch(VERIFIER_KEYS_URL);
  if (!res.ok) {
    throw new Error(`Failed to fetch AdMob verifier keys: ${res.status}`);
  }
  const data = (await res.json()) as VerifierKeysResponse;
  const map = new Map<number, string>();
  for (const k of data.keys) {
    map.set(k.keyId, k.pem);
  }
  cache = { fetchedAt: now, keys: map };
  return map;
}

function buildSignedString(rawQuery: string): string {
  const idx = rawQuery.lastIndexOf('&signature=');
  if (idx < 0) throw new Error('signature param missing');
  return rawQuery.slice(0, idx);
}

function base64UrlToBuffer(s: string): Buffer {
  const pad = s.length % 4 === 0 ? '' : '='.repeat(4 - (s.length % 4));
  return Buffer.from(s.replace(/-/g, '+').replace(/_/g, '/') + pad, 'base64');
}

export const verifyAdMobSsvCallback = onRequest(
  {
    region: DEFAULT_REGION,
    timeoutSeconds: 30,
    memory: '256MiB',
    cors: false,
    invoker: 'public',
  },
  async (req, res) => {
    if (req.method !== 'GET') {
      res.status(405).send('method_not_allowed');
      return;
    }

    const rawQuery = (req.url.split('?')[1] || '').trim();
    if (!rawQuery) {
      res.status(400).send('missing_query');
      return;
    }

    const params = new URLSearchParams(rawQuery);
    const keyIdStr = params.get('key_id');
    const signatureB64 = params.get('signature');
    const transactionId = params.get('transaction_id');
    const adUnit = params.get('ad_unit');
    const userId = params.get('user_id');
    const rewardItem = params.get('reward_item');
    const rewardAmount = params.get('reward_amount');
    const timestampMs = params.get('timestamp');

    if (!keyIdStr || !signatureB64 || !transactionId || !adUnit || !timestampMs) {
      logWarn('ssv_missing_param', { fn: 'verifyAdMobSsvCallback', transactionId });
      res.status(400).send('missing_param');
      return;
    }

    const keyId = Number.parseInt(keyIdStr, 10);
    if (Number.isNaN(keyId)) {
      res.status(400).send('invalid_key_id');
      return;
    }

    const ts = Number.parseInt(timestampMs, 10);
    if (Number.isNaN(ts) || Math.abs(Date.now() - ts) > RECEIPT_TTL_MS) {
      logWarn('ssv_expired', { fn: 'verifyAdMobSsvCallback', transactionId, ts });
      res.status(400).send('expired_or_invalid_timestamp');
      return;
    }

    let pem: string | undefined;
    try {
      const keys = await getVerifierKeys();
      pem = keys.get(keyId);
    } catch (err) {
      logError('ssv_keys_fetch_failed', { fn: 'verifyAdMobSsvCallback', err });
      res.status(500).send('keys_unavailable');
      return;
    }

    if (!pem) {
      logWarn('ssv_unknown_key', { fn: 'verifyAdMobSsvCallback', keyId });
      res.status(400).send('unknown_key_id');
      return;
    }

    const signedString = buildSignedString(rawQuery);
    const sig = base64UrlToBuffer(signatureB64);

    const ok = crypto.verify(
      'sha256',
      Buffer.from(signedString),
      { key: pem, dsaEncoding: 'der' },
      sig,
    );

    if (!ok) {
      logWarn('ssv_signature_mismatch', { fn: 'verifyAdMobSsvCallback', transactionId, keyId });
      res.status(403).send('invalid_signature');
      return;
    }

    const receiptRef = db().collection('rewardedReceipts').doc(transactionId);

    try {
      await db().runTransaction(async (tx) => {
        const snap = await tx.get(receiptRef);
        if (snap.exists) {
          return;
        }
        tx.set(receiptRef, {
          transactionId,
          adUnitId: adUnit,
          userId: userId ?? null,
          rewardItem: rewardItem ?? null,
          rewardAmount: rewardAmount ? Number.parseFloat(rewardAmount) : null,
          signedAt: FieldValue.serverTimestamp(),
          callbackTimestampMs: ts,
          keyId,
        });
      });

      logInfo('ssv_receipt_written', {
        fn: 'verifyAdMobSsvCallback',
        transactionId,
        adUnit,
        userId,
      });

      res.status(200).send('ok');
    } catch (err) {
      logError('ssv_receipt_failed', { fn: 'verifyAdMobSsvCallback', transactionId, err });
      res.status(500).send('receipt_failed');
    }
  },
);
