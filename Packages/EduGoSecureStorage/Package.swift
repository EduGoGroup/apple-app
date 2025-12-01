// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EduGoSecureStorage",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoSecureStorage",
            targets: ["EduGoSecureStorage"]
        )
    ],
    dependencies: [
        .package(path: "../EduGoFoundation"),
        .package(path: "../EduGoDomainCore"),
        .package(path: "../EduGoObservability")
    ],
    targets: [
        .target(
            name: "EduGoSecureStorage",
            dependencies: [
                "EduGoFoundation",
                "EduGoDomainCore",
                "EduGoObservability"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EduGoSecureStorageTests",
            dependencies: ["EduGoSecureStorage"]
        )
    ]
)
