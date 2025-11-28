//
//  TraceToken.swift
//  apple-app
//
//  Created on 28-11-25.
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
struct TraceToken: Sendable {
    /// ID único del trace
    ///
    /// Usado para correlacionar el inicio y fin del trace.
    let id: UUID

    /// Nombre descriptivo de la operación
    ///
    /// Ejemplo: "api_login", "image_download", "database_query"
    let name: String

    /// Categoría de la métrica
    ///
    /// Permite agrupar traces por tipo para análisis.
    let category: MetricCategory

    /// Timestamp de inicio del trace
    ///
    /// Usado para calcular la duración cuando se finaliza el trace.
    let startTime: Date
}

// MARK: - Identifiable

extension TraceToken: Identifiable {
    // id ya está definido como propiedad
}

// MARK: - Equatable

extension TraceToken: Equatable {
    static func == (lhs: TraceToken, rhs: TraceToken) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension TraceToken: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
