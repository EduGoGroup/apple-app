//
//  PlatformCapabilities.swift
//  apple-app
//
//  Created on 27-11-25.
//  SPEC-006: Platform Optimization
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Platform Detection

/// Sistema de detección de capacidades y características de la plataforma
///
/// Proporciona información sobre:
/// - Tipo de dispositivo (iPhone, iPad, Mac, Vision)
/// - Capacidades de UI (Size Classes, orientación)
/// - Versiones de OS y APIs disponibles
///
/// - Important: Implementado como struct Sendable (sin estado mutable)
///   siguiendo REGLA 2.2 de 03-REGLAS-DESARROLLO-IA.md
struct PlatformCapabilities: Sendable {

    // MARK: - Device Type Detection

    /// Tipo de dispositivo actual
    enum DeviceType: Sendable {
        case iPhone
        case iPad
        case mac
        case vision
        case unknown
    }

    /// Detecta el tipo de dispositivo actual
    @MainActor
    static var currentDevice: DeviceType {
        #if os(iOS)
        #if targetEnvironment(simulator)
        // En simulador, detectar por userInterfaceIdiom
        return UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
        #else
        // En dispositivo real
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .iPhone
        case .pad:
            return .iPad
        case .vision:
            return .vision
        default:
            return .unknown
        }
        #endif
        #elseif os(macOS)
        return .mac
        #elseif os(visionOS)
        return .vision
        #else
        return .unknown
        #endif
    }

    // MARK: - Size Class Detection

    /// Contexto de Size Class actual
    struct SizeClassContext: Sendable {
        let horizontal: UserInterfaceSizeClass?
        let vertical: UserInterfaceSizeClass?

        /// Indica si el contexto es compacto (típicamente iPhone en portrait)
        var isCompact: Bool {
            horizontal == .compact && vertical == .regular
        }

        /// Indica si el contexto es regular (típicamente iPad o iPhone landscape)
        var isRegular: Bool {
            horizontal == .regular
        }

        /// Indica si es contexto tipo iPad (regular en ambas direcciones)
        var isTablet: Bool {
            horizontal == .regular && vertical == .regular
        }
    }

    // MARK: - Screen Capabilities

    /// Información sobre las capacidades de la pantalla
    struct ScreenCapabilities: Sendable {
        let screenSize: CGSize
        let scale: CGFloat
        let isLargeScreen: Bool

        /// Determina si debe usar layout de múltiples columnas
        var supportsMultiColumn: Bool {
            isLargeScreen
        }

        /// Determina si debe mostrar sidebar permanente
        var supportsPermanentSidebar: Bool {
            isLargeScreen
        }
    }

    #if os(iOS)
    /// Obtiene las capacidades de la pantalla actual
    @MainActor
    static var screenCapabilities: ScreenCapabilities {
        let screen = UIScreen.main
        let size = screen.bounds.size
        let scale = screen.scale

        // iPad Pro 12.9" o mayor
        let isLargeScreen = size.width >= 1024 || size.height >= 1024

        return ScreenCapabilities(
            screenSize: size,
            scale: scale,
            isLargeScreen: isLargeScreen
        )
    }
    #elseif os(macOS)
    /// Obtiene las capacidades de la pantalla actual
    static var screenCapabilities: ScreenCapabilities {
        guard let screen = NSScreen.main else {
            return ScreenCapabilities(
                screenSize: CGSize(width: 1920, height: 1080),
                scale: 2.0,
                isLargeScreen: true
            )
        }

        let size = screen.frame.size
        let scale = screen.backingScaleFactor

        return ScreenCapabilities(
            screenSize: size,
            scale: scale,
            isLargeScreen: true // macOS siempre es "large screen"
        )
    }
    #else
    /// Obtiene las capacidades de la pantalla actual
    static var screenCapabilities: ScreenCapabilities {
        ScreenCapabilities(
            screenSize: CGSize(width: 1920, height: 1080),
            scale: 2.0,
            isLargeScreen: true
        )
    }
    #endif

    // MARK: - OS Version Detection

    /// Capacidades según versión del OS
    struct OSCapabilities: Sendable {
        let supportsModernEffects: Bool      // iOS 18+, macOS 15+
        let supportsLiquidGlass: Bool        // iOS 26+, macOS 26+ (futuro)
        let supportsAdvancedConcurrency: Bool // Swift 6

        static var current: OSCapabilities {
            if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
                return OSCapabilities(
                    supportsModernEffects: true,
                    supportsLiquidGlass: false, // TODO: Cambiar cuando iOS 26 esté disponible
                    supportsAdvancedConcurrency: true
                )
            } else {
                return OSCapabilities(
                    supportsModernEffects: false,
                    supportsLiquidGlass: false,
                    supportsAdvancedConcurrency: false
                )
            }
        }
    }

    // MARK: - Input Capabilities

    /// Capacidades de entrada del dispositivo
    struct InputCapabilities: Sendable {
        let hasKeyboard: Bool
        let hasTrackpad: Bool
        let supportsPencil: Bool
        let supportsHover: Bool

        static var current: InputCapabilities {
            #if os(macOS)
            return InputCapabilities(
                hasKeyboard: true,
                hasTrackpad: true,
                supportsPencil: false,
                supportsHover: true
            )
            #elseif os(iOS)
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            return InputCapabilities(
                hasKeyboard: false, // Puede tener teclado externo, pero no asumimos
                hasTrackpad: false,
                supportsPencil: isPad,
                supportsHover: isPad
            )
            #elseif os(visionOS)
            return InputCapabilities(
                hasKeyboard: false,
                hasTrackpad: false,
                supportsPencil: false,
                supportsHover: true
            )
            #else
            return InputCapabilities(
                hasKeyboard: false,
                hasTrackpad: false,
                supportsPencil: false,
                supportsHover: false
            )
            #endif
        }
    }

    // MARK: - Navigation Style

    /// Estilo de navegación recomendado según el dispositivo
    enum NavigationStyle: Sendable {
        case tabs          // iPhone
        case sidebar       // iPad, Mac
        case spatial       // visionOS
    }

    /// Estilo de navegación recomendado para el dispositivo actual
    @MainActor
    static var recommendedNavigationStyle: NavigationStyle {
        switch currentDevice {
        case .iPhone:
            return .tabs
        case .iPad, .mac:
            return .sidebar
        case .vision:
            return .spatial
        case .unknown:
            return .tabs
        }
    }

    // MARK: - Convenience Properties

    /// Indica si estamos en iPhone
    @MainActor
    static var isIPhone: Bool {
        currentDevice == .iPhone
    }

    /// Indica si estamos en iPad
    @MainActor
    static var isIPad: Bool {
        currentDevice == .iPad
    }

    /// Indica si estamos en Mac
    @MainActor
    static var isMac: Bool {
        currentDevice == .mac
    }

    /// Indica si estamos en Vision Pro
    @MainActor
    static var isVision: Bool {
        currentDevice == .vision
    }

    /// Indica si el dispositivo soporta múltiples ventanas
    @MainActor
    static var supportsMultipleWindows: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #elseif os(macOS)
        return true
        #elseif os(visionOS)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - SwiftUI Environment Extension

/// Extension para acceder a Size Classes desde SwiftUI
extension View {
    /// Ejecuta código adaptado según el Size Class context
    func adaptiveLayout<Content: View>(
        @ViewBuilder compact: @escaping () -> Content,
        @ViewBuilder regular: @escaping () -> Content
    ) -> some View {
        GeometryReader { geometry in
            Group {
                if geometry.size.width < 768 {
                    compact()
                } else {
                    regular()
                }
            }
        }
    }
}

// MARK: - Debug Description

extension PlatformCapabilities {
    /// Información de debug sobre la plataforma actual
    @MainActor
    static var debugDescription: String {
        """
        Platform Capabilities:
        - Device: \(currentDevice)
        - Navigation: \(recommendedNavigationStyle)
        - Screen: \(screenCapabilities.screenSize)
        - Scale: \(screenCapabilities.scale)
        - Large Screen: \(screenCapabilities.isLargeScreen)
        - Modern Effects: \(OSCapabilities.current.supportsModernEffects)
        - Multiple Windows: \(supportsMultipleWindows)
        - Input: Keyboard=\(InputCapabilities.current.hasKeyboard), Pencil=\(InputCapabilities.current.supportsPencil)
        """
    }
}

// MARK: - Previews

#Preview("Platform Info") {
    VStack(alignment: .leading, spacing: DSSpacing.medium) {
        Text("Platform Capabilities")
            .font(DSTypography.title)

        Text(PlatformCapabilities.debugDescription)
            .font(.system(.body, design: .monospaced))
            .padding()
            .background(DSColors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.medium))
    }
    .padding()
}
