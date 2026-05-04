// FeatureMonetize — AdMob 슬롯(배너/인터스티셜/보상형) + ATT + 첫 60초 차단 가드.
// 의존: Domain, DesignSystem (+ Phase 3에서 GoogleMobileAds, StoreKit).
//
// Phase 3에서 채울 항목:
// - BannerAdView.swift          (지도 화면 하단)
// - InterstitialAdCoordinator.swift  (매장 상세 진입 N=5회마다, 쿨다운 90초)
// - RewardedAdCoordinator.swift  (도감 잠금 해제)
// - ATTPromptCoordinator.swift   (App Tracking Transparency)
// - FirstSixtySecondsGuard.swift (첫 60초 광고 차단 — UX 보호)
//
// 정책 본문은 docs/product/admob-slots.md / decisions-monetization.md 참조.

import Domain
import DesignSystem

public enum FeatureMonetize {
    public static let version: String = "0.1.0"
}
