// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EduGoSecurityKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoSecurityKit",
            targets: ["EduGoSecurityKit"]
        )
    ],
    dependencies: [
        .package(path: "../EduGoFoundation"),
        .package(path: "../EduGoDomainCore"),
        .package(path: "../EduGoObservability"),
        .package(path: "../EduGoSecureStorage"),
        .package(path: "../EduGoDataLayer")
    ],
    targets: [
        .target(
            name: "EduGoSecurityKit",
            dependencies: [
                "EduGoFoundation",
                "EduGoDomainCore",
                "EduGoObservability",
                "EduGoSecureStorage",
                "EduGoDataLayer"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EduGoSecurityKitTests",
            dependencies: ["EduGoSecurityKit"]
        )
    ]
)
