// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EduGoDomainCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoDomainCore",
            targets: ["EduGoDomainCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "EduGoDomainCore",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EduGoDomainCoreTests",
            dependencies: ["EduGoDomainCore"]
        )
    ]
)
