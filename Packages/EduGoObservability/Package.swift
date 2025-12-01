// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EduGoObservability",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoObservability",
            targets: ["EduGoObservability"]
        )
    ],
    dependencies: [
        .package(path: "../EduGoFoundation"),
        .package(path: "../EduGoDomainCore")
    ],
    targets: [
        .target(
            name: "EduGoObservability",
            dependencies: [
                "EduGoFoundation",
                "EduGoDomainCore"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EduGoObservabilityTests",
            dependencies: ["EduGoObservability"]
        )
    ]
)
