//
//  DSColors.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Paleta de colores del Design System
/// Soporta Light y Dark mode automáticamente
/// Incluye Glass-enhanced colors y estados interactivos
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
enum DSColors {
    // MARK: - Background Colors

    /// Color de fondo principal
    static let backgroundPrimary: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemBackground)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }()

    /// Color de fondo secundario
    static let backgroundSecondary: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemBackground)
        #else
        return Color(nsColor: .controlColor)
        #endif
    }()

    /// Color de fondo terciario
    static let backgroundTertiary: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .tertiarySystemBackground)
        #else
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }()

    // MARK: - Text Colors

    /// Color de texto principal
    static let textPrimary = Color.primary

    /// Color de texto secundario
    static let textSecondary = Color.secondary

    /// Color de texto terciario (placeholder)
    static let textTertiary: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .tertiaryLabel)
        #else
        return Color(nsColor: .tertiaryLabelColor)
        #endif
    }()

    // MARK: - Brand Colors

    /// Color de acento principal (usado para botones primarios, links, etc.)
    static let accent = Color.accentColor

    /// Color de acento secundario
    static let accentSecondary = Color.blue.opacity(0.7)

    // MARK: - Semantic Colors

    /// Color para indicar éxito
    static let success = Color.green

    /// Color para indicar error
    static let error = Color.red

    /// Color para indicar advertencia
    static let warning = Color.orange

    /// Color para información
    static let info = Color.blue

    // MARK: - Borders & Separators

    /// Color de separadores
    static let separator: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .separator)
        #else
        return Color(nsColor: .separatorColor)
        #endif
    }()

    /// Color de borde
    static let border: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .separator)
        #else
        return Color(nsColor: .separatorColor)
        #endif
    }()

    // MARK: - Overlay

    /// Color de overlay oscuro (para modals, alerts, etc.)
    static let overlay = Color.black.opacity(0.4)

    // MARK: - Glass-Enhanced Colors

    /// Color base para efectos Glass subtle
    static let glassSubtle = Color.white.opacity(0.05)

    /// Color base para efectos Glass standard
    static let glassStandard = Color.white.opacity(0.1)

    /// Color base para efectos Glass prominent
    static let glassProminent = Color.white.opacity(0.15)

    /// Color base para efectos Glass immersive
    static let glassImmersive = Color.white.opacity(0.2)

    /// Color base para efectos Glass desktop (macOS específico)
    static let glassDesktop = Color.white.opacity(0.12)

    // MARK: - Glass Interactive States

    /// Estado normal del acento principal
    static let primaryNormal = accent

    /// Estado pressed del acento principal
    static let primaryPressed = accent.opacity(0.8)

    /// Estado focused del acento principal
    static let primaryFocused = accent.opacity(0.9)

    /// Estado hovered del acento principal
    static let primaryHovered = accent.opacity(0.95)

    /// Estado disabled del acento principal
    static let primaryDisabled = accent.opacity(0.5)

    // MARK: - Surface Glass Variants

    /// Superficie con efecto Glass para cards
    static let surfaceGlass = Color.white.opacity(0.08)

    /// Superficie con efecto Glass subtle para backgrounds
    static let surfaceGlassSubtle = Color.white.opacity(0.04)

    /// Superficie con efecto Glass prominent para modales
    static let surfaceGlassProminent = Color.white.opacity(0.12)

    /// Superficie con efecto Glass para overlays
    static let surfaceGlassOverlay = Color.black.opacity(0.3)

    // MARK: - Glass-Specific Roles

    /// Color de highlight para Glass effects
    static let glassHighlight = Color.white.opacity(0.25)

    /// Color de shadow para Glass effects
    static let glassShadow = Color.black.opacity(0.15)

    /// Color de overlay para Glass backgrounds
    static let glassOverlay = Color.white.opacity(0.06)

    /// Color de refraction para Glass effects
    static let glassRefraction = Color.white.opacity(0.18)

    // MARK: - Status Containers with Glass

    /// Background para success con Glass
    static let successGlassBackground = Color.green.opacity(0.12)

    /// Foreground para success con Glass
    static let successGlassForeground = Color.green

    /// Background para error con Glass
    static let errorGlassBackground = Color.red.opacity(0.12)

    /// Foreground para error con Glass
    static let errorGlassForeground = Color.red

    /// Background para warning con Glass
    static let warningGlassBackground = Color.orange.opacity(0.12)

    /// Foreground para warning con Glass
    static let warningGlassForeground = Color.orange

    /// Background para info con Glass
    static let infoGlassBackground = Color.blue.opacity(0.12)

    /// Foreground para info con Glass
    static let infoGlassForeground = Color.blue

    // MARK: - Dark Mode Specific

    /// Color de Glass para modo oscuro (inverso)
    static let glassDark = Color.black.opacity(0.3)

    /// Color de highlight para modo oscuro
    static let glassHighlightDark = Color.white.opacity(0.15)
}
