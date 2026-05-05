/**
 * `stores.pinTier` derive — server-data ADR-302 v1.2 정합.
 *
 * iOS Repository `storesInBounds(minPinTier:)` viewport 디클러스터링 + designer-icon
 * MatchaPin 4등급 정합.
 *
 * 분기:
 *   - `S` = verified && matchaScore ≥ 4.5
 *   - `A` = verified && 4.0 ≤ matchaScore < 4.5
 *   - `B` = (3.0 ≤ matchaScore < 4.0) || (verified && matchaScore < 4.0)
 *   - `C` = !verified && matchaScore < 3.0
 *
 * 즉 verified=true는 최소 B 보장.
 */
export type PinTier = 'S' | 'A' | 'B' | 'C';

export const PIN_TIERS: readonly PinTier[] = ['S', 'A', 'B', 'C'] as const;

/** S > A > B > C. 비교 시 작을수록 상위. */
const PIN_TIER_RANK: Record<PinTier, number> = { S: 0, A: 1, B: 2, C: 3 };

export function derivePinTier(matchaScore: number, verified: boolean): PinTier {
  if (verified && matchaScore >= 4.5) return 'S';
  if (verified && matchaScore >= 4.0) return 'A';
  if (matchaScore >= 3.0) return 'B';
  if (verified) return 'B';
  return 'C';
}

export function isPinTier(value: unknown): value is PinTier {
  return value === 'S' || value === 'A' || value === 'B' || value === 'C';
}

/** `minPinTier` 필터 — `pin >= S`(상위)일 때만 포함. */
export function pinTierAtLeast(pin: PinTier, min: PinTier): boolean {
  return PIN_TIER_RANK[pin] <= PIN_TIER_RANK[min];
}
