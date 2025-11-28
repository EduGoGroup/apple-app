//
//  Language.swift
//  apple-app
//
//  Created on 25-11-25.
//  Updated on 28-11-25: Removidas propiedades UI para cumplir Clean Architecture
//  SPEC-010: Localization - Language Enum
//

import Foundation

/// Idiomas soportados en la aplicación
///
/// Esta entidad de Domain contiene solo lógica de negocio (códigos ISO, detección).
/// Para propiedades de presentación (displayName, iconName, flagEmoji),
/// ver la extensión en `Presentation/Extensions/Language+UI.swift`.
///
/// - Note: Cumple Clean Architecture - Domain Layer puro
/// - Note: Conforme a iOS 15+ String Catalog (xcstrings)
enum Language: String, Codable, CaseIterable, Sendable {
    /// Español
    case spanish = "es"

    /// Inglés
    case english = "en"

    // MARK: - Business Logic Properties

    /// Código de idioma ISO 639-1
    var code: String {
        rawValue
    }

    /// Idioma predeterminado de la aplicación
    static var `default`: Language {
        .spanish
    }

    /// Detecta el idioma del sistema y retorna el más cercano soportado
    ///
    /// Utiliza `Locale.preferredLanguages` del sistema para detectar
    /// el idioma preferido del usuario y mapear al idioma soportado
    /// más cercano.
    ///
    /// - Returns: Language soportado más cercano al idioma del sistema
    static func systemLanguage() -> Language {
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

    /// Indica si es el idioma predeterminado
    var isDefault: Bool {
        self == .default
    }
}
