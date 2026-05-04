// swift-tools-version: 6.0
// FeatureMap — 지도 화면 + 매장 핀 마커 + 카메라 제어.
// 의존: Domain, DesignSystem, GoogleMaps. Data import 금지.

import PackageDescription

let package = Package(
    name: "FeatureMap",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(name: "FeatureMap", targets: ["FeatureMap"])
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../DesignSystem")
        // Phase 3 추가 예정:
        // .package(url: "https://github.com/googlemaps/ios-maps-sdk", from: "9.0.0")
    ],
    targets: [
        .target(
            name: "FeatureMap",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
                .product(name: "DesignSystem", package: "DesignSystem")
                // .product(name: "GoogleMaps", package: "ios-maps-sdk")
            ],
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        ),
        .testTarget(
            name: "FeatureMapTests",
            dependencies: ["FeatureMap"]
        )
    ]
)
