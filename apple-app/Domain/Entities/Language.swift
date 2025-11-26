//
//  Language.swift
//  apple-app
//
//  Created on 25-11-25.
//  SPEC-010: Localization - Language Enum
//

import Foundation

/// Idiomas soportados en la aplicación
///
/// Define los idiomas disponibles para la localización de contenido.
/// Cada idioma tiene un código ISO 639-1 y un nombre para mostrar en UI.
///
/// - Note: Conforme a iOS 15+ String Catalog (xcstrings)
enum Language: String, Codable, CaseIterable, Sendable {
    /// Español
    case spanish = "es"

    /// Inglés
    case english = "en"

    /// Código de idioma ISO 639-1
    nonisolated var code: String {
        rawValue
    }

    /// Nombre del idioma en su propio idioma (autoglotónimo)
    nonisolated var displayName: String {
        switch self {
        case .spanish:
            return "Español"
        case .english:
            return "English"
        }
    }

    /// Icono SF Symbol representativo del idioma
    nonisolated var iconName: String {
        switch self {
        case .spanish:
            return "flag.fill" // Bandera genérica
        case .english:
            return "flag.fill"
        }
    }

    /// Emoji de bandera representativa (opcional, para UI)
    nonisolated var flagEmoji: String {
        switch self {
        case .spanish:
            return "🇪🇸"
        case .english:
            return "🇺🇸"
        }
    }

    /// Idioma predeterminado de la aplicación
    nonisolated static var `default`: Language {
        .spanish
    }

    /// Detecta el idioma del sistema y retorna el más cercano soportado
    /// - Returns: Language soportado más cercano al idioma del sistema
    nonisolated static func systemLanguage() -> Language {
        let preferredLanguages = Locale.preferredLanguages

        for preferredLanguage in preferredLanguages {
            let languageCode = String(preferredLanguage.prefix(2))

            if let language = Language(rawValue: languageCode) {
                return language
            }
        }

        // Fallback al idioma predeterminado
        return .default
    }
}
