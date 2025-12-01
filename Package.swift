// swift-tools-version: 6.0
// El swift-tools-version declara la versión mínima de Swift requerida para compilar este package.

import PackageDescription

/// EduGoWorkspace - Workspace SPM para modularización del proyecto EduGo Apple App
///
/// Este Package.swift define el workspace raíz que contendrá todos los módulos SPM.
/// Los módulos se agregarán progresivamente durante los sprints de modularización.
///
/// Módulos planificados:
/// - Sprint 1: EduGoFoundation, EduGoDesignSystem, EduGoDomainCore
/// - Sprint 2: EduGoObservability, EduGoSecureStorage
/// - Sprint 3: EduGoDataLayer, EduGoSecurityKit
/// - Sprint 4: EduGoFeatures
///
/// Plataformas soportadas:
/// - iOS 18.0+
/// - macOS 15.0+
/// - visionOS 2.0+

let package = Package(
    name: "EduGoWorkspace",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        // Los productos se agregarán en sprints posteriores
        // Ejemplo:
        // .library(name: "EduGoFoundation", targets: ["EduGoFoundation"]),
    ],
    dependencies: [
        // Las dependencias externas se agregarán si son necesarias
    ],
    targets: [
        // Los targets se agregarán en sprints posteriores
        // Ejemplo:
        // .target(
        //     name: "EduGoFoundation",
        //     dependencies: [],
        //     path: "Packages/EduGoFoundation/Sources"
        // ),
    ]
)
