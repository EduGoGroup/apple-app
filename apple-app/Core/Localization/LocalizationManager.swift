//
//  LocalizationManager.swift
//  apple-app
//
//  Created on 25-11-25.
//  SPEC-010: Localization - Localization Manager
//

import Foundation
import Observation

/// Gestor centralizado de localización de la aplicación
///
/// Maneja el idioma actual y proporciona métodos para cambiar el idioma
/// en tiempo de ejecución sin reiniciar la app.
///
/// Uso:
/// ```swift
/// @Environment(LocalizationManager.self) private var localization
///
/// Text(localization.localized("welcome.title"))
/// ```
///
/// - Note: Usa @Observable (iOS 17+) para reactividad automática
/// - Important: Marcado como @MainActor porque maneja estado de UI y se accede
///   principalmente desde vistas SwiftUI. Esto garantiza thread-safety en Swift 6.
@Observable
@MainActor
final class LocalizationManager {
    // MARK: - Properties

    /// Idioma actual de la aplicación
    private(set) var currentLanguage: Language

    // MARK: - Initialization

    /// Inicializa el gestor con un idioma específico
    /// - Parameter language: Idioma inicial (por defecto detecta del sistema)
    nonisolated init(language: Language? = nil) {
        let resolvedLanguage = language ?? Language.systemLanguage()
        self._currentLanguage = resolvedLanguage
    }

    // MARK: - Public Methods

    /// Cambia el idioma de la aplicación
    /// - Parameter language: Nuevo idioma a aplicar
    func setLanguage(_ language: Language) {
        currentLanguage = language
    }

    /// Obtiene una cadena localizada por su clave
    ///
    /// Este método está aquí para compatibilidad, pero se recomienda
    /// usar directamente `String(localized:)` en las vistas.
    ///
    /// - Parameter key: Clave de localización
    /// - Returns: String localizado
    func localized(_ key: String) -> String {
        // iOS 15+ usa String Catalog (.xcstrings)
        // String(localized:) automáticamente busca en Localizable.xcstrings
        String(localized: String.LocalizationValue(key))
    }

    /// Obtiene una cadena localizada con argumentos
    /// - Parameters:
    ///   - key: Clave de localización
    ///   - arguments: Argumentos para interpolar
    /// - Returns: String localizado con argumentos
    func localized(_ key: String, arguments: CVarArg...) -> String {
        let format = localized(key)
        return String(format: format, arguments: arguments)
    }
}

// MARK: - Environment Key

import SwiftUI

/// Extension para usar LocalizationManager en @Environment
extension EnvironmentValues {
    @Entry var localization = LocalizationManager()
}
