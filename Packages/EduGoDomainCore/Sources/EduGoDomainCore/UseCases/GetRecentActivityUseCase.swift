//
//  GetRecentActivityUseCase.swift
//  apple-app
//
//  Created on 30-11-25.
//  Fase 3: Caso de uso para obtener actividad reciente
//

import Foundation

/// Caso de uso para obtener actividad reciente
@MainActor
protocol GetRecentActivityUseCase: Sendable {
    /// Ejecuta el caso de uso
    /// - Parameter limit: Número máximo de actividades (default: 5)
    /// - Returns: Lista de actividades o error
    func execute(limit: Int) async -> Result<[Activity], AppError>
}

/// Implementación por defecto
@MainActor
final class DefaultGetRecentActivityUseCase: GetRecentActivityUseCase {
    private let activityRepository: ActivityRepository

    nonisolated init(activityRepository: ActivityRepository) {
        self.activityRepository = activityRepository
    }

    func execute(limit: Int = 5) async -> Result<[Activity], AppError> {
        await activityRepository.getRecentActivity(limit: limit)
    }
}
