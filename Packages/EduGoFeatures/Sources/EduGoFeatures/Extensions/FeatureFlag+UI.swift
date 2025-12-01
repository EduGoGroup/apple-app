//
//  FeatureFlag+UI.swift
//  EduGoFeatures
//
//  Created on 28-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//  SPEC-009: Feature Flags System
//
//  Extensión de FeatureFlag con propiedades específicas de UI
//

import SwiftUI
import EduGoDomainCore

/// Extensión de FeatureFlag con propiedades de presentación
///
/// Esta extensión contiene todas las propiedades que dependen de SwiftUI
/// o que son específicas de presentación, manteniendo el enum `FeatureFlag`
/// en Domain Layer puro.
///
/// ## Separación de responsabilidades
/// - **Domain/Entities/FeatureFlag.swift**: Lógica de negocio
/// - **Features/Extensions/FeatureFlag+UI.swift**: Propiedades de UI
///
/// - Note: Cumple Clean Architecture - UI en Presentation Layer
extension FeatureFlag {
    // MARK: - Display Properties

    /// Nombre para mostrar en UI
    ///
    /// - Note: TODO SPEC-010: Migrar a String Catalog cuando se implemente localización
    public var displayName: String {
        switch self {
        // Security
        case .biometricLogin:
            return "Login Biométrico"
        case .certificatePinning:
            return "Certificate Pinning"
        case .loginRateLimiting:
            return "Límite de Intentos de Login"

        // Features
        case .offlineMode:
            return "Modo Offline"
        case .backgroundSync:
            return "Sincronización en Background"
        case .pushNotifications:
            return "Notificaciones Push"

        // UI
        case .autoDarkMode:
            return "Tema Oscuro Automático"
        case .newDashboard:
            return "Dashboard Nuevo (Beta)"
        case .transitionAnimations:
            return "Animaciones de Transición"

        // Debug
        case .debugLogs:
            return "Logs de Debug"
        case .mockAPI:
            return "API Mock (Desarrollo)"
        }
    }

    /// Descripción detallada del feature flag
    public var description: String {
        switch self {
        // Security
        case .biometricLogin:
            return "Habilita autenticación con Face ID o Touch ID"
        case .certificatePinning:
            return "Valida certificados SSL para mayor seguridad"
        case .loginRateLimiting:
            return "Limita intentos de login para prevenir ataques"

        // Features
        case .offlineMode:
            return "Permite usar la app sin conexión a internet"
        case .backgroundSync:
            return "Sincroniza datos automáticamente en segundo plano"
        case .pushNotifications:
            return "Recibe notificaciones de la app"

        // UI
        case .autoDarkMode:
            return "Adapta el tema según las preferencias del sistema"
        case .newDashboard:
            return "Interfaz rediseñada del dashboard (experimental)"
        case .transitionAnimations:
            return "Animaciones suaves entre pantallas"

        // Debug
        case .debugLogs:
            return "Registra información detallada para depuración"
        case .mockAPI:
            return "Usa datos simulados en lugar del servidor real"
        }
    }

    /// Ícono SF Symbol para el feature flag
    public var iconName: String {
        switch self {
        // Security
        case .biometricLogin:
            return "faceid"
        case .certificatePinning:
            return "lock.shield"
        case .loginRateLimiting:
            return "timer"

        // Features
        case .offlineMode:
            return "wifi.slash"
        case .backgroundSync:
            return "arrow.triangle.2.circlepath"
        case .pushNotifications:
            return "bell.badge"

        // UI
        case .autoDarkMode:
            return "moon.stars"
        case .newDashboard:
            return "rectangle.3.group.bubble.left"
        case .transitionAnimations:
            return "wand.and.stars"

        // Debug
        case .debugLogs:
            return "ant"
        case .mockAPI:
            return "puzzlepiece.extension"
        }
    }

    /// Categoría visual del feature flag
    public var category: FeatureFlagCategory {
        switch self {
        case .biometricLogin, .certificatePinning, .loginRateLimiting:
            return .security
        case .offlineMode, .backgroundSync, .pushNotifications:
            return .features
        case .autoDarkMode, .newDashboard, .transitionAnimations:
            return .ui
        case .debugLogs, .mockAPI:
            return .debug
        }
    }

    /// Color temático para el icono del flag
    public var iconColor: Color {
        switch category {
        case .security:
            return .red
        case .features:
            return .blue
        case .ui:
            return .purple
        case .debug:
            return .orange
        }
    }
}

/// Categoría de un feature flag (para UI)
///
/// Agrupa flags por tipo para mejor organización visual
public enum FeatureFlagCategory: String, CaseIterable, Sendable {
    case security = "Seguridad"
    case features = "Características"
    case ui = "Interfaz"
    case debug = "Depuración"

    /// Ícono de la categoría
    public var icon: String {
        switch self {
        case .security:
            return "shield"
        case .features:
            return "star"
        case .ui:
            return "paintbrush"
        case .debug:
            return "hammer"
        }
    }

    /// Color de la categoría
    public var color: Color {
        switch self {
        case .security:
            return .red
        case .features:
            return .blue
        case .ui:
            return .purple
        case .debug:
            return .orange
        }
    }
}
