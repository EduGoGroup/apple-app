//
//  AppSettings.swift
//  EduGoDataLayer
//
//  Created on 25-11-25.
//  SPEC-005: SwiftData Integration - App Settings Model
//

import Foundation
import SwiftData
import EduGoDomainCore

/// Configuración de la aplicación persistida localmente
///
/// Reemplaza UserDefaults para preferencias estructuradas.
/// Sincronizable entre dispositivos del mismo usuario.
@Model
public final class AppSettings {
    // MARK: - Properties

    @Attribute(.unique) public var id: String
    public var theme: String
    public var language: String
    public var biometricsEnabled: Bool
    public var notificationsEnabled: Bool
    public var lastSyncDate: Date?
    public var userId: String?

    // MARK: - Initialization

    public init() {
        self.id = "app_settings"
        self.theme = "system"
        self.language = "es"
        self.biometricsEnabled = false
        self.notificationsEnabled = true
    }

    // MARK: - Helpers

    public var themeEnum: Theme {
        Theme(rawValue: theme) ?? .system
    }

    public func updateTheme(_ theme: Theme) {
        self.theme = theme.rawValue
    }

    /// SPEC-010: Helper para obtener Language enum desde String
    public var languageEnum: Language {
        Language(rawValue: language) ?? .default
    }

    /// SPEC-010: Actualiza el idioma de la aplicación
    public func updateLanguage(_ language: Language) {
        self.language = language.rawValue
    }
}
