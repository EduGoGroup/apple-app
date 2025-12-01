//
//  LoggerFactory.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Core/Logging/
//  SPEC-002: Professional Logging System
//

import Foundation

/// Factory para crear loggers pre-configurados por categoría
///
/// Proporciona loggers listos para usar en toda la aplicación, cada uno
/// asociado a una categoría específica para facilitar el filtrado en Console.app.
///
/// ## Uso
/// ```swift
/// // En un componente de networking
/// private let logger = LoggerFactory.network
/// logger.info("Request started")
///
/// // En un repositorio de auth
/// private let logger = LoggerFactory.auth
/// logger.error("Login failed")
/// ```
///
/// ## Filtrado en Console.app
/// ```
/// subsystem:com.edugo.apple-app AND category:network
/// subsystem:com.edugo.apple-app AND category:auth AND level:error
/// ```
public enum LoggerFactory {
    // MARK: - Subsystem

    /// Identificador único del subsystem (bundle identifier de la app)
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.edugo.apple-app"

    // MARK: - Pre-configured Loggers

    /// Logger para componentes de networking
    ///
    /// Usar en: APIClient, NetworkService, RequestBuilder
    public static let network: Logger = make(category: .network)

    /// Logger para componentes de autenticación
    ///
    /// Usar en: AuthRepository, BiometricService, TokenManager
    public static let auth: Logger = make(category: .auth)

    /// Logger para componentes de persistencia
    ///
    /// Usar en: KeychainService, UserDefaults, Database
    public static let data: Logger = make(category: .data)

    /// Logger para componentes de UI
    ///
    /// Usar en: Views, ViewModels, NavigationCoordinator
    public static let ui: Logger = make(category: .ui)

    /// Logger para business logic
    ///
    /// Usar en: Use Cases
    public static let business: Logger = make(category: .business)

    /// Logger para eventos del sistema
    ///
    /// Usar en: AppDelegate, App lifecycle, Memory management
    public static let system: Logger = make(category: .system)

    /// Logger para analytics y telemetry
    ///
    /// Usar en: AnalyticsManager, AnalyticsProviders
    public static let analytics: Logger = make(category: .analytics)

    /// Logger para performance monitoring
    ///
    /// Usar en: PerformanceMonitor, LaunchTimeTracker, MemoryMonitor
    public static let performance: Logger = make(category: .performance)

    // MARK: - Factory Method

    /// Crea un logger para la categoría especificada
    /// - Parameter category: Categoría del logger
    /// - Returns: Logger configurado con el subsystem de la app y la categoría
    public static func make(category: LogCategory) -> Logger {
        OSLogger(subsystem: subsystem, category: category)
    }
}
