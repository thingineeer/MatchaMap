/**
 * server-data ADR-302 v1.1 / v1.2 enum 정합 테스트.
 */
import { describe, expect, it } from 'vitest';

import { colorHexForTier, COLOR_TIERS, isColorTier } from '../src/utils/colorTier.js';
import {
  COLLECTION_DRINKS,
  COLLECTION_GRADES,
  isOneOf,
  ORIGIN_REGIONS,
} from '../src/utils/enums.js';
import { derivePinTier, isPinTier, pinTierAtLeast } from '../src/utils/pinTier.js';

describe('collection enums (v1.1)', () => {
  it('grades reject legacy `cooking`', () => {
    expect(isOneOf(COLLECTION_GRADES, 'cooking')).toBe(false);
    expect(isOneOf(COLLECTION_GRADES, 'standard')).toBe(true);
    expect(isOneOf(COLLECTION_GRADES, 'culinary')).toBe(true);
    expect(isOneOf(COLLECTION_GRADES, 'unknown')).toBe(true);
  });

  it('originRegions include jeju (v1.1 +1)', () => {
    expect(isOneOf(ORIGIN_REGIONS, 'jeju')).toBe(true);
    expect(ORIGIN_REGIONS.length).toBe(9);
  });

  it('drinks for collections accept matcha_dessert', () => {
    expect(isOneOf(COLLECTION_DRINKS, 'matcha_dessert')).toBe(true);
    expect(isOneOf(COLLECTION_DRINKS, 'dessert')).toBe(false);
  });
});

describe('colorTier (v1.1, design-system.md § 1.5.1 SSOT)', () => {
  it('5 tiers in order', () => {
    expect(COLOR_TIERS).toEqual([
      'matchaSoft',
      'matchaPale',
      'matcha',
      'deepMatcha',
      'deep',
    ]);
  });

  it('hex values match design-system.md § 1.5.1', () => {
    expect(colorHexForTier('matchaSoft')).toBe('#A8B994');
    expect(colorHexForTier('matchaPale')).toBe('#E6ECDE');
    expect(colorHexForTier('matcha')).toBe('#7A9560');
    expect(colorHexForTier('deepMatcha')).toBe('#556B43');
    expect(colorHexForTier('deep')).toBe('#3D4A2D');
  });

  it('isColorTier guard', () => {
    expect(isColorTier('matcha')).toBe(true);
    expect(isColorTier('cooking')).toBe(false);
    expect(isColorTier(null)).toBe(false);
  });
});

describe('pinTier (v1.2)', () => {
  it('S = verified && score ≥ 4.5', () => {
    expect(derivePinTier(4.6, true)).toBe('S');
    expect(derivePinTier(4.5, true)).toBe('S');
    expect(derivePinTier(4.6, false)).toBe('B');
  });

  it('A = verified && 4.0 ≤ score < 4.5', () => {
    expect(derivePinTier(4.0, true)).toBe('A');
    expect(derivePinTier(4.49, true)).toBe('A');
  });

  it('verified guarantees at least B', () => {
    expect(derivePinTier(2.0, true)).toBe('B');
    expect(derivePinTier(3.5, true)).toBe('B');
  });

  it('C = !verified && score < 3.0', () => {
    expect(derivePinTier(2.9, false)).toBe('C');
    expect(derivePinTier(0, false)).toBe('C');
  });

  it('B = !verified && 3.0 ≤ score', () => {
    expect(derivePinTier(3.0, false)).toBe('B');
    expect(derivePinTier(4.9, false)).toBe('B');
  });

  it('isPinTier guard', () => {
    expect(isPinTier('S')).toBe(true);
    expect(isPinTier('Z')).toBe(false);
  });

  it('pinTierAtLeast: S ≥ A ≥ B ≥ C', () => {
    expect(pinTierAtLeast('S', 'A')).toBe(true);
    expect(pinTierAtLeast('A', 'S')).toBe(false);
    expect(pinTierAtLeast('B', 'B')).toBe(true);
    expect(pinTierAtLeast('C', 'B')).toBe(false);
  });
});
