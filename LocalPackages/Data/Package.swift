// swift-tools-version: 6.0
// Data — Domain Repository 프로토콜 구현체.
// Firebase / GoogleMaps / GooglePlaces SDK 의존.
// Feature/* import 금지. DesignSystem import 금지.
//
// 외부 의존성은 앱 타깃의 Xcode Local Package 단계에서 SDK들을 추가하고,
// 그 후 본 Package.swift에 .product(...) 의존을 풀어 둔다 (현 단계에서는 주석으로 명시).

import PackageDescription

let package = Package(
    name: "Data",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(name: "Data", targets: ["Data"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Domain"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0")
        // Phase 3 후속 — Map/Places SDK는 FeatureMap이 직접 의존:
        // .package(url: "https://github.com/googlemaps/ios-maps-sdk", from: "9.0.0"),
        // .package(url: "https://github.com/googlemaps/ios-places-sdk", from: "9.0.0")
    ],
    targets: [
        .target(
            name: "Data",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Domain", package: "Domain"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
            ],
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        ),
        .testTarget(
            name: "DataTests",
            dependencies: ["Data"]
        )
    ]
)
