//
//  UserPreferences.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Representa las preferencias configurables del usuario
public struct UserPreferences: Codable, Equatable, Sendable {
    /// Tema de apariencia seleccionado
    public var theme: Theme

    /// Código de idioma (ej: "es", "en")
    public var language: String

    /// Indica si la autenticación biométrica está habilitada
    public var biometricsEnabled: Bool

    public init(theme: Theme, language: String, biometricsEnabled: Bool) {
        self.theme = theme
        self.language = language
        self.biometricsEnabled = biometricsEnabled
    }

    /// Configuración por defecto para nuevos usuarios
    public static let `default` = UserPreferences(
        theme: .system,
        language: "es",
        biometricsEnabled: false
    )

    // MARK: - SPEC-010: Language Helper

    /// Obtiene el idioma como enum Language
    public var languageEnum: Language {
        Language(rawValue: language) ?? .default
    }
}

// MARK: - Mock Data
public extension UserPreferences {
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
