//
//  AnalyticsEvent.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-011: Analytics & Telemetry
//

import Foundation

/// Eventos de analytics trackeados en la aplicación
///
/// ## Concurrency
/// - **Sendable:** Enum sin estado mutable ✅
/// - **Thread-safe:** Value type, sin referencias compartidas
///
/// ## Categorías
/// - Authentication: Eventos de login/logout
/// - Navigation: Navegación entre pantallas
/// - Feature: Uso de features
/// - Error: Errores y excepciones
///
/// ## Privacy
/// - Usar `containsSensitiveData` para identificar eventos con PII
/// - Eventos sensibles requieren consentimiento explícito
enum AnalyticsEvent: String, Sendable, CaseIterable {
    // MARK: - Authentication Events

    /// Usuario inició sesión exitosamente
    case userLoggedIn = "user_logged_in"

    /// Usuario cerró sesión
    case userLoggedOut = "user_logged_out"

    /// Intento de login falló
    case loginFailed = "login_failed"

    /// Login con biometría (Face ID / Touch ID)
    case biometricLoginAttempted = "biometric_login_attempted"

    /// Login con biometría exitoso
    case biometricLoginSucceeded = "biometric_login_succeeded"

    // MARK: - Navigation Events

    /// Usuario vio una pantalla
    case screenViewed = "screen_viewed"

    /// Usuario tocó un botón
    case buttonTapped = "button_tapped"

    /// Usuario navegó hacia atrás
    case navigationBack = "navigation_back"

    /// Usuario abrió menú de settings
    case settingsOpened = "settings_opened"

    // MARK: - Feature Events

    /// Feature flag fue evaluado
    case featureFlagEvaluated = "feature_flag_evaluated"

    /// Usuario cambió tema (light/dark)
    case themeChanged = "theme_changed"

    /// Usuario cambió idioma
    case languageChanged = "language_changed"

    /// Notificaciones habilitadas
    case notificationsEnabled = "notifications_enabled"

    /// Notificaciones deshabilitadas
    case notificationsDisabled = "notifications_disabled"

    // MARK: - Error Events

    /// Error de red ocurrió
    case networkError = "network_error"

    /// Error de API ocurrió
    case apiError = "api_error"

    /// Error de validación
    case validationError = "validation_error"

    /// App crash (si se implementa crash reporting)
    case appCrashed = "app_crashed"

    // MARK: - Performance Events

    /// App lanzada
    case appLaunched = "app_launched"

    /// App pasó a background
    case appBackgrounded = "app_backgrounded"

    /// App volvió a foreground
    case appForegrounded = "app_foregrounded"

    /// Operación lenta detectada
    case slowOperation = "slow_operation"
}

// MARK: - Event Properties

extension AnalyticsEvent {
    /// Categoría del evento
    ///
    /// Permite agrupar eventos por tipo para análisis.
    var category: EventCategory {
        switch self {
        case .userLoggedIn, .userLoggedOut, .loginFailed,
             .biometricLoginAttempted, .biometricLoginSucceeded:
            return .authentication

        case .screenViewed, .buttonTapped, .navigationBack, .settingsOpened:
            return .navigation

        case .featureFlagEvaluated, .themeChanged, .languageChanged,
             .notificationsEnabled, .notificationsDisabled:
            return .feature

        case .networkError, .apiError, .validationError, .appCrashed:
            return .error

        case .appLaunched, .appBackgrounded, .appForegrounded, .slowOperation:
            return .performance
        }
    }

    /// Indica si el evento debe enviarse inmediatamente
    ///
    /// Eventos inmediatos se envían sin batching para análisis en tiempo real.
    var isImmediate: Bool {
        switch self {
        case .appCrashed, .networkError, .apiError:
            return true
        default:
            return false
        }
    }

    /// Indica si el evento contiene datos sensibles
    ///
    /// ## Privacy
    /// Eventos sensibles requieren consentimiento del usuario y pueden
    /// necesitar anonimización antes de enviarse.
    var containsSensitiveData: Bool {
        switch self {
        case .userLoggedIn, .userLoggedOut, .biometricLoginAttempted,
             .biometricLoginSucceeded:
            return true
        default:
            return false
        }
    }
}

// MARK: - Event Categories

extension AnalyticsEvent {
    /// Categorías de eventos para agrupación
    enum EventCategory: String, Sendable {
        case authentication
        case navigation
        case feature
        case error
        case performance
    }
}

// MARK: - Identifiable

extension AnalyticsEvent: Identifiable {
    var id: String { rawValue }
}
