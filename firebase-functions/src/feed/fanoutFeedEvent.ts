/**
 * Fanout-on-write 모델 — schema.md §7 `feed_events` 정합.
 *
 * 본 함수는 **단일 진입점이 아니다**. fanout-on-write의 SSOT는 `feed_events` doc 자체의
 * `audienceUids` 배열이며, 이 배열은 콜러블 (`addCollectionItem` / `submitReview` /
 * `acceptFriend`)이 **doc 생성 시점에 직접 채운다**.
 *
 * 본 트리거의 역할:
 *   1) audit/observability — feed_events 생성 시 분석 보조 로그.
 *   2) `audienceUids.length` 가드레일 — ADR-302-rev1 fanout-on-read 전환 트리거 모니터링
 *      (schema.md §12 SCH-6).
 *   3) 후속 정합 보정 (TODO Phase 3: 디노멀 drift fix-up).
 *
 * 클라가 직접 feed_events에 write하는 경로는 **없다** (security-rules P-feed: write Functions
 * only). 따라서 본 트리거는 fanout 자체를 *수행*하지 않는다 — 콜러블이 audienceUids를 채운
 * 상태로 doc create.
 *
 * 친구 ≥ 500 시 처리 (ADR-302 § fanout):
 *   - audienceUids 배열은 schema §7.1에서 0~500 items 제약.
 *   - 콜러블이 friendCount > 500 검출 시 `audienceUids = []` (빈) + `actorUid`만 저장 →
 *     fanout-on-read 모드 폴백.
 *   - 본 트리거는 임계 근접 시 Cloud Logging WARN으로 모니터링 신호.
 */
import { onDocumentCreated } from 'firebase-functions/v2/firestore';

import { logInfo, logWarn } from '../utils/logger.js';
import { BACKGROUND_DEFAULTS } from '../utils/region.js';

const FANOUT_THRESHOLD_WARN = 400;
const FANOUT_HARD_LIMIT = 500;

export const fanoutFeedEvent = onDocumentCreated(
  {
    ...BACKGROUND_DEFAULTS,
    document: 'feed_events/{eventId}',
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const eventId = event.params.eventId;
    const data = snap.data() as FeedEventDoc | undefined;
    if (!data || !data.actorUid || !Array.isArray(data.audienceUids)) {
      logWarn('feed_event_invalid', { fn: 'fanoutFeedEvent', eventId });
      return;
    }

    const size = data.audienceUids.length;

    if (size > FANOUT_HARD_LIMIT) {
      // 콜러블 측 가드 누락 = 정책 위반. 보안 규칙도 정합 차단해야 함.
      logWarn('feed_event_audience_overflow', {
        fn: 'fanoutFeedEvent',
        eventId,
        actorUid: data.actorUid,
        audienceSize: size,
      });
      return;
    }

    if (size >= FANOUT_THRESHOLD_WARN) {
      // ADR-302 fanout-on-read 전환 트리거 모니터링.
      logWarn('fanout_threshold_approaching', {
        fn: 'fanoutFeedEvent',
        eventId,
        actorUid: data.actorUid,
        audienceSize: size,
        threshold: FANOUT_HARD_LIMIT,
      });
    }

    logInfo('feed_event_created', {
      fn: 'fanoutFeedEvent',
      eventId,
      actorUid: data.actorUid,
      type: data.type,
      audienceSize: size,
    });
  },
);

interface FeedEventDoc {
  eventId: string;
  actorUid: string;
  audienceUids: string[];
  type: 'collection' | 'review' | 'checkin' | 'friend_added';
  targetType: 'store' | 'review' | 'collection_item' | 'user';
  targetId: string;
  visibility: 'friends' | 'public';
  country?: string;
}
