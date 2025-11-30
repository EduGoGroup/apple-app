//
//  GetUserStatsUseCase.swift
//  apple-app
//
//  Created on 30-11-25.
//  Fase 3: Caso de uso para obtener estadísticas del usuario
//

import Foundation

/// Caso de uso para obtener estadísticas del usuario
@MainActor
protocol GetUserStatsUseCase: Sendable {
    /// Ejecuta el caso de uso
    /// - Returns: Estadísticas del usuario o error
    func execute() async -> Result<UserStats, AppError>
}

/// Implementación por defecto
@MainActor
final class DefaultGetUserStatsUseCase: GetUserStatsUseCase {
    private let statsRepository: StatsRepository

    nonisolated init(statsRepository: StatsRepository) {
        self.statsRepository = statsRepository
    }

    func execute() async -> Result<UserStats, AppError> {
        await statsRepository.getUserStats()
    }
}
