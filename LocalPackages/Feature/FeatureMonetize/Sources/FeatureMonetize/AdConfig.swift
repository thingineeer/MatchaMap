import Foundation

/// AdMob 광고 슬롯 정의 — vault `~/.env-vault/projects/matchamap-ios/admob.json` 매핑.
/// MVP 3 슬롯: 배너(맵 하단), 인터스티셜(매장 상세 진입 N=5회마다), 보상형(도감 잠금 해제).
public enum AdSlot: String, Sendable, Hashable, CaseIterable {
    case bannerMapBottom
    case interstitialStoreDetail
    case rewardedCollectionUnlock

    /// vault admob.json의 키 — Phase 5에서 실제 값 주입.
    public var vaultKey: String {
        switch self {
        case .bannerMapBottom:           return "GAD_BANNER_MAP_UNIT_ID"
        case .interstitialStoreDetail:   return "GAD_INTERSTITIAL_STORE_UNIT_ID"
        case .rewardedCollectionUnlock:  return "GAD_REWARDED_UNLOCK_UNIT_ID"
        }
    }
}

/// 광고 정책 — `docs/product/admob-slots.md` SSOT.
public enum AdPolicy {
    /// 첫 사용 60초 동안 광고 노출 금지 (UX 보호).
    public static let firstSessionGuardSeconds: TimeInterval = 60
    /// 인터스티셜 노출 빈도 — 매장 상세 진입 N회마다 1회.
    public static let interstitialEveryNVisits: Int = 5
    /// 인터스티셜 쿨다운.
    public static let interstitialCooldownSeconds: TimeInterval = 90
}
