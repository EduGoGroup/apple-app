//
//  DSColors.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Paleta de colores del Design System
/// Soporta Light y Dark mode automáticamente
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
}
