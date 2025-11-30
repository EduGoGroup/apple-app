//
//  MockCoursesRepository.swift
//  apple-app
//
//  Created on 30-11-25.
//  Fase 3: Implementación mock de CoursesRepository
//  TODO: Reemplazar con implementación real cuando API esté disponible
//

import Foundation

/// Implementación mock de CoursesRepository
@MainActor
final class MockCoursesRepository: CoursesRepository {

    private let mockCourses: [Course] = [
        Course(
            id: "1",
            title: "Swift 6 Avanzado",
            description: "Domina las nuevas características de Swift 6 incluyendo concurrencia estricta, macros y más.",
            progress: 0.75,
            thumbnailURL: nil,
            instructor: "Juan Pérez",
            category: .programming,
            totalLessons: 24,
            completedLessons: 18
        ),
        Course(
            id: "2",
            title: "SwiftUI Moderno",
            description: "Construye apps modernas con SwiftUI, aprovechando las nuevas APIs de iOS 18.",
            progress: 0.45,
            thumbnailURL: nil,
            instructor: "María García",
            category: .programming,
            totalLessons: 32,
            completedLessons: 14
        ),
        Course(
            id: "3",
            title: "Diseño de Apps",
            description: "Aprende los principios fundamentales del diseño de interfaces para apps móviles.",
            progress: 0.20,
            thumbnailURL: nil,
            instructor: "Carlos López",
            category: .design,
            totalLessons: 16,
            completedLessons: 3
        ),
        Course(
            id: "4",
            title: "Concurrencia en Swift",
            description: "Domina async/await, actors y el protocolo Sendable para apps thread-safe.",
            progress: 1.0,
            thumbnailURL: nil,
            instructor: "Ana Martínez",
            category: .programming,
            totalLessons: 12,
            completedLessons: 12
        ),
        Course(
            id: "5",
            title: "Inglés para Desarrolladores",
            description: "Mejora tu inglés técnico para leer documentación y comunicarte mejor.",
            progress: 0.60,
            thumbnailURL: nil,
            instructor: "David Wilson",
            category: .language,
            totalLessons: 20,
            completedLessons: 12
        )
    ]

    func getRecentCourses(limit: Int) async -> Result<[Course], AppError> {
        // Simular latencia de red
        try? await Task.sleep(nanoseconds: 250_000_000) // 250ms

        // Ordenar por progreso (los que tienen más progreso reciente primero, excluyendo completados)
        let inProgress = mockCourses.filter { !$0.isCompleted }
        let sorted = inProgress.sorted { $0.progress > $1.progress }
        let recent = Array(sorted.prefix(limit))
        return .success(recent)
    }

    func getAllCourses() async -> Result<[Course], AppError> {
        // Simular latencia de red
        try? await Task.sleep(nanoseconds: 400_000_000) // 400ms

        return .success(mockCourses)
    }

    func getCourse(byId id: String) async -> Result<Course, AppError> {
        // Simular latencia de red
        try? await Task.sleep(nanoseconds: 150_000_000) // 150ms

        if let course = mockCourses.first(where: { $0.id == id }) {
            return .success(course)
        }
        return .failure(.business(.resourceUnavailable))
    }
}
