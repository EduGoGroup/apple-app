//
//  AppSettings.swift
//  apple-app
//
//  Created on 25-11-25.
//  SPEC-005: SwiftData Integration - App Settings Model
//

import Foundation
import SwiftData

/// Configuración de la aplicación persistida localmente
///
/// Reemplaza UserDefaults para preferencias estructuradas.
/// Sincronizable entre dispositivos del mismo usuario.
@Model
final class AppSettings {
    // MARK: - Properties

    @Attribute(.unique) var id: String
    var theme: String
    var language: String
    var biometricsEnabled: Bool
    var notificationsEnabled: Bool
    var lastSyncDate: Date?
    var userId: String?

    // MARK: - Initialization

    init() {
        self.id = "app_settings"
        self.theme = "system"
        self.language = "es"
        self.biometricsEnabled = false
        self.notificationsEnabled = true
    }

    // MARK: - Helpers

    var themeEnum: Theme {
        Theme(rawValue: theme) ?? .system
    }

    func updateTheme(_ theme: Theme) {
        self.theme = theme.rawValue
    }

    /// SPEC-010: Helper para obtener Language enum desde String
    var languageEnum: Language {
        Language(rawValue: language) ?? .default
    }

    /// SPEC-010: Actualiza el idioma de la aplicación
    func updateLanguage(_ language: Language) {
        self.language = language.rawValue
    }
}
