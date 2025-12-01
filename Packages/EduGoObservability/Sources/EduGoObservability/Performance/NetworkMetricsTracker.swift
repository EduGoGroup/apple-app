//
//  NetworkMetricsTracker.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Data/Services/Performance/
//  SPEC-012: Performance Monitoring
//

import Foundation

/// Tracker de métricas de red
///
/// ## Responsabilidad
/// - Tracking de requests HTTP en progreso
/// - Medición de duración de requests
/// - Estadísticas de red
///
/// ## Concurrency
/// - **actor:** Serializa acceso a estado mutable ✅
/// - **Estado:** activeRequests dictionary
///
/// ## Dependencies
/// - Acceso directo a DefaultPerformanceMonitor.shared (no inyectado)
/// - Razón: Evita circular dependency en actor initialization
public actor NetworkMetricsTracker {
    // MARK: - State (actor-isolated)

    /// Logger para el tracker
    private let logger: Logger

    /// Requests activos (en progreso)
    ///
    /// ## Concurrency
    /// - actor-isolated: Solo accesible dentro del actor
    private var activeRequests: [UUID: RequestMetric] = [:]

    /// Metadata de request activo
    ///
    /// ## Concurrency
    /// - Sendable: Struct inmutable ✅
    private struct RequestMetric: Sendable {
        let url: String
        let method: String
        let startTime: Date
        let requestSize: Int
    }

    // MARK: - Singleton

    /// Instancia compartida del tracker
    ///
    /// ## Concurrency
    /// - Actor singleton es thread-safe ✅
    public static let shared = NetworkMetricsTracker()

    // MARK: - Initialization

    /// Inicializa el tracker
    ///
    /// ## Concurrency
    /// - Actor init puede llamarse desde cualquier contexto
    /// - Logger inmutable: Sendable, thread-safe
    ///
    /// - Parameter logger: Logger a usar (default: performance logger)
    public init(logger: Logger? = nil) {
        self.logger = logger ?? OSLogger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.edugo.apple-app",
            category: .performance
        )
    }

    // MARK: - Request Tracking

    /// Inicia el tracking de un request
    ///
    /// ## Concurrency
    /// - actor method: Modifica activeRequests de forma thread-safe
    ///
    /// - Parameters:
    ///   - id: UUID único del request
    ///   - url: URL del request
    ///   - method: Método HTTP
    ///   - requestSize: Tamaño del body en bytes
    public func startRequest(
        id: UUID,
        url: String,
        method: String,
        requestSize: Int
    ) async {
        let metric = RequestMetric(
            url: url,
            method: method,
            startTime: Date(),
            requestSize: requestSize
        )

        activeRequests[id] = metric

        // Redact URL to prevent PII/token leakage in query params
        let safeUrl = URL(string: url).map { "\($0.host ?? "")\($0.path)" } ?? "[invalid-url]"
        await logger.debug("Request started: \(method) \(safeUrl)")
    }

    /// Finaliza el tracking de un request
    ///
    /// ## Concurrency
    /// - actor method: Serializa acceso a activeRequests
    /// - Crossing isolation a DefaultPerformanceMonitor (actor)
    ///
    /// - Parameters:
    ///   - id: UUID del request
    ///   - responseSize: Tamaño de la response en bytes
    ///   - statusCode: Código HTTP (nil si error)
    ///   - error: Error si el request falló (nil si exitoso)
    public func endRequest(
        id: UUID,
        responseSize: Int,
        statusCode: Int?,
        error: Error?
    ) async {
        guard let request = activeRequests.removeValue(forKey: id) else {
            await logger.warning("Request not found: \(id)")
            return
        }

        let duration = Date().timeIntervalSince(request.startTime)

        // ✅ Acceso directo al singleton en método async
        await DefaultPerformanceMonitor.shared.recordMetric(
            "network_request_duration",
            value: duration,
            unit: .seconds
        )

        await DefaultPerformanceMonitor.shared.recordMetric(
            "network_request_size",
            value: Double(request.requestSize),
            unit: .bytes
        )

        await DefaultPerformanceMonitor.shared.recordMetric(
            "network_response_size",
            value: Double(responseSize),
            unit: .bytes
        )

        // Logging según resultado (redact URLs to prevent PII/token leakage)
        let safeUrl = URL(string: request.url).map { "\($0.host ?? "")\($0.path)" } ?? "[invalid-url]"

        if let error = error {
            await logger.error("Request failed: \(request.method) \(safeUrl)", metadata: [
                "duration": "\(String(format: "%.3f", duration))s",
                "error": error.localizedDescription
            ])
        } else if let statusCode = statusCode {
            await logger.debug("Request completed: \(request.method) \(safeUrl)", metadata: [
                "duration": "\(String(format: "%.3f", duration))s",
                "status": "\(statusCode)",
                "responseSize": "\(responseSize) bytes"
            ])

            // Detectar requests lentos
            if duration > 5.0 {
                await logger.warning("⚠️ Slow network request", metadata: [
                    "endpoint": safeUrl,
                    "duration": "\(String(format: "%.3f", duration))s",
                    "threshold": "5.0s"
                ])
            }
        }
    }

    // MARK: - Statistics

    /// Obtiene estadísticas de requests
    ///
    /// ## Concurrency
    /// - actor method: Crossing isolation a DefaultPerformanceMonitor
    ///
    /// - Returns: Estadísticas de red
    public func getStatistics() async -> NetworkStatistics {
        // ✅ Acceso directo al singleton en método async
        let metrics = await DefaultPerformanceMonitor.shared.getRecentMetrics(category: .network)

        guard !metrics.isEmpty else {
            return NetworkStatistics(
                totalRequests: 0,
                averageDuration: 0,
                slowestRequest: 0
            )
        }

        let durations = metrics.compactMap { metric -> Double? in
            metric.name == "network_request_duration" ? metric.value : nil
        }

        let total = durations.count
        let average = durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)
        let slowest = durations.max() ?? 0

        return NetworkStatistics(
            totalRequests: total,
            averageDuration: average,
            slowestRequest: slowest
        )
    }
}

// MARK: - Supporting Types

/// Estadísticas de red
///
/// ## Concurrency
/// - Sendable: Struct inmutable ✅
public struct NetworkStatistics: Sendable {
    /// Total de requests registrados
    public let totalRequests: Int

    /// Duración promedio en segundos
    public let averageDuration: Double

    /// Request más lento en segundos
    public let slowestRequest: Double

    public init(totalRequests: Int, averageDuration: Double, slowestRequest: Double) {
        self.totalRequests = totalRequests
        self.averageDuration = averageDuration
        self.slowestRequest = slowestRequest
    }
}
