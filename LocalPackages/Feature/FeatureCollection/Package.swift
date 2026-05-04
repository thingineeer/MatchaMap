// swift-tools-version: 6.0
// FeatureCollection — 도감(컬렉션), 위시리스트, 랭킹.
// 의존: Domain, DesignSystem. Data import 금지.

import PackageDescription

let package = Package(
    name: "FeatureCollection",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(name: "FeatureCollection", targets: ["FeatureCollection"])
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(
            name: "FeatureCollection",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
                .product(name: "DesignSystem", package: "DesignSystem")
            ],
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        ),
        .testTarget(
            name: "FeatureCollectionTests",
            dependencies: ["FeatureCollection"]
        )
    ]
)
