//
//  MockStatsRepository.swift
//  apple-app
//
//  Created on 30-11-25.
//  Fase 3: Implementación mock de StatsRepository
//  TODO: Reemplazar con implementación real cuando API esté disponible
//

import Foundation

/// Implementación mock de StatsRepository
@MainActor
final class MockStatsRepository: StatsRepository {

    private let mockStats = UserStats(
        coursesCompleted: 12,
        studyHoursTotal: 48,
        currentStreakDays: 7,
        totalPoints: 2450,
        rank: "Intermedio"
    )

    func getUserStats() async -> Result<UserStats, AppError> {
        // Simular latencia de red
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

        return .success(mockStats)
    }
}
