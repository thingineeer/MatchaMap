// swift-tools-version: 6.0
// FeatureMonetize — AdMob 슬롯(배너/인터스티셜/보상형) + ATT + 첫 60초 차단 가드.
// 의존: Domain, DesignSystem, GoogleMobileAds, StoreKit(시스템). Data import 금지.

import PackageDescription

let package = Package(
    name: "FeatureMonetize",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(name: "FeatureMonetize", targets: ["FeatureMonetize"])
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../DesignSystem")
        // Phase 3 추가 예정:
        // .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads", from: "11.0.0")
    ],
    targets: [
        .target(
            name: "FeatureMonetize",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
                .product(name: "DesignSystem", package: "DesignSystem")
                // .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")
            ],
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        ),
        .testTarget(
            name: "FeatureMonetizeTests",
            dependencies: ["FeatureMonetize"]
        )
    ]
)
