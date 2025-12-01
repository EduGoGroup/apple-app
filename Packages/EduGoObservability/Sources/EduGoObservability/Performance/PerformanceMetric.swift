//
//  PerformanceMetric.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Domain/Services/Performance/
//  SPEC-012: Performance Monitoring
//

import Foundation

/// Métrica de rendimiento registrada
///
/// ## Responsabilidad
/// Almacenar información de una métrica de rendimiento capturada.
///
/// ## Concurrency
/// - **Sendable:** Struct inmutable ✅
/// - **Thread-safe:** Todos los campos son let (inmutables)
/// - **Crossing boundaries:** Puede cruzar isolation boundaries sin problemas
///
/// ## Inmutabilidad
/// Todos los campos son `let` para garantizar thread-safety.
/// Una vez creada, la métrica no se modifica.
///
/// ## Uso Típico
/// ```swift
/// let metric = PerformanceMetric(
///     name: "api_call_duration",
///     category: .network,
///     value: 1.5,
///     unit: .seconds,
///     metadata: ["endpoint": "/login"]
/// )
/// ```
public struct PerformanceMetric: Sendable, Identifiable {
    /// ID único de la métrica
    public let id: UUID

    /// Nombre descriptivo de la métrica
    ///
    /// Ejemplo: "app_launch_time", "api_call_duration", "memory_usage"
    public let name: String

    /// Categoría de la métrica
    ///
    /// Permite agrupar métricas por tipo para análisis.
    public let category: MetricCategory

    /// Valor numérico de la métrica
    ///
    /// Interpretado según la unidad especificada.
    public let value: Double

    /// Unidad de medida
    ///
    /// Proporciona contexto al valor numérico.
    public let unit: MetricUnit

    /// Timestamp de cuando se capturó la métrica
    public let timestamp: Date

    /// Metadata adicional (opcional)
    ///
    /// Información contextual como endpoint, screen name, error type, etc.
    public let metadata: [String: String]?

    // MARK: - Initialization

    /// Crea una nueva métrica de rendimiento
    ///
    /// ## Concurrency
    /// - nonisolated: NECESARIO para prevenir MainActor inference
    /// - Razón: Default params (Date(), UUID()) causan inference en strict mode
    /// - Permite llamadas desde actors sin 'await'
    ///
    /// - Parameters:
    ///   - id: ID único (generado automáticamente si no se proporciona)
    ///   - name: Nombre descriptivo
    ///   - category: Categoría de la métrica
    ///   - value: Valor numérico
    ///   - unit: Unidad de medida
    ///   - timestamp: Timestamp (Date.now por defecto)
    ///   - metadata: Información adicional (opcional)
    public nonisolated init(
        id: UUID = UUID(),
        name: String,
        category: MetricCategory,
        value: Double,
        unit: MetricUnit,
        timestamp: Date = Date(),
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

// MARK: - Computed Properties

public extension PerformanceMetric {
    /// Valor formateado con unidad para mostrar en UI
    ///
    /// Ejemplo: "1.5 s", "1024 KB", "60 fps"
    var formattedValue: String {
        let formatted = String(format: "%.2f", value)
        let symbol = unit.symbol
        return symbol.isEmpty ? formatted : "\(formatted) \(symbol)"
    }

    /// Indica si la métrica es reciente (últimos 5 minutos)
    var isRecent: Bool {
        timestamp.timeIntervalSinceNow > -300
    }
}

// MARK: - Equatable

extension PerformanceMetric: Equatable {
    public static func == (lhs: PerformanceMetric, rhs: PerformanceMetric) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension PerformanceMetric: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
