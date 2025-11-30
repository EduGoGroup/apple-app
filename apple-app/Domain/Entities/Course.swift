//
//  Course.swift
//  apple-app
//
//  Created on 30-11-25.
//  Fase 3: Representa un curso en el que está inscrito el usuario
//

import Foundation
import SwiftUI

/// Representa un curso en el que está inscrito el usuario
struct Course: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let description: String
    let progress: Double // 0.0 - 1.0
    let thumbnailURL: URL?
    let instructor: String
    let category: CourseCategory
    let totalLessons: Int
    let completedLessons: Int

    enum CourseCategory: String, Sendable, CaseIterable {
        case programming = "programming"
        case design = "design"
        case business = "business"
        case language = "language"
        case other = "other"

        var displayName: String {
            switch self {
            case .programming: return "Programación"
            case .design: return "Diseño"
            case .business: return "Negocios"
            case .language: return "Idiomas"
            case .other: return "Otros"
            }
        }

        var color: Color {
            switch self {
            case .programming: return .blue
            case .design: return .purple
            case .business: return .green
            case .language: return .orange
            case .other: return .gray
            }
        }

        var iconName: String {
            switch self {
            case .programming: return "chevron.left.forwardslash.chevron.right"
            case .design: return "paintbrush.fill"
            case .business: return "briefcase.fill"
            case .language: return "textformat"
            case .other: return "square.grid.2x2.fill"
            }
        }
    }
}

// MARK: - Computed Properties

extension Course {
    /// Porcentaje de progreso formateado (ej: "75%")
    var progressPercentage: String {
        "\(Int(progress * 100))%"
    }

    /// Indicador de progreso para UI
    var progressDescription: String {
        "\(completedLessons)/\(totalLessons) lecciones"
    }

    /// Color asociado a la categoría
    var color: Color {
        category.color
    }

    /// Indica si el curso está completado
    var isCompleted: Bool {
        progress >= 1.0
    }
}

// MARK: - Mock para Previews y Tests

extension Course {
    static let mock = Course(
        id: "mock-1",
        title: "Curso de Prueba",
        description: "Un curso de prueba para desarrollo",
        progress: 0.5,
        thumbnailURL: nil,
        instructor: "Instructor Demo",
        category: .programming,
        totalLessons: 10,
        completedLessons: 5
    )

    static let mockList: [Course] = [
        Course(
            id: "1",
            title: "Swift 6 Avanzado",
            description: "Domina las nuevas características de Swift 6",
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
            description: "Construye apps con SwiftUI y iOS 18",
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
            description: "Principios de diseño para apps móviles",
            progress: 0.20,
            thumbnailURL: nil,
            instructor: "Carlos López",
            category: .design,
            totalLessons: 16,
            completedLessons: 3
        )
    ]
}
