//
//  Language+UI.swift
//  EduGoFeatures
//
//  Created on 28-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//  Extension de Language para propiedades de presentación
//

import SwiftUI
import EduGoDomainCore

/// Extensión de Language con propiedades específicas de UI
///
/// Separación de responsabilidades:
/// - **Domain/Entities/Language.swift**: Lógica de negocio (ISO codes, detección)
/// - **Features/Extensions/Language+UI.swift**: Propiedades de UI (displayName, emoji, icon)
extension Language {

    // MARK: - Display Properties

    /// Nombre del idioma en su propio idioma (autoglotónimo)
    public var displayName: String {
        switch self {
        case .spanish:
            return "Español"
        case .english:
            return "English"
        }
    }

    /// Ícono SF Symbol representativo del idioma
    public var iconName: String {
        switch self {
        case .spanish:
            return "flag.fill"
        case .english:
            return "flag.fill"
        }
    }

    /// Emoji de bandera representativa
    public var flagEmoji: String {
        switch self {
        case .spanish:
            return "🇪🇸"
        case .english:
            return "🇺🇸"
        }
    }

    // MARK: - Additional UI Properties

    /// Color de acento para el idioma
    public var accentColor: Color {
        switch self {
        case .spanish:
            return .red
        case .english:
            return .blue
        }
    }

    /// Label de accesibilidad
    public var accessibilityLabel: String {
        switch self {
        case .spanish:
            return "Idioma: Español"
        case .english:
            return "Language: English"
        }
    }
}
