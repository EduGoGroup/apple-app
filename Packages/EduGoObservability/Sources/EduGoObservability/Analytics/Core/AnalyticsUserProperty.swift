//
//  AnalyticsUserProperty.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Domain/Services/Analytics/
//  SPEC-011: Analytics & Telemetry
//

import Foundation

/// Propiedades de usuario para analytics
///
/// ## Responsabilidad
/// Define propiedades que se pueden asociar a un usuario y que
/// se envían con todos los eventos subsecuentes.
///
/// ## Concurrency
/// - **Sendable:** Enum sin estado mutable ✅
/// - **Thread-safe:** Value type, sin referencias compartidas
///
/// ## Privacy
/// - Propiedades que requieren consentimiento están marcadas con `requiresConsent`
/// - Cumplir con GDPR/CCPA al establecer propiedades sensibles
public enum AnalyticsUserProperty: String, Sendable, CaseIterable {
    // MARK: - User Identity

    /// ID del usuario en el sistema
    case userId = "user_id"

    /// Rol del usuario (student, teacher, admin)
    case userRole = "user_role"

    /// Email del usuario (hasheado)
    case userEmail = "user_email_hash"

    // MARK: - App Information

    /// Versión de la app instalada
    case appVersion = "app_version"

    /// Build number de la app
    case buildNumber = "build_number"

    /// Ambiente de la app (development, staging, production)
    case appEnvironment = "app_environment"

    // MARK: - Device Information

    /// Modelo del dispositivo (iPhone 15 Pro, iPad Air, Mac Studio)
    case deviceModel = "device_model"

    /// Versión del OS (iOS 18.0, macOS 15.0)
    case osVersion = "os_version"

    /// Plataforma (iOS, iPadOS, macOS, visionOS)
    case platform = "platform"

    /// Idioma preferido del usuario
    case preferredLanguage = "preferred_language"

    // MARK: - User Preferences

    /// Tema seleccionado (light, dark, system)
    case selectedTheme = "selected_theme"

    /// Notificaciones habilitadas
    case notificationsEnabled = "notifications_enabled"

    /// Autenticación biométrica habilitada
    case biometricsEnabled = "biometrics_enabled"
}

// MARK: - Privacy Properties

public extension AnalyticsUserProperty {
    /// Indica si la propiedad requiere consentimiento del usuario
    ///
    /// ## GDPR/CCPA Compliance
    /// Propiedades que requieren consentimiento no deben establecerse
    /// sin permiso explícito del usuario.
    var requiresConsent: Bool {
        switch self {
        case .userId, .userEmail:
            return true
        case .userRole, .appVersion, .buildNumber, .appEnvironment,
             .deviceModel, .osVersion, .platform, .preferredLanguage,
             .selectedTheme, .notificationsEnabled, .biometricsEnabled:
            return false
        }
    }
}

// MARK: - Identifiable

extension AnalyticsUserProperty: Identifiable {
    public var id: String { rawValue }
}
