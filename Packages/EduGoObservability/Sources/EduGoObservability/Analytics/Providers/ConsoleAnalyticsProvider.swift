//
//  ConsoleAnalyticsProvider.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Data/Services/Analytics/Providers/
//  SPEC-011: Analytics & Telemetry
//

import Foundation

/// Provider de analytics que imprime eventos en la consola
///
/// ## Responsabilidad
/// - Imprimir eventos de analytics en la consola de Xcode
/// - Útil para debugging y desarrollo local
/// - No envía datos a servicios externos
///
/// ## Concurrency
/// - **struct Sendable:** Sin estado mutable ✅
/// - **Logger es Sendable:** os.Logger es Sendable desde iOS 17+
/// - **Thread-safe:** Struct inmutable, logger thread-safe
///
/// ## Uso
/// Principalmente para ambiente Development/Debug.
///
/// ## Ejemplo
/// ```swift
/// let provider = ConsoleAnalyticsProvider()
/// await provider.logEvent("user_logged_in", parameters: ["method": "email"])
/// // Output: [Analytics][Console] Event: user_logged_in {"method": "email"}
/// ```
public struct ConsoleAnalyticsProvider: AnalyticsProvider {
    // MARK: - Properties

    public nonisolated let name = "Console"
    public nonisolated let isAvailable = true

    /// Logger para output
    ///
    /// ## Concurrency
    /// - os.Logger es Sendable desde iOS 17+ ✅
    /// - Inmutable (let) garantiza thread-safety
    private let logger: Logger

    // MARK: - Initialization

    /// Crea un provider de consola
    ///
    /// - Parameter logger: Logger a usar (default: analytics logger)
    public init(logger: Logger? = nil) {
        self.logger = logger ?? OSLogger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.edugo.apple-app",
            category: .analytics
        )
    }

    // MARK: - AnalyticsProvider Implementation

    public func initialize() async {
        await logger.info("[Console] Analytics provider initialized")
    }

    public func logEvent(_ name: String, parameters: [String: String]?) async {
        if let params = parameters {
            await logger.debug("[Console] Event: \(name)", metadata: [
                "parameters": "\(params)"
            ])
        } else {
            await logger.debug("[Console] Event: \(name)")
        }
    }

    public func setUserProperty(_ name: String, value: String?) async {
        if value != nil {
            await logger.debug("[Console] User Property: \(name) = [REDACTED]")
        } else {
            await logger.debug("[Console] User Property: \(name) = nil (removed)")
        }
    }

    public func setUserId(_ userId: String?) async {
        if userId != nil {
            await logger.debug("[Console] User ID set")
        } else {
            await logger.debug("[Console] User ID cleared")
        }
    }

    public func reset() async {
        await logger.debug("[Console] Analytics data reset")
    }
}
