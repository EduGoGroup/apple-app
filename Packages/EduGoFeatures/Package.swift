// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EduGoFeatures",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoFeatures",
            targets: ["EduGoFeatures"]
        )
    ],
    dependencies: [
        .package(path: "../EduGoFoundation"),
        .package(path: "../EduGoDesignSystem"),
        .package(path: "../EduGoDomainCore"),
        .package(path: "../EduGoObservability"),
        .package(path: "../EduGoSecureStorage"),
        .package(path: "../EduGoDataLayer"),
        .package(path: "../EduGoSecurityKit")
    ],
    targets: [
        .target(
            name: "EduGoFeatures",
            dependencies: [
                .product(name: "EduGoFoundation", package: "EduGoFoundation"),
                .product(name: "EduGoDesignSystem", package: "EduGoDesignSystem"),
                .product(name: "EduGoDomainCore", package: "EduGoDomainCore"),
                .product(name: "EduGoObservability", package: "EduGoObservability"),
                .product(name: "EduGoSecureStorage", package: "EduGoSecureStorage"),
                .product(name: "EduGoDataLayer", package: "EduGoDataLayer"),
                .product(name: "EduGoSecurityKit", package: "EduGoSecurityKit")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EduGoFeaturesTests",
            dependencies: ["EduGoFeatures"]
        )
    ]
)
