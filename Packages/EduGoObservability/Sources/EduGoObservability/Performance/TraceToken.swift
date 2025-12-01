//
//  TraceToken.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Domain/Services/Performance/
//  SPEC-012: Performance Monitoring
//

import Foundation

/// Token para tracking de traces de rendimiento
///
/// ## Responsabilidad
/// - Identificar una operación en progreso
/// - Almacenar metadata del inicio del trace
/// - Pasar información entre inicio y fin del trace
///
/// ## Concurrency
/// - **Sendable:** Struct inmutable ✅
/// - **Thread-safe:** Todos los campos son let (inmutables)
/// - **Crossing boundaries:** Puede pasarse entre actors/MainActor sin problemas
///
/// ## Inmutabilidad
/// Todos los campos son `let` para garantizar thread-safety.
/// El token se crea una vez y no se modifica.
///
/// ## Uso Típico
/// ```swift
/// let token = await monitor.startTrace("operation", category: .network)
/// // Token puede cruzar boundaries sin problemas
/// Task.detached {
///     // ... operación ...
///     await monitor.endTrace(token)  // ✅ Sendable
/// }
/// ```
public struct TraceToken: Sendable {
    /// ID único del trace
    ///
    /// Usado para correlacionar el inicio y fin del trace.
    public let id: UUID

    /// Nombre descriptivo de la operación
    ///
    /// Ejemplo: "api_login", "image_download", "database_query"
    public let name: String

    /// Categoría de la métrica
    ///
    /// Permite agrupar traces por tipo para análisis.
    public let category: MetricCategory

    /// Timestamp de inicio del trace
    ///
    /// Usado para calcular la duración cuando se finaliza el trace.
    public let startTime: Date

    // MARK: - Initialization

    public init(id: UUID, name: String, category: MetricCategory, startTime: Date) {
        self.id = id
        self.name = name
        self.category = category
        self.startTime = startTime
    }
}

// MARK: - Identifiable

extension TraceToken: Identifiable {
    // id ya está definido como propiedad
}

// MARK: - Equatable

extension TraceToken: Equatable {
    public static func == (lhs: TraceToken, rhs: TraceToken) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension TraceToken: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
