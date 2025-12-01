//
//  PerformanceMonitor.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Domain/Services/Performance/
//  SPEC-012: Performance Monitoring
//

import Foundation

/// Servicio de monitoreo de rendimiento
///
/// ## Responsabilidad
/// - Tracking de traces (operaciones con duración)
/// - Registro de métricas numéricas
/// - Almacenamiento temporal de métricas
/// - Detección de problemas de rendimiento
///
/// ## Concurrency
/// - **Protocol:** Sendable (puro, sin implementación)
/// - **Métodos async:** Permite implementaciones actor
/// - **Thread-safety:** Garantizado por implementación (actor)
///
/// ## Implementaciones
/// - `DefaultPerformanceMonitor` (actor) - Implementación principal
///
/// ## Uso Típico
/// ```swift
/// let monitor = DefaultPerformanceMonitor.shared
/// let token = await monitor.startTrace("api_call", category: .network)
/// // ... operación ...
/// await monitor.endTrace(token)
/// ```
public protocol PerformanceMonitor: Sendable {
    /// Inicia el tracking de una operación
    ///
    /// ## Concurrency
    /// - Synchronous: Crea token inmediato (no requiere async)
    /// - Token es Sendable: Puede cruzar boundaries
    ///
    /// - Parameters:
    ///   - name: Nombre descriptivo de la operación
    ///   - category: Categoría de la métrica
    /// - Returns: Token para finalizar el trace
    func startTrace(_ name: String, category: MetricCategory) -> TraceToken

    /// Finaliza el tracking de una operación
    ///
    /// Calcula la duración desde el inicio y registra la métrica.
    ///
    /// ## Concurrency
    /// - async: Permite crossing isolation boundaries
    ///
    /// - Parameter token: Token retornado por `startTrace`
    func endTrace(_ token: TraceToken) async

    /// Registra una métrica numérica
    ///
    /// Para métricas puntuales que no requieren tracking de duración.
    ///
    /// ## Concurrency
    /// - async: Permite crossing isolation boundaries
    ///
    /// - Parameters:
    ///   - name: Nombre de la métrica
    ///   - value: Valor numérico
    ///   - unit: Unidad de medida
    func recordMetric(_ name: String, value: Double, unit: MetricUnit) async

    /// Obtiene las métricas recientes
    ///
    /// ## Concurrency
    /// - async: Permite crossing isolation boundaries
    ///
    /// - Parameter category: Categoría para filtrar (nil = todas)
    /// - Returns: Array de métricas ordenadas por timestamp (más reciente primero)
    func getRecentMetrics(category: MetricCategory?) async -> [PerformanceMetric]

    /// Elimina métricas antiguas para liberar memoria
    ///
    /// ## Concurrency
    /// - async: Permite crossing isolation boundaries
    func pruneOldMetrics() async
}
