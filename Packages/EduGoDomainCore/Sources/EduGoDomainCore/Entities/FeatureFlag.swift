//
//  FeatureFlag.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-009: Feature Flags System
//
//  Feature flags del sistema (lógica de negocio pura)
//  Las propiedades de UI están en Presentation/Extensions/FeatureFlag+UI.swift
//
//  IMPORTANTE: Este archivo NO debe importar SwiftUI ni SwiftData
//

import Foundation

/// Feature flags disponibles en la aplicación
///
/// Define los feature flags que pueden habilitarse o deshabilitarse
/// de forma dinámica. Las propiedades aquí son SOLO de negocio.
///
/// ## Clean Architecture
/// Este enum es 100% puro:
/// - NO tiene `displayName` (está en Presentation)
/// - NO tiene `iconName` (está en Presentation)
/// - NO tiene `description` (está en Presentation)
/// - NO tiene `category` UI (está en Presentation)
///
/// ## Propiedades de Negocio
/// - `defaultValue`: Valor por defecto del flag
/// - `requiresRestart`: Si requiere reiniciar la app
/// - `minimumBuildNumber`: Build mínimo requerido
/// - `isExperimental`: Si es una feature experimental
///
/// - Note: Para propiedades de UI, ver `FeatureFlag+UI.swift`
/// - Note: Cumple Clean Architecture - Domain Layer puro
public enum FeatureFlag: String, CaseIterable, Codable, Sendable {
    // MARK: - Security Flags

    /// Habilita login con Face ID/Touch ID
    case biometricLogin = "biometric_login"

    /// Habilita certificate pinning
    case certificatePinning = "certificate_pinning"

    /// Habilita rate limiting de login
    case loginRateLimiting = "login_rate_limiting"

    // MARK: - Feature Flags

    /// Habilita modo offline
    case offlineMode = "offline_mode"

    /// Habilita sync en background
    case backgroundSync = "background_sync"

    /// Habilita notificaciones push
    case pushNotifications = "push_notifications"

    // MARK: - UI Flags

    /// Habilita tema oscuro automático
    case autoDarkMode = "auto_dark_mode"

    /// Habilita nuevo dashboard (experimental)
    case newDashboard = "new_dashboard"

    /// Habilita animaciones de transición
    case transitionAnimations = "transition_animations"

    // MARK: - Debug Flags

    /// Habilita logs de debug en producción
    case debugLogs = "debug_logs"

    /// Habilita mock de API (solo dev)
    case mockAPI = "mock_api"

    // MARK: - Business Logic Properties

    /// Valor por defecto del flag
    ///
    /// Este es el valor usado cuando:
    /// - No hay valor en cache
    /// - No hay valor remoto
    /// - El flag no se ha sincronizado
    public nonisolated var defaultValue: Bool {
        switch self {
        // Security: habilitados por defecto
        case .biometricLogin: return true
        case .certificatePinning: return true
        case .loginRateLimiting: return true

        // Features: depende del estado de desarrollo
        case .offlineMode: return true
        case .backgroundSync: return false
        case .pushNotifications: return false

        // UI: seguros por defecto
        case .autoDarkMode: return true
        case .newDashboard: return false
        case .transitionAnimations: return true

        // Debug: deshabilitados en producción
        case .debugLogs: return false
        case .mockAPI: return false
        }
    }

    /// Indica si el flag requiere reiniciar la app para aplicar cambios
    public nonisolated var requiresRestart: Bool {
        switch self {
        case .certificatePinning: return true
        case .debugLogs: return true
        case .mockAPI: return true
        default: return false
        }
    }

    /// Build number mínimo para que el flag esté disponible
    ///
    /// Si el build actual es menor, el flag se considera deshabilitado
    /// independientemente de su valor.
    public nonisolated var minimumBuildNumber: Int? {
        switch self {
        case .newDashboard: return 100  // Solo disponible desde build 100
        default: return nil
        }
    }

    /// Indica si es una feature experimental
    ///
    /// Features experimentales:
    /// - Pueden ser inestables
    /// - Pueden eliminarse sin previo aviso
    /// - Solo deberían habilitarse para testers
    public nonisolated var isExperimental: Bool {
        switch self {
        case .newDashboard: return true
        case .mockAPI: return true
        default: return false
        }
    }

    /// Indica si el flag solo está disponible en builds de debug
    public nonisolated var isDebugOnly: Bool {
        switch self {
        case .debugLogs: return true
        case .mockAPI: return true
        default: return false
        }
    }

    /// Indica si el flag afecta la seguridad
    public nonisolated var affectsSecurity: Bool {
        switch self {
        case .biometricLogin,
             .certificatePinning,
             .loginRateLimiting:
            return true
        default:
            return false
        }
    }

    /// Prioridad del flag (para ordenamiento en UI/backend)
    ///
    /// Mayor prioridad = más importante
    /// - Security flags: 90-100
    /// - Feature flags: 40-60
    /// - UI flags: 10-30
    /// - Debug flags: 1-9
    public nonisolated var priority: Int {
        switch self {
        case .biometricLogin: return 100
        case .certificatePinning: return 99
        case .loginRateLimiting: return 98
        case .offlineMode: return 50
        case .backgroundSync: return 49
        case .pushNotifications: return 48
        case .autoDarkMode: return 30
        case .transitionAnimations: return 20
        case .newDashboard: return 10
        case .debugLogs: return 5
        case .mockAPI: return 1
        }
    }
}
