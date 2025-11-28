//
//  FeatureFlagRepository.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-009: Feature Flags System
//

import Foundation

/// Repositorio de Feature Flags
///
/// Define las operaciones para obtener y sincronizar feature flags
/// desde el backend y cache local.
///
/// ## Arquitectura
/// - **Domain Layer**: Protocol (este archivo)
/// - **Data Layer**: Implementación con actor
///
/// ## Estrategia de Obtención
/// 1. Intentar obtener de cache local (SwiftData)
/// 2. Si no hay cache o está expirado, obtener del backend
/// 3. Actualizar cache con valores del backend
/// 4. Si backend falla, usar valores por defecto
///
/// - Note: La implementación DEBE ser un `actor` para concurrency
protocol FeatureFlagRepository: Sendable {
    /// Obtiene el valor de un feature flag específico
    ///
    /// Estrategia de fallback:
    /// 1. Cache local (si es válido)
    /// 2. Backend remoto
    /// 3. Valor por defecto del flag
    ///
    /// - Parameter flag: El feature flag a consultar
    /// - Returns: `true` si el flag está habilitado, `false` si está deshabilitado
    func isEnabled(_ flag: FeatureFlag) async -> Bool

    /// Obtiene todos los feature flags con sus valores actuales
    ///
    /// - Returns: Diccionario con todos los flags y sus valores
    func getAllFlags() async -> [FeatureFlag: Bool]

    /// Sincroniza los feature flags con el backend
    ///
    /// Obtiene los valores actuales del backend y actualiza el cache local.
    /// Esta operación puede ser ejecutada en background.
    ///
    /// - Returns: `Result` con éxito o error de sincronización
    func syncFlags() async -> Result<Void, AppError>

    /// Obtiene la última fecha de sincronización exitosa
    ///
    /// - Returns: Fecha de última sincronización, o `nil` si nunca se ha sincronizado
    func getLastSyncDate() async -> Date?

    /// Fuerza la recarga de todos los flags desde el backend
    ///
    /// Ignora el cache y obtiene valores frescos del servidor.
    /// Útil para testing o cuando se sospecha de datos desactualizados.
    ///
    /// - Returns: `Result` con éxito o error de recarga
    func forceRefresh() async -> Result<Void, AppError>
}
