//
//  LogCategory.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Core/Logging/
//  SPEC-002: Professional Logging System
//

import Foundation

/// Categorías de logging para organizar y filtrar logs
///
/// Cada categoría representa un subsistema de la aplicación, permitiendo
/// filtrar logs en Console.app por categoría específica.
///
/// ## Uso en Console.app
/// ```
/// category:network  # Solo logs de networking
/// category:auth     # Solo logs de autenticación
/// ```
public enum LogCategory: String, Sendable {
    /// Logs de networking (HTTP requests, responses, errors)
    ///
    /// Ejemplos:
    /// - "Request started: GET /api/users"
    /// - "Response received: 200 OK"
    /// - "Network error: timeout"
    case network

    /// Logs de autenticación y autorización
    ///
    /// Ejemplos:
    /// - "Login attempt started"
    /// - "Token refreshed successfully"
    /// - "Biometric authentication failed"
    case auth

    /// Logs de persistencia (Keychain, UserDefaults, Database)
    ///
    /// Ejemplos:
    /// - "Token saved to Keychain"
    /// - "Preferences updated"
    /// - "Database migration completed"
    case data

    /// Logs de UI y user interactions
    ///
    /// Ejemplos:
    /// - "LoginView appeared"
    /// - "Button tapped: Login"
    /// - "Navigation: Home → Settings"
    case ui

    /// Logs de business logic (Use Cases)
    ///
    /// Ejemplos:
    /// - "LoginUseCase: Validating input"
    /// - "GetUserUseCase: Fetching user data"
    /// - "UpdateThemeUseCase: Theme changed"
    case business

    /// Logs del sistema (App lifecycle, memory, crashes)
    ///
    /// Ejemplos:
    /// - "App launched"
    /// - "Memory warning received"
    /// - "App entering background"
    case system

    /// Logs de analytics y telemetry
    ///
    /// Ejemplos:
    /// - "Event tracked: user_logged_in"
    /// - "Analytics provider initialized"
    /// - "User property set: theme"
    case analytics

    /// Logs de performance monitoring
    ///
    /// Ejemplos:
    /// - "Trace started: api_call"
    /// - "Memory usage: 150MB"
    /// - "Launch time: 1.2s"
    case performance
}
