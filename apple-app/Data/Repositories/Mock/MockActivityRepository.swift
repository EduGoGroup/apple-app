//
//  MockActivityRepository.swift
//  apple-app
//
//  Created on 30-11-25.
//  Fase 3: Implementación mock de ActivityRepository
//  TODO: Reemplazar con implementación real cuando API esté disponible
//

import Foundation

/// Implementación mock de ActivityRepository
/// Retorna datos de prueba para desarrollo y previews
@MainActor
final class MockActivityRepository: ActivityRepository {

    /// Datos mock predefinidos
    private let mockActivities: [Activity] = [
        Activity(
            id: "1",
            type: .moduleCompleted,
            title: "Completaste el módulo de Swift Básico",
            timestamp: Date().addingTimeInterval(-7200), // Hace 2 horas
            iconName: "checkmark.circle.fill"
        ),
        Activity(
            id: "2",
            type: .badgeEarned,
            title: "Obtuviste la insignia 'Primera Semana'",
            timestamp: Date().addingTimeInterval(-86400), // Ayer
            iconName: "star.fill"
        ),
        Activity(
            id: "3",
            type: .forumMessage,
            title: "Nuevo mensaje en el foro de Swift",
            timestamp: Date().addingTimeInterval(-259200), // Hace 3 días
            iconName: "message.fill"
        ),
        Activity(
            id: "4",
            type: .courseStarted,
            title: "Iniciaste el curso SwiftUI Avanzado",
            timestamp: Date().addingTimeInterval(-432000), // Hace 5 días
            iconName: "play.circle.fill"
        ),
        Activity(
            id: "5",
            type: .quizCompleted,
            title: "Completaste el quiz de Concurrencia",
            timestamp: Date().addingTimeInterval(-604800), // Hace 1 semana
            iconName: "checkmark.seal.fill"
        )
    ]

    func getRecentActivity(limit: Int) async -> Result<[Activity], AppError> {
        // Simular latencia de red
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

        let activities = Array(mockActivities.prefix(limit))
        return .success(activities)
    }
}
