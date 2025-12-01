//
//  MetricCategory.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Domain/Services/Performance/
//  SPEC-012: Performance Monitoring
//

import Foundation

/// Categorías de métricas de rendimiento
///
/// ## Responsabilidad
/// Clasificar métricas para facilitar análisis y filtrado.
///
/// ## Concurrency
/// - **Sendable:** Enum sin estado mutable ✅
/// - **Thread-safe:** Value type, sin referencias compartidas
///
/// ## Uso
/// Permite agrupar métricas por tipo:
/// - Network: Llamadas API, descargas
/// - UI: Renders, animaciones
/// - Database: Queries, operaciones SwiftData
/// - Memory: Uso de RAM
/// - Launch: Tiempo de inicio de app
public enum MetricCategory: String, Sendable, CaseIterable {
    /// Métricas de red (API calls, downloads)
    case network

    /// Métricas de UI (renders, animations)
    case ui

    /// Métricas de base de datos (queries, SwiftData ops)
    case database

    /// Métricas de memoria (RAM usage, leaks)
    case memory

    /// Métricas de lanzamiento de app
    case launch

    /// Métricas de CPU
    case cpu

    /// Métricas personalizadas
    case custom
}

// MARK: - Identifiable

extension MetricCategory: Identifiable {
    public var id: String { rawValue }
}
