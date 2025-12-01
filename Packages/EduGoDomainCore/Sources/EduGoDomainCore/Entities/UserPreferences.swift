//
//  UserPreferences.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Representa las preferencias configurables del usuario
struct UserPreferences: Codable, Equatable, Sendable {
    /// Tema de apariencia seleccionado
    var theme: Theme

    /// Código de idioma (ej: "es", "en")
    var language: String

    /// Indica si la autenticación biométrica está habilitada
    var biometricsEnabled: Bool

    /// Configuración por defecto para nuevos usuarios
    static let `default` = UserPreferences(
        theme: .system,
        language: "es",
        biometricsEnabled: false
    )

    // MARK: - SPEC-010: Language Helper

    /// Obtiene el idioma como enum Language
    var languageEnum: Language {
        Language(rawValue: language) ?? .default
    }
}

// MARK: - Mock Data
extension UserPreferences {
    /// Preferencias de ejemplo con biometría activada
    static let mockWithBiometrics = UserPreferences(
        theme: .dark,
        language: "en",
        biometricsEnabled: true
    )

    /// Preferencias de ejemplo con tema claro
    static let mockLight = UserPreferences(
        theme: .light,
        language: "es",
        biometricsEnabled: false
    )
}
