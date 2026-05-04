import { defineSecret } from 'firebase-functions/params';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { db } from '../utils/admin.js';
import { assertAppCheck } from '../utils/appCheck.js';
import { assertAuthenticated } from '../utils/auth.js';
import { ErrorCodes } from '../utils/errors.js';
import { logInfo } from '../utils/logger.js';
import { CALLABLE_DEFAULTS } from '../utils/region.js';

/**
 * 검색 보강 — 자사 매장 데이터 + Google Places 결과 머지.
 *
 * 흐름:
 *   1) 클라에서 viewport bbox + query 전달.
 *   2) Firestore `stores`에서 자사 인덱싱된 매장 우선 조회 (server-data 인덱스 합의).
 *   3) 부족 시 Google Places API 호출 (search/text 또는 places/searchNearby).
 *   4) Place ID로 dedupe → 단일 결과 반환.
 *
 * 정책:
 *   - 자사 매장 우선 (검증된 데이터 우위).
 *   - Places 결과는 캐시 (TTL 24h, `placesCache/{placeId}`).
 *   - 비용 보호: 단일 호출당 Places API ≤ 1회.
 *
 * Phase 2 산출물: 인터페이스만. 실제 Places 통합은 ios-store/server-data 합의 후 Phase 3.
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
}

interface MergeStoreSearchResponse {
  results: SearchResult[];
  source: { firstParty: number; places: number; cached: number };
}

interface SearchResult {
  storeId: string | null;
  placeId: string | null;
  name: string;
  lat: number;
  lng: number;
  country: string;
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

    const max = Math.min(data.maxResults ?? 20, 50);

    // Phase 2 placeholder: 자사 매장만 조회. Places 통합은 Phase 3.
    const firstPartySnap = await db()
      .collection('stores')
      .where('keywords', 'array-contains', data.query.toLowerCase())
      .limit(max)
      .get();

    const results: SearchResult[] = firstPartySnap.docs.map((doc) => {
      const s = doc.data();
      return {
        storeId: doc.id,
        placeId: (s.placeId as string | undefined) ?? null,
        name: s.name as string,
        lat: s.lat as number,
        lng: s.lng as number,
        country: s.country as string,
        rating: s.ratingAvg as number | undefined,
        isFirstParty: true,
      };
    });

    logInfo('search_merged', {
      fn: 'mergeStoreSearch',
      uid,
      query: data.query,
      firstPartyCount: results.length,
    });

    return {
      results,
      source: { firstParty: results.length, places: 0, cached: 0 },
    };
  },
);
