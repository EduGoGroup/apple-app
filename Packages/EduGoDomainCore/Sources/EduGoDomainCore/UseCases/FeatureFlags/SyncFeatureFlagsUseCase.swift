//
//  SyncFeatureFlagsUseCase.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-009: Feature Flags System
//

import Foundation

/// Use Case para sincronizar feature flags con el backend
///
/// ## Responsabilidad
/// Sincroniza los feature flags desde el backend y actualiza el cache local.
/// Esta operación puede ejecutarse:
/// - Al iniciar la app
/// - En background (cada X horas)
/// - Manualmente desde configuración
///
/// ## Estrategia
/// 1. Verificar conectividad
/// 2. Llamar al backend
/// 3. Actualizar cache local
/// 4. Notificar resultado
///
/// ## Clean Architecture
/// - Retorna `Result<Void, AppError>` (no throws)
/// - No depende de estado mutable
/// - Lógica de negocio pura
public struct SyncFeatureFlagsUseCase: Sendable {
    // MARK: - Properties

    private let repository: FeatureFlagRepository

    // MARK: - Initialization

    public nonisolated init(repository: FeatureFlagRepository) {
        self.repository = repository
    }

    // MARK: - Use Case Execution

    /// Ejecuta la sincronización de feature flags
    ///
    /// - Returns: `Result` con éxito o error de sincronización
    public func execute() async -> Result<Void, AppError> {
        // Delegar al repositorio la sincronización
        return await repository.syncFlags()
    }

    /// Ejecuta la sincronización forzada (ignora cache)
    ///
    /// - Returns: `Result` con éxito o error de sincronización
    public func executeForced() async -> Result<Void, AppError> {
        // Delegar al repositorio la recarga forzada
        return await repository.forceRefresh()
    }
}
