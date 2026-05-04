// swift-tools-version: 6.0
// Domain — Entity, UseCase, Repository protocol.
// 외부 의존 0. 다른 LocalPackage import 금지.

import PackageDescription

let package = Package(
    name: "Domain",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(name: "Domain", targets: ["Domain"])
    ],
    targets: [
        .target(
            name: "Domain",
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"]
        )
    ]
)
