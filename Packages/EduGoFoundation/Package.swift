// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EduGoFoundation",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoFoundation",
            targets: ["EduGoFoundation"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "EduGoFoundation",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EduGoFoundationTests",
            dependencies: ["EduGoFoundation"]
        )
    ]
)
