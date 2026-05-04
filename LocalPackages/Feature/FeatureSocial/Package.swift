// swift-tools-version: 6.0
// FeatureSocial — 친구 피드, 친구 추가/수락, 알림.
// 의존: Domain, DesignSystem. Data import 금지.

import PackageDescription

let package = Package(
    name: "FeatureSocial",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(name: "FeatureSocial", targets: ["FeatureSocial"])
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(
            name: "FeatureSocial",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
                .product(name: "DesignSystem", package: "DesignSystem")
            ],
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        ),
        .testTarget(
            name: "FeatureSocialTests",
            dependencies: ["FeatureSocial"]
        )
    ]
)
