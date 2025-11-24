//
//  Environment.swift
//  apple-app
//
//  Created on 23-11-25.
//  SPEC-001: Environment Configuration System
//

import Foundation
import OSLog

// MARK: - Authentication Mode (SPEC-003)

/// Modo de autenticación soportado
enum AuthenticationMode: Sendable, Equatable {
    case dummyJSON  // DummyJSON API (desarrollo/testing)
    case realAPI    // API Real EduGo (staging/production)
}

// MARK: - Environment Configuration

/// Sistema de configuración de ambientes basado en archivos .xcconfig
///
/// Lee la configuración desde variables inyectadas en tiempo de compilación
/// vía Build Settings desde los archivos .xcconfig correspondientes.
///
/// ## Uso
/// ```swift
/// // Obtener ambiente actual
/// let env = AppEnvironment.current  // .development, .staging, .production
///
/// // Acceder a configuración
/// let apiURL = AppEnvironment.apiBaseURL
/// let timeout = AppEnvironment.apiTimeout
/// let logLevel = AppEnvironment.logLevel
///
/// // Feature flags
/// if AppEnvironment.analyticsEnabled {
///     // Inicializar analytics
/// }
/// ```
enum AppEnvironment {

    // MARK: - Environment Type

    /// Tipos de ambiente soportados
    enum EnvironmentType: String, Sendable {
        case development = "Development"
        case staging = "Staging"
        case production = "Production"

        /// Indica si es ambiente de producción
        var isProduction: Bool {
            self == .production
        }

        /// Indica si es ambiente de desarrollo
        var isDevelopment: Bool {
            self == .development
        }

        /// Indica si es ambiente de staging
        var isStaging: Bool {
            self == .staging
        }

        /// Nombre descriptivo del ambiente
        var displayName: String {
            rawValue
        }
    }

    // MARK: - Log Level

    /// Niveles de logging soportados
    enum LogLevel: String, Sendable {
        case debug
        case info
        case notice
        case warning
        case error
        case critical

        /// Convierte el nivel a OSLogType
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .notice: return .default
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
    }

    // MARK: - Current Environment

    /// Ambiente actual detectado desde configuración de build
    static var current: EnvironmentType {
        guard let envString = infoDictionary["ENVIRONMENT_NAME"] as? String,
              let environment = EnvironmentType(rawValue: envString) else {
            #if DEBUG
            assertionFailure("⚠️ ENVIRONMENT_NAME no encontrado en Info.plist. Usando Development por defecto.")
            #endif
            return .development // Fallback seguro
        }
        return environment
    }

    // MARK: - API Configuration

    /// URL base del API configurada para el ambiente actual
    ///
    /// La URL se lee desde la variable `API_BASE_URL` configurada en el archivo .xcconfig
    /// correspondiente al ambiente actual.
    ///
    /// - Note: Si la URL no es válida, la app fallará en debug para detectar el error temprano.
    static var apiBaseURL: URL {
        guard let urlString = infoDictionary["API_BASE_URL"] as? String else {
            fatalError("❌ API_BASE_URL no encontrado en configuración de build")
        }

        // Limpiar workaround de .xcconfig (https:/$()/domain -> https://domain)
        let cleanedURL = urlString
            .replacingOccurrences(of: "https:/$()/", with: "https://")
            .replacingOccurrences(of: "http:/$()/", with: "http://")

        guard let url = URL(string: cleanedURL) else {
            fatalError("❌ API_BASE_URL tiene formato inválido: \(cleanedURL)")
        }

        return url
    }

    /// Timeout para requests HTTP (en segundos)
    ///
    /// Valores típicos por ambiente:
    /// - Development: 60s (permite debugging)
    /// - Staging: 45s
    /// - Production: 30s
    static var apiTimeout: TimeInterval {
        guard let timeoutString = infoDictionary["API_TIMEOUT"] as? String,
              let timeout = TimeInterval(timeoutString) else {
            #if DEBUG
            assertionFailure("⚠️ API_TIMEOUT no encontrado. Usando 30s por defecto.")
            #endif
            return 30
        }
        return timeout
    }

    // MARK: - Logging Configuration

    /// Nivel de logging configurado para el ambiente actual
    ///
    /// Valores por ambiente:
    /// - Development: `.debug` (máximo detalle)
    /// - Staging: `.info`
    /// - Production: `.warning` (solo problemas)
    static var logLevel: LogLevel {
        guard let levelString = infoDictionary["LOG_LEVEL"] as? String,
              let level = LogLevel(rawValue: levelString) else {
            #if DEBUG
            assertionFailure("⚠️ LOG_LEVEL no encontrado. Usando .info por defecto.")
            #endif
            return .info
        }
        return level
    }

    // MARK: - Feature Flags

    /// Indica si analytics está habilitado
    ///
    /// Por defecto:
    /// - Development: `false`
    /// - Staging: `true`
    /// - Production: `true`
    static var analyticsEnabled: Bool {
        guard let value = infoDictionary["ENABLE_ANALYTICS"] as? String else {
            return false
        }
        return value.lowercased() == "true"
    }

    /// Indica si crashlytics/crash reporting está habilitado
    ///
    /// Por defecto:
    /// - Development: `false`
    /// - Staging: `true`
    /// - Production: `true`
    static var crashlyticsEnabled: Bool {
        guard let value = infoDictionary["ENABLE_CRASHLYTICS"] as? String else {
            return false
        }
        return value.lowercased() == "true"
    }

    // MARK: - Authentication Mode (SPEC-003)

    /// Modo de autenticación (DummyJSON vs Real API)
    ///
    /// Por defecto:
    /// - Development: DummyJSON (para desarrollo rápido)
    /// - Staging: Real API
    /// - Production: Real API
    static var authMode: AuthenticationMode {
        // Leer de .xcconfig si está configurado
        if let modeString = infoDictionary["AUTH_MODE"] as? String {
            return modeString.lowercased() == "real" ? .realAPI : .dummyJSON
        }

        // Fallback basado en ambiente
        #if DEBUG
        return .dummyJSON
        #else
        return .realAPI
        #endif
    }

    // MARK: - Helpers

    /// Diccionario de Info.plist del bundle principal
    private static var infoDictionary: [String: Any] {
        Bundle.main.infoDictionary ?? [:]
    }

    /// Nombre descriptivo del ambiente actual
    static var displayName: String {
        current.displayName
    }

    /// Indica si estamos en ambiente de producción
    static var isProduction: Bool {
        current.isProduction
    }

    /// Indica si estamos en ambiente de desarrollo
    static var isDevelopment: Bool {
        current.isDevelopment
    }

    /// Indica si estamos en ambiente de staging
    static var isStaging: Bool {
        current.isStaging
    }

    // MARK: - Debug Info

    /// Imprime información de configuración en consola (solo en debug)
    ///
    /// Útil para verificar que las variables se están leyendo correctamente.
    static func printDebugInfo() {
        #if DEBUG
        print("""

        🌍 Environment Configuration:
        ════════════════════════════════════════
        Environment:    \(current.rawValue)
        API URL:        \(apiBaseURL.absoluteString)
        Timeout:        \(apiTimeout)s
        Log Level:      \(logLevel.rawValue)
        Analytics:      \(analyticsEnabled ? "✅" : "❌")
        Crashlytics:    \(crashlyticsEnabled ? "✅" : "❌")
        ════════════════════════════════════════

        """)
        #endif
    }
}

// MARK: - Convenience Extensions

extension AppEnvironment.EnvironmentType: CustomStringConvertible {
    var description: String {
        displayName
    }
}

extension AppEnvironment.LogLevel: CustomStringConvertible {
    var description: String {
        rawValue
    }
}

// MARK: - Testing Support

#if DEBUG
extension AppEnvironment {
    /// Verifica que todas las variables requeridas estén presentes
    /// - Returns: Array de variables faltantes (vacío si todo está bien)
    static func validateConfiguration() -> [String] {
        var missing: [String] = []

        // Verificar variables requeridas
        if infoDictionary["ENVIRONMENT_NAME"] == nil {
            missing.append("ENVIRONMENT_NAME")
        }
        if infoDictionary["API_BASE_URL"] == nil {
            missing.append("API_BASE_URL")
        }
        if infoDictionary["API_TIMEOUT"] == nil {
            missing.append("API_TIMEOUT")
        }
        if infoDictionary["LOG_LEVEL"] == nil {
            missing.append("LOG_LEVEL")
        }

        return missing
    }
}
#endif
