// swift-tools-version: 6.0
// DesignSystem — MM2 토큰, 컴포넌트, SVG/이미지 리소스.
// SwiftUI만 의존. Domain import 금지.

import PackageDescription

let package = Package(
    name: "DesignSystem",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"])
    ],
    targets: [
        .target(
            name: "DesignSystem",
            // Phase 3에서 Asset Catalog(Pretendard 폰트, MM2 컬러, MatchaPin SVG) 적재 후
            // resources: [.process("Resources")] 활성화. 현재 빈 디렉토리라 SwiftPM 경고 발생 → 비활성.
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"]
        )
    ]
)
