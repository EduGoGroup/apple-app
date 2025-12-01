//
//  MetricUnit.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Domain/Services/Performance/
//  SPEC-012: Performance Monitoring
//

import Foundation

/// Unidades de medida para métricas de rendimiento
///
/// ## Responsabilidad
/// Definir unidades estándar para métricas numéricas.
///
/// ## Concurrency
/// - **Sendable:** Enum sin estado mutable ✅
/// - **Thread-safe:** Value type, sin referencias compartidas
///
/// ## Uso
/// Proporciona context a los valores numéricos:
/// - 1.5 seconds vs 1500 milliseconds
/// - 1024 bytes vs 1 kilobyte
public enum MetricUnit: String, Sendable {
    // MARK: - Time Units

    /// Segundos
    case seconds

    /// Milisegundos
    case milliseconds

    /// Microsegundos
    case microseconds

    // MARK: - Data Size Units

    /// Bytes
    case bytes

    /// Kilobytes
    case kilobytes

    /// Megabytes
    case megabytes

    // MARK: - Count Units

    /// Contador genérico
    case count

    /// Porcentaje (0-100)
    case percentage

    // MARK: - Rate Units

    /// Operaciones por segundo
    case operationsPerSecond

    /// Frames per second
    case framesPerSecond
}

// MARK: - Identifiable

extension MetricUnit: Identifiable {
    public var id: String { rawValue }
}

// MARK: - Display

public extension MetricUnit {
    /// Símbolo para mostrar en UI
    var symbol: String {
        switch self {
        case .seconds:
            return "s"
        case .milliseconds:
            return "ms"
        case .microseconds:
            return "μs"
        case .bytes:
            return "B"
        case .kilobytes:
            return "KB"
        case .megabytes:
            return "MB"
        case .count:
            return ""
        case .percentage:
            return "%"
        case .operationsPerSecond:
            return "ops/s"
        case .framesPerSecond:
            return "fps"
        }
    }
}
