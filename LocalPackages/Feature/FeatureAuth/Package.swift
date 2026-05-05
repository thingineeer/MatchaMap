// swift-tools-version: 6.0
// FeatureAuth — Apple Sign In + Passkey UI.
// 의존: Domain, DesignSystem, AuthenticationServices(시스템 프레임워크). Data import 금지.

import PackageDescription

let package = Package(
    name: "FeatureAuth",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(name: "FeatureAuth", targets: ["FeatureAuth"])
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(
            name: "FeatureAuth",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
                .product(name: "DesignSystem", package: "DesignSystem")
            ],
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        ),
        .testTarget(
            name: "FeatureAuthTests",
            dependencies: ["FeatureAuth"]
        )
    ]
)
