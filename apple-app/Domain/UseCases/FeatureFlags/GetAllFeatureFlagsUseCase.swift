//
//  GetAllFeatureFlagsUseCase.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-009: Feature Flags System
//

import Foundation

/// Use Case para obtener todos los feature flags con sus valores
///
/// ## Responsabilidad
/// Retorna un diccionario con todos los feature flags y sus valores evaluados,
/// aplicando las mismas reglas de validación que `GetFeatureFlagUseCase`.
///
/// ## Uso Típico
/// - Pantalla de configuración/debug
/// - Sincronización inicial
/// - Dashboard de feature flags
///
/// ## Clean Architecture
/// - Retorna `Result<[FeatureFlag: Bool], AppError>` (no throws)
/// - Lógica de negocio pura
/// - Reutiliza lógica de `GetFeatureFlagUseCase`
struct GetAllFeatureFlagsUseCase: Sendable {
    // MARK: - Properties

    private let repository: FeatureFlagRepository

    // MARK: - Initialization

    nonisolated init(repository: FeatureFlagRepository) {
        self.repository = repository
    }

    // MARK: - Use Case Execution

    /// Ejecuta el use case para obtener todos los feature flags
    ///
    /// - Returns: `Result` con diccionario de todos los flags y sus valores
    func execute() async -> Result<[FeatureFlag: Bool], AppError> {
        // Obtener todos los flags del repositorio
        let allFlags = await repository.getAllFlags()

        // Crear use case para validar cada flag individualmente
        let getFlagUseCase = GetFeatureFlagUseCase(repository: repository)

        var evaluatedFlags: [FeatureFlag: Bool] = [:]

        // Evaluar cada flag aplicando reglas de negocio
        for flag in FeatureFlag.allCases {
            let result = await getFlagUseCase.execute(flag: flag)

            switch result {
            case .success(let isEnabled):
                evaluatedFlags[flag] = isEnabled
            case .failure:
                // Si falla, usar valor por defecto
                evaluatedFlags[flag] = flag.defaultValue
            }
        }

        return .success(evaluatedFlags)
    }
}
