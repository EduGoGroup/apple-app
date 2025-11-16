//
//  Config.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Configuración de la aplicación por ambiente
enum AppConfig {
    /// Ambiente actual de la aplicación
    static let environment: Environment = .development

    /// URL base del API según el ambiente
    static var baseURL: URL {
        URL(string: environment.baseURLString)!
    }

    /// Timeout para requests HTTP (en segundos)
    static let requestTimeout: TimeInterval = 30

    /// Tiempo de expiración por defecto de tokens (en minutos)
    static let tokenExpirationMinutes: Int = 30
}

// MARK: - Environment

extension AppConfig {
    /// Ambientes disponibles de la aplicación
    enum Environment {
        case development
        case staging
        case production

        /// URL base del API para cada ambiente
        var baseURLString: String {
            switch self {
            case .development:
                return "https://dummyjson.com"
            case .staging:
                // TODO: Cambiar por URL de staging cuando esté disponible
                return "https://dummyjson.com"
            case .production:
                // TODO: Cambiar por URL de producción cuando esté disponible
                return "https://dummyjson.com"
            }
        }

        /// Nombre descriptivo del ambiente
        var displayName: String {
            switch self {
            case .development:
                return "Development"
            case .staging:
                return "Staging"
            case .production:
                return "Production"
            }
        }

        /// Indica si es ambiente de desarrollo
        var isDevelopment: Bool {
            self == .development
        }
    }
}

// MARK: - Credentials (Solo para Development/Testing)

extension AppConfig {
    /// Credenciales de prueba (SOLO para desarrollo y testing)
    /// ⚠️ NUNCA usar en producción
    enum TestCredentials {
        static let username = "emilys"
        static let password = "emilyspass"

        /// Indica si las credenciales de prueba están disponibles
        static var available: Bool {
            environment.isDevelopment
        }
    }
}
