import { defineSecret } from 'firebase-functions/params';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { db } from '../utils/admin.js';
import { assertAppCheck } from '../utils/appCheck.js';
import { assertAuthenticated } from '../utils/auth.js';
import { ErrorCodes } from '../utils/errors.js';
import { logInfo } from '../utils/logger.js';
import { isPinTier, PinTier, pinTierAtLeast } from '../utils/pinTier.js';
import { CALLABLE_DEFAULTS } from '../utils/region.js';

/**
 * 검색 보강 — 자사 매장 데이터 + Google Places 결과 머지.
 *
 * 흐름:
 *   1) 클라에서 viewport bbox + query (+ minPinTier?) 전달.
 *   2) Firestore `stores`에서 자사 인덱싱된 매장 우선 조회.
 *   3) 부족 시 Google Places API 호출 (Phase 3).
 *   4) Place ID로 dedupe → 단일 결과 반환.
 *
 * 정책:
 *   - 자사 매장 우선.
 *   - Places 결과는 캐시 (TTL 24h, `placesCache/{placeId}`, Phase 3).
 *   - 비용 보호: 단일 호출당 Places API ≤ 1회.
 *
 * v1.2 (server-data ADR-302): `minPinTier` 필터 추가 — viewport 디클러스터링용.
 *   `country × pinTier × matchaScore DESC` 인덱스 사용.
 *
 * Phase 2 산출물: 자사 매장만. Places 통합은 Phase 3.
 */
const GOOGLE_PLACES_API_KEY = defineSecret('GOOGLE_PLACES_API_KEY');

interface MergeStoreSearchRequest {
  query: string;
  viewport: {
    northEast: { lat: number; lng: number };
    southWest: { lat: number; lng: number };
  };
  locale: string;
  maxResults?: number;
  cursor?: string;
  minPinTier?: PinTier; // S만 / A 이상 등 (v1.2)
}

interface MergeStoreSearchResponse {
  results: SearchResult[];
  nextCursor: string | null;
  source: { firstParty: number; places: number; cached: number };
}

interface SearchResult {
  storeId: string | null;
  placeId: string | null;
  name: string;
  lat: number;
  lng: number;
  country: string;
  pinTier?: PinTier;
  rating?: number;
  isFirstParty: boolean;
}

export const mergeStoreSearch = onCall<MergeStoreSearchRequest, Promise<MergeStoreSearchResponse>>(
  {
    ...CALLABLE_DEFAULTS,
    secrets: [GOOGLE_PLACES_API_KEY],
    timeoutSeconds: 20,
  },
  async (req) => {
    assertAppCheck(req);
    const { uid } = assertAuthenticated(req);

    const data = req.data;
    if (
      !data ||
      typeof data.query !== 'string' ||
      data.query.length < 1 ||
      data.query.length > 100 ||
      !data.viewport ||
      !data.locale
    ) {
      throw new HttpsError('invalid-argument', 'Invalid search payload.', {
        code: ErrorCodes.INVALID_ARGUMENT,
      });
    }
    if (data.minPinTier !== undefined && !isPinTier(data.minPinTier)) {
      throw new HttpsError('invalid-argument', 'Invalid minPinTier enum.', {
        code: ErrorCodes.INVALID_ARGUMENT,
      });
    }

    const max = Math.min(data.maxResults ?? 20, 50);
    const minPinTier = data.minPinTier;

    // Phase 2: 자사 매장만. keywords array-contains + (옵션) minPinTier 클라/서버 필터.
    const firstPartySnap = await db()
      .collection('stores')
      .where('keywords', 'array-contains', data.query.toLowerCase())
      .limit(max * 2) // post-filter 손실 보전
      .get();

    const results: SearchResult[] = [];
    for (const doc of firstPartySnap.docs) {
      const s = doc.data();
      const pinTier = isPinTier(s.pinTier) ? (s.pinTier as PinTier) : undefined;
      if (minPinTier && pinTier && !pinTierAtLeast(pinTier, minPinTier)) continue;
      results.push({
        storeId: doc.id,
        placeId: (s.placeId as string | undefined) ?? null,
        name: s.name as string,
        lat: s.lat as number,
        lng: s.lng as number,
        country: s.country as string,
        pinTier,
        rating: s.ratingAvg as number | undefined,
        isFirstParty: true,
      });
      if (results.length >= max) break;
    }

    logInfo('search_merged', {
      fn: 'mergeStoreSearch',
      uid,
      query: data.query,
      firstPartyCount: results.length,
      minPinTier: minPinTier ?? 'none',
    });

    return {
      results,
      nextCursor: null,
      source: { firstParty: results.length, places: 0, cached: 0 },
    };
  },
);
