//
//  NoOpAnalyticsProvider.swift
//  apple-app
//
//  Created on 28-11-25.
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
struct NoOpAnalyticsProvider: AnalyticsProvider {
    // MARK: - Properties

    nonisolated let name = "NoOp"
    nonisolated let isAvailable = true

    // MARK: - AnalyticsProvider Implementation

    /// Inicialización vacía
    func initialize() async {
        // No-op: No hacer nada
    }

    /// Log event vacío
    func logEvent(_ name: String, parameters: [String: String]?) async {
        // No-op: No hacer nada
    }

    /// Set user property vacío
    func setUserProperty(_ name: String, value: String?) async {
        // No-op: No hacer nada
    }

    /// Set user ID vacío
    func setUserId(_ userId: String?) async {
        // No-op: No hacer nada
    }

    /// Reset vacío
    func reset() async {
        // No-op: No hacer nada
    }
}
