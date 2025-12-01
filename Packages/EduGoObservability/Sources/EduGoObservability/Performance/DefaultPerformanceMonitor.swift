//
//  DefaultPerformanceMonitor.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Data/Services/Performance/
//  SPEC-012: Performance Monitoring
//

import Foundation

/// Monitor de rendimiento por defecto
///
/// ## Responsabilidad
/// - Tracking de traces (operaciones con duración)
/// - Registro de métricas numéricas
/// - Almacenamiento en memoria de métricas recientes
/// - Pruning automático de métricas antiguas
/// - Detección de thresholds (operaciones lentas)
///
/// ## Concurrency (CRÍTICO)
/// - **actor:** Serializa acceso a estado mutable ✅
/// - **Estado mutable:**
///   - `activeTraces: [UUID: TraceToken]` - Traces en progreso
///   - `metrics: [PerformanceMetric]` - Métricas registradas
/// - **Thread-safety:** Garantizado por actor isolation
///
/// ## Por qué actor
/// Estado compartido mutable accedido desde múltiples contextos:
/// - ViewModels (@MainActor)
/// - Repositories (actor)
/// - Background tasks (detached)
public actor DefaultPerformanceMonitor: PerformanceMonitor {
    // MARK: - State (actor-isolated)

    private var activeTraces: [UUID: TraceToken] = [:]
    private var metrics: [PerformanceMetric] = []
    private let maxMetricsCount = 1000
    private let logger: Logger

    // MARK: - Singleton

    public static let shared = DefaultPerformanceMonitor()

    // MARK: - Initialization

    private init() {
        self.logger = OSLogger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.edugo.apple-app",
            category: .performance
        )
    }

    // MARK: - PerformanceMonitor Implementation

    public nonisolated func startTrace(_ name: String, category: MetricCategory) -> TraceToken {
        let token = TraceToken(
            id: UUID(),
            name: name,
            category: category,
            startTime: Date()
        )

        Task {
            await storeActiveTrace(token)
        }

        return token
    }

    private func storeActiveTrace(_ token: TraceToken) async {
        activeTraces[token.id] = token
        await logger.debug("Trace started: \(token.name) [\(token.category.rawValue)]")
    }

    public func endTrace(_ token: TraceToken) async {
        guard let activeToken = activeTraces.removeValue(forKey: token.id) else {
            await logger.warning("Trace not found: \(token.name)")
            return
        }

        let duration = Date().timeIntervalSince(activeToken.startTime)

        let metric = PerformanceMetric(
            name: token.name,
            category: token.category,
            value: duration,
            unit: .seconds
        )

        metrics.append(metric)

        await logger.debug("Trace ended: \(token.name) - \(String(format: "%.3f", duration))s")
        await checkThreshold(metric)
        await pruneIfNeeded()
    }

    public func recordMetric(_ name: String, value: Double, unit: MetricUnit) async {
        let metric = PerformanceMetric(
            name: name,
            category: .custom,
            value: value,
            unit: unit
        )

        metrics.append(metric)
        await logger.debug("Metric recorded: \(name) = \(value) \(unit.symbol)")
        await pruneIfNeeded()
    }

    public func getRecentMetrics(category: MetricCategory?) async -> [PerformanceMetric] {
        if let category = category {
            return metrics.filter { $0.category == category }
                .sorted { $0.timestamp > $1.timestamp }
        } else {
            return metrics.sorted { $0.timestamp > $1.timestamp }
        }
    }

    public func pruneOldMetrics() async {
        let cutoffDate = Date().addingTimeInterval(-3600)
        let before = metrics.count
        metrics.removeAll { $0.timestamp < cutoffDate }
        let removed = before - metrics.count

        if removed > 0 {
            await logger.debug("Pruned \(removed) old metrics")
        }
    }

    // MARK: - Private Helpers

    private func pruneIfNeeded() async {
        guard metrics.count > maxMetricsCount else { return }

        metrics.sort { $0.timestamp > $1.timestamp }
        let toRemove = metrics.count - maxMetricsCount
        metrics.removeLast(toRemove)

        await logger.debug("Auto-pruned \(toRemove) metrics (limit reached)")
    }

    private func checkThreshold(_ metric: PerformanceMetric) async {
        let threshold: Double? = switch metric.category {
        case .network: 5.0
        case .ui: 0.1
        case .database: 1.0
        case .launch: 3.0
        default: nil
        }

        if let threshold = threshold, metric.value > threshold {
            await logger.warning("⚠️ Slow operation detected: \(metric.name)", metadata: [
                "duration": "\(String(format: "%.3f", metric.value))s",
                "threshold": "\(threshold)s",
                "category": metric.category.rawValue
            ])
        }
    }
}
