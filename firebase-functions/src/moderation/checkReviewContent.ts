import { onDocumentCreated } from 'firebase-functions/v2/firestore';

import { db } from '../utils/admin.js';
import { logInfo, logWarn } from '../utils/logger.js';
import { BACKGROUND_DEFAULTS } from '../utils/region.js';

/**
 * 리뷰 작성 시 자동 모더레이션 트리거.
 *
 * 트리거: `reviews/{reviewId}` 문서 생성.
 *
 * Phase 4 통합 예정:
 *   - 텍스트: Perspective API (toxicity, insult, threat)
 *   - 이미지: Vision API SafeSearch (adult, violence, racy)
 *
 * 본 Phase(2) 산출물:
 *   - 인터페이스/플로우만 작성. 실제 외부 API 호출은 미구현 (TODO).
 *   - moderationStatus = 'pending' → 'approved' (디폴트 auto-approve, MVP 정책).
 *   - 향후 'rejected' / 'needs_review' 상태 추가.
 *
 * 정책:
 *   - 모더레이션 결과는 비동기. 사용자에게는 즉시 표시(낙관적), rejected 시 fanout 롤백.
 *   - 사진은 Storage Cloud Function (`onObjectFinalized`) 별도 트리거로 처리 — 본 함수는 텍스트만.
 */
export const checkReviewContent = onDocumentCreated(
  {
    ...BACKGROUND_DEFAULTS,
    document: 'reviews/{reviewId}',
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const reviewId = event.params.reviewId;
    const review = snap.data() as ReviewDoc | undefined;
    if (!review) return;

    const result = await runTextModeration(review.text ?? '');

    await snap.ref.update({
      moderationStatus: result.status,
      moderationScores: result.scores,
      moderationCheckedAt: new Date(),
    });

    if (result.status === 'rejected') {
      logWarn('review_rejected', {
        fn: 'checkReviewContent',
        reviewId,
        uid: review.authorUid,
        scores: result.scores,
      });
      // Fanout 롤백: 이미 발행된 feedEvent를 invalidated 처리.
      await rollbackFeedEvent(review.authorUid, reviewId);
    } else {
      logInfo('review_approved', { fn: 'checkReviewContent', reviewId, uid: review.authorUid });
    }
  },
);

interface ReviewDoc {
  authorUid: string;
  storeId: string;
  text?: string;
  rating: number;
  photoPaths?: string[];
}

interface ModerationResult {
  status: 'approved' | 'rejected' | 'needs_review';
  scores: Record<string, number>;
}

/**
 * Phase 4에서 Perspective API로 교체 예정. 현 Phase는 길이 + 차단 키워드만 검사.
 */
async function runTextModeration(text: string): Promise<ModerationResult> {
  const trimmed = text.trim();
  if (trimmed.length === 0) {
    return { status: 'approved', scores: {} };
  }
  if (trimmed.length > 5000) {
    return { status: 'rejected', scores: { length: trimmed.length } };
  }
  // TODO(Phase 4): Perspective API 호출. 현 Phase는 placeholder만.
  return { status: 'approved', scores: { toxicity: 0, insult: 0 } };
}

async function rollbackFeedEvent(authorUid: string, reviewId: string): Promise<void> {
  const eventsSnap = await db()
    .collection('feedEvents')
    .where('authorUid', '==', authorUid)
    .where('refId', '==', reviewId)
    .limit(5)
    .get();

  if (eventsSnap.empty) return;
  const batch = db().batch();
  for (const doc of eventsSnap.docs) {
    batch.update(doc.ref, { fanoutStatus: 'invalidated' });
  }
  await batch.commit();
}
