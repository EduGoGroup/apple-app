// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EduGoDataLayer",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoDataLayer",
            targets: ["EduGoDataLayer"]
        )
    ],
    dependencies: [
        .package(path: "../EduGoFoundation"),
        .package(path: "../EduGoDomainCore"),
        .package(path: "../EduGoObservability"),
        .package(path: "../EduGoSecureStorage")
        // EduGoSecurityKit se agregará después para cerrar el ciclo
    ],
    targets: [
        .target(
            name: "EduGoDataLayer",
            dependencies: [
                "EduGoFoundation",
                "EduGoDomainCore",
                "EduGoObservability",
                "EduGoSecureStorage"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EduGoDataLayerTests",
            dependencies: ["EduGoDataLayer"]
        )
    ]
)
