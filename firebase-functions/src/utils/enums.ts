/**
 * server-data ADR-302 v1.1 정합 enum 셋.
 *
 * 서버 측 입력 검증 + iOS Domain enum과 1:1.
 */

export const COLLECTION_DRINKS = [
  'usucha',
  'koicha',
  'matcha_latte',
  'iced_matcha',
  'matcha_dessert',
  'other',
] as const;
export type CollectionDrink = (typeof COLLECTION_DRINKS)[number];

/**
 * v1.1: `cooking` → `standard` + `culinary`로 분리. `unknown` 유지.
 */
export const COLLECTION_GRADES = [
  'ceremonial',
  'premium',
  'standard',
  'culinary',
  'unknown',
] as const;
export type CollectionGrade = (typeof COLLECTION_GRADES)[number];

/**
 * v1.1: `jeju` 추가. 9종.
 */
export const ORIGIN_REGIONS = [
  'uji',
  'nishio',
  'kagoshima',
  'shizuoka',
  'boseong',
  'hadong',
  'jeju',
  'other',
  'unknown',
] as const;
export type OriginRegion = (typeof ORIGIN_REGIONS)[number];

export const REVIEW_DRINKS = [
  'usucha',
  'koicha',
  'matcha_latte',
  'iced_matcha',
  'dessert',
  'other',
] as const;
export type ReviewDrink = (typeof REVIEW_DRINKS)[number];

export function isOneOf<T extends string>(
  values: readonly T[],
  value: unknown,
): value is T {
  return typeof value === 'string' && (values as readonly string[]).includes(value);
}
