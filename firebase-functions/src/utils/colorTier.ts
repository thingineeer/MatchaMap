/**
 * `collections/items.colorTier` enum 5단계 → `colorHex` 자동 매핑.
 *
 * SSOT: `docs/design/design-system.md` § 1.5.1 (designer-lead v1.1).
 * 본 상수는 design-system.md § 1.5.1 매핑 표를 직접 인용. 변경 시 3곳 동시 갱신:
 *   1. design-system.md § 1.5.1 (디자인 SSOT, designer-lead 권한)
 *   2. 본 파일 (server-functions)
 *   3. iOS DesignSystem `MMColorTier.color` (designer-lead / ios-social-collection)
 *
 * 정책 (server-data ADR-302 v1.1):
 *   - 클라가 보낸 colorTier만 신뢰. colorHex 직접 입력은 무시.
 *   - 미래 호환: free hex picker 도입 시 `colorTier=null` + `colorHex` 직접 입력 분기.
 */
export const COLOR_TIERS = [
  'matchaSoft',
  'matchaPale',
  'matcha',
  'deepMatcha',
  'deep',
] as const;

export type ColorTier = (typeof COLOR_TIERS)[number];

/**
 * design-system.md § 1.5.1 매핑 표 (인용):
 *   matchaSoft  #A8B994  Color.MM.matchaSoft   (stop 1, 가장 연한 우스차)
 *   matchaPale  #E6ECDE  Color.MM.matchaPale   (stop 2, 연두빛)
 *   matcha      #7A9560  Color.MM.matcha       (stop 3, 표준 / 중심값)
 *   deepMatcha  #556B43  Color.MM.deepMatcha   (stop 4, 진한 코이차) — designer-lead 사인오프 정정 (deep 쪽 치우침 위계 우월)
 *   deep        #3D4A2D  Color.MM.deep         (stop 5, 가장 진함)
 */
const COLOR_TIER_TO_HEX: Readonly<Record<ColorTier, string>> = Object.freeze({
  matchaSoft: '#A8B994',
  matchaPale: '#E6ECDE',
  matcha: '#7A9560',
  deepMatcha: '#556B43',
  deep: '#3D4A2D',
});

export function isColorTier(value: unknown): value is ColorTier {
  return typeof value === 'string' && (COLOR_TIERS as readonly string[]).includes(value);
}

export function colorHexForTier(tier: ColorTier): string {
  return COLOR_TIER_TO_HEX[tier];
}
