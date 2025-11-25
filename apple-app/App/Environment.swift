//
//  Environment.swift
//  apple-app
//
//  Created on 23-11-25.
//  Updated on 24-01-25 - Refactored to modern Swift 6 approach
//  Updated on 24-11-25 - SPRINT2: URLs separadas para ecosistema EduGo
//  SPEC-001: Environment Configuration System (Modernized)
//

import Foundation
import OSLog

// MARK: - Authentication Mode

/// Modo de autenticación soportado
enum AuthenticationMode: Sendable, Equatable {
    case dummyJSON  // DummyJSON API (desarrollo/testing)
    case realAPI    // API Real EduGo (staging/production)
}

// MARK: - Environment Configuration (Modern Approach)

/// Sistema de configuración de ambientes usando Conditional Compilation
///
/// Este approach moderno (Xcode 26 / Swift 6 / iOS 18+) usa:
/// - Conditional compilation (#if DEBUG, STAGING, PRODUCTION)
/// - Constantes compile-time (type-safe, sin runtime overhead)
/// - SWIFT_ACTIVE_COMPILATION_CONDITIONS configurado en .xcconfig
///
/// ## URLs del Ecosistema EduGo
/// - `authAPIBaseURL`: api-admin (Puerto 8081) - Autenticación centralizada
/// - `mobileAPIBaseURL`: api-mobile (Puerto 9091) - Materiales y progreso
/// - `adminAPIBaseURL`: api-admin (Puerto 8081) - Funciones administrativas
///
/// ## Ventajas
/// - ✅ Type-safe en compile-time
/// - ✅ Sin crashes por variables faltantes
/// - ✅ Funciona en desarrollo, CI/CD, producción, TestFlight
/// - ✅ Sin runtime overhead
/// - ✅ Fácil de debuggear
///
/// ## Uso
/// ```swift
/// let authURL = AppEnvironment.authAPIBaseURL
/// let mobileURL = AppEnvironment.mobileAPIBaseURL
///
/// if AppEnvironment.isDevelopment {
///     print("🔧 Modo desarrollo")
/// }
/// ```
enum AppEnvironment {

    // MARK: - Environment Type

    /// Tipos de ambiente soportados
    enum EnvironmentType: String, Sendable, CaseIterable {
        case development = "Development"
        case staging = "Staging"
        case production = "Production"

        var displayName: String { rawValue }

        var isProduction: Bool { self == .production }
        var isDevelopment: Bool { self == .development }
        var isStaging: Bool { self == .staging }
    }

    // MARK: - Log Level

    /// Niveles de logging soportados
    enum LogLevel: String, Sendable, CaseIterable {
        case debug, info, notice, warning, error, critical

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

    // MARK: - Current Environment (Compile-Time)

    /// Ambiente actual detectado en compile-time
    static var current: EnvironmentType {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }

    // MARK: - API URLs del Ecosistema EduGo

    /// URL base para autenticación (api-admin)
    /// Endpoints: /v1/auth/login, /v1/auth/refresh, /v1/auth/logout, /v1/auth/verify
    ///
    /// Esta es la fuente única de tokens JWT para todo el ecosistema.
    /// Los tokens emitidos aquí funcionan con api-mobile y api-admin.
    static var authAPIBaseURL: URL {
        #if DEBUG
        return URL(string: "http://localhost:8081")!
        #elseif STAGING
        return URL(string: "https://staging-api-admin.edugo.com")!
        #else
        return URL(string: "https://api-admin.edugo.com")!
        #endif
    }

    /// URL base para API móvil (api-mobile)
    /// Endpoints: /v1/materials, /v1/progress, etc.
    ///
    /// Usa tokens emitidos por authAPIBaseURL (api-admin).
    static var mobileAPIBaseURL: URL {
        #if DEBUG
        return URL(string: "http://localhost:9091")!
        #elseif STAGING
        return URL(string: "https://staging-api-mobile.edugo.com")!
        #else
        return URL(string: "https://api-mobile.edugo.com")!
        #endif
    }

    /// URL base para administración (api-admin)
    /// Endpoints: /v1/schools, /v1/units, etc.
    ///
    /// Mismo servidor que auth, pero para funciones administrativas.
    static var adminAPIBaseURL: URL {
        #if DEBUG
        return URL(string: "http://localhost:8081")!
        #elseif STAGING
        return URL(string: "https://staging-api-admin.edugo.com")!
        #else
        return URL(string: "https://api-admin.edugo.com")!
        #endif
    }

    /// URL base genérica del API (retrocompatibilidad)
    /// @deprecated Usar authAPIBaseURL, mobileAPIBaseURL o adminAPIBaseURL según el servicio
    static var apiBaseURL: URL {
        mobileAPIBaseURL
    }

    /// Timeout para requests HTTP (en segundos)
    static var apiTimeout: TimeInterval {
        #if DEBUG
        return 60  // Desarrollo: permite debugging
        #elseif STAGING
        return 45  // Staging
        #else
        return 30  // Producción
        #endif
    }

    // MARK: - JWT Configuration

    /// Issuer esperado en los tokens JWT
    /// DEBE coincidir con el issuer configurado en api-admin
    static var jwtIssuer: String {
        "edugo-central"
    }

    /// Duración del access token (para cálculo de refresh anticipado)
    /// Valor por defecto: 15 minutos (900 segundos)
    static var accessTokenDuration: TimeInterval {
        15 * 60
    }

    /// Tiempo antes de expiración para iniciar refresh automático
    /// Default: 2 minutos antes de expirar
    static var tokenRefreshThreshold: TimeInterval {
        2 * 60
    }

    // MARK: - Logging Configuration

    /// Nivel de logging configurado para el ambiente actual
    static var logLevel: LogLevel {
        #if DEBUG
        return .debug  // Desarrollo: máximo detalle
        #elseif STAGING
        return .info   // Staging
        #else
        return .warning  // Producción: solo problemas
        #endif
    }

    // MARK: - Authentication Mode

    /// Modo de autenticación (DummyJSON vs Real API)
    static var authMode: AuthenticationMode {
        #if DEBUG
        return .realAPI    // Desarrollo: API real centralizada
        #elseif STAGING
        return .realAPI    // Staging: API real
        #else
        return .realAPI    // Producción: API real
        #endif
    }

    // MARK: - Feature Flags

    /// Indica si analytics está habilitado
    static var analyticsEnabled: Bool {
        #if DEBUG
        return false  // Desarrollo: deshabilitado
        #elseif STAGING
        return true   // Staging: habilitado para testing
        #else
        return true   // Producción: habilitado
        #endif
    }

    /// Indica si crashlytics está habilitado
    static var crashlyticsEnabled: Bool {
        #if DEBUG
        return false  // Desarrollo: deshabilitado
        #elseif STAGING
        return true   // Staging: habilitado
        #else
        return true   // Producción: habilitado
        #endif
    }

    // MARK: - Convenience Properties

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
    static func printDebugInfo() {
        #if DEBUG
        print("""

        🌍 EduGo Environment Configuration
        ════════════════════════════════════════════════
        Environment:      \(current.rawValue)

        📡 API URLs:
        ├─ Auth API:      \(authAPIBaseURL.absoluteString)
        ├─ Mobile API:    \(mobileAPIBaseURL.absoluteString)
        └─ Admin API:     \(adminAPIBaseURL.absoluteString)

        🔐 JWT Configuration:
        ├─ Issuer:        \(jwtIssuer)
        ├─ Token Duration: \(Int(accessTokenDuration / 60)) min
        └─ Refresh at:    \(Int(tokenRefreshThreshold / 60)) min before expiry

        ⚙️ Settings:
        ├─ Timeout:       \(Int(apiTimeout))s
        ├─ Log Level:     \(logLevel.rawValue)
        ├─ Auth Mode:     \(authMode == .dummyJSON ? "DummyJSON" : "Real API")
        ├─ Analytics:     \(analyticsEnabled ? "✅" : "❌")
        └─ Crashlytics:   \(crashlyticsEnabled ? "✅" : "❌")
        ════════════════════════════════════════════════

        """)
        #endif
    }
}

// MARK: - Convenience Extensions

extension AppEnvironment.EnvironmentType: CustomStringConvertible {
    var description: String { displayName }
}

extension AppEnvironment.LogLevel: CustomStringConvertible {
    var description: String { rawValue }
}
