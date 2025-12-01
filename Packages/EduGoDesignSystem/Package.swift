// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EduGoDesignSystem",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoDesignSystem",
            targets: ["EduGoDesignSystem"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "EduGoDesignSystem",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EduGoDesignSystemTests",
            dependencies: ["EduGoDesignSystem"]
        )
    ]
)
