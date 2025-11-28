//
//  Language+UI.swift
//  apple-app
//
//  Created on 28-11-25.
//  Extension de Language para propiedades de presentación
//

import SwiftUI

/// Extensión de Language con propiedades específicas de UI
///
/// Separación de responsabilidades:
/// - **Domain/Entities/Language.swift**: Lógica de negocio (ISO codes, detección)
/// - **Presentation/Extensions/Language+UI.swift**: Propiedades de UI (displayName, emoji, icon)
extension Language {

    // MARK: - Display Properties

    /// Nombre del idioma en su propio idioma (autoglotónimo)
    var displayName: String {
        switch self {
        case .spanish:
            return "Español"
        case .english:
            return "English"
        }
    }

    /// Ícono SF Symbol representativo del idioma
    var iconName: String {
        switch self {
        case .spanish:
            return "flag.fill"
        case .english:
            return "flag.fill"
        }
    }

    /// Emoji de bandera representativa
    var flagEmoji: String {
        switch self {
        case .spanish:
            return "🇪🇸"
        case .english:
            return "🇺🇸"
        }
    }

    // MARK: - Additional UI Properties

    /// Color de acento para el idioma
    var accentColor: Color {
        switch self {
        case .spanish:
            return .red
        case .english:
            return .blue
        }
    }

    /// Label de accesibilidad
    var accessibilityLabel: String {
        switch self {
        case .spanish:
            return "Idioma: Español"
        case .english:
            return "Language: English"
        }
    }
}
