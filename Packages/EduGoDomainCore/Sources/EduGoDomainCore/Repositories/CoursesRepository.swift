//
//  CoursesRepository.swift
//  apple-app
//
//  Created on 30-11-25.
//  Fase 3: Protocolo para gestionar cursos del usuario
//

import Foundation

/// Protocolo para gestionar cursos del usuario
@MainActor
protocol CoursesRepository: Sendable {
    /// Obtiene los cursos recientes del usuario (ordenados por última actividad)
    /// - Parameter limit: Número máximo de cursos a retornar
    /// - Returns: Lista de cursos o error
    func getRecentCourses(limit: Int) async -> Result<[Course], AppError>

    /// Obtiene todos los cursos del usuario
    /// - Returns: Lista completa de cursos o error
    func getAllCourses() async -> Result<[Course], AppError>

    /// Obtiene un curso por su ID
    /// - Parameter id: Identificador del curso
    /// - Returns: Curso encontrado o error
    func getCourse(byId id: String) async -> Result<Course, AppError>
}
