//
//  GetRecentCoursesUseCase.swift
//  apple-app
//
//  Created on 30-11-25.
//  Fase 3: Caso de uso para obtener cursos recientes
//

import Foundation

/// Caso de uso para obtener cursos recientes
@MainActor
public protocol GetRecentCoursesUseCase: Sendable {
    /// Ejecuta el caso de uso
    /// - Parameter limit: Número máximo de cursos (default: 3)
    /// - Returns: Lista de cursos o error
    func execute(limit: Int) async -> Result<[Course], AppError>
}

/// Implementación por defecto
@MainActor
public final class DefaultGetRecentCoursesUseCase: GetRecentCoursesUseCase {
    private let coursesRepository: CoursesRepository

    public nonisolated init(coursesRepository: CoursesRepository) {
        self.coursesRepository = coursesRepository
    }

    public func execute(limit: Int = 3) async -> Result<[Course], AppError> {
        await coursesRepository.getRecentCourses(limit: limit)
    }
}
