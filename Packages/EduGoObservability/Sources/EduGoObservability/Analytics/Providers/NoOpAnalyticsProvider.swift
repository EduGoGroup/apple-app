//
//  NoOpAnalyticsProvider.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Data/Services/Analytics/Providers/
//  SPEC-011: Analytics & Telemetry
//

import Foundation

/// Provider que no hace nada (No Operation)
///
/// ## Responsabilidad
/// - Implementación vacía del protocol AnalyticsProvider
/// - Se usa cuando el usuario ha optado out del tracking
/// - No envía datos a ningún servicio
///
/// ## Concurrency
/// - **struct Sendable:** Sin estado ✅
/// - **Thread-safe:** Struct vacío, sin operaciones
///
/// ## Privacy
/// Este provider respeta la decisión del usuario de no ser trackeado.
/// Cuando está activo, ningún evento se registra ni se envía.
///
/// ## Uso
/// ```swift
/// let manager = AnalyticsManager.shared
/// await manager.configure(with: [
///     NoOpAnalyticsProvider()  // Usuario opted out
/// ])
/// ```
public struct NoOpAnalyticsProvider: AnalyticsProvider {
    // MARK: - Properties

    public nonisolated let name = "NoOp"
    public nonisolated let isAvailable = true

    // MARK: - Initialization

    public init() {}

    // MARK: - AnalyticsProvider Implementation

    /// Inicialización vacía
    public func initialize() async {
        // No-op: No hacer nada
    }

    /// Log event vacío
    public func logEvent(_ name: String, parameters: [String: String]?) async {
        // No-op: No hacer nada
    }

    /// Set user property vacío
    public func setUserProperty(_ name: String, value: String?) async {
        // No-op: No hacer nada
    }

    /// Set user ID vacío
    public func setUserId(_ userId: String?) async {
        // No-op: No hacer nada
    }

    /// Reset vacío
    public func reset() async {
        // No-op: No hacer nada
    }
}
