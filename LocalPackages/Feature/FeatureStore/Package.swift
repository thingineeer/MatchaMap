// swift-tools-version: 6.0
// FeatureStore — 매장 상세, 메뉴, 리뷰, 검색·필터.
// 의존: Domain, DesignSystem. Data import 금지.

import PackageDescription

let package = Package(
    name: "FeatureStore",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(name: "FeatureStore", targets: ["FeatureStore"])
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(
            name: "FeatureStore",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
                .product(name: "DesignSystem", package: "DesignSystem")
            ],
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        ),
        .testTarget(
            name: "FeatureStoreTests",
            dependencies: ["FeatureStore"]
        )
    ]
)
