//
//  Activity.swift
//  apple-app
//
//  Created on 30-11-25.
//  Fase 3: Representa una actividad reciente del usuario
//

import Foundation
import SwiftUI

/// Representa una actividad reciente del usuario
struct Activity: Identifiable, Equatable, Sendable {
    let id: String
    let type: ActivityType
    let title: String
    let timestamp: Date
    let iconName: String

    enum ActivityType: String, Sendable, CaseIterable {
        case moduleCompleted = "module_completed"
        case badgeEarned = "badge_earned"
        case forumMessage = "forum_message"
        case courseStarted = "course_started"
        case quizCompleted = "quiz_completed"

        var color: Color {
            switch self {
            case .moduleCompleted: return .green
            case .badgeEarned: return .yellow
            case .forumMessage: return .blue
            case .courseStarted: return .purple
            case .quizCompleted: return .orange
            }
        }
    }
}

extension Activity {
    /// Tiempo relativo desde la actividad (ej: "Hace 2 horas")
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale.current
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    /// Color asociado al tipo de actividad
    var color: Color {
        type.color
    }
}

// MARK: - Mock para Previews y Tests

extension Activity {
    static let mock = Activity(
        id: "mock-1",
        type: .moduleCompleted,
        title: "Completaste el módulo de prueba",
        timestamp: Date().addingTimeInterval(-3600),
        iconName: "checkmark.circle.fill"
    )

    static let mockList: [Activity] = [
        Activity(
            id: "1",
            type: .moduleCompleted,
            title: "Completaste el módulo de Swift Básico",
            timestamp: Date().addingTimeInterval(-7200),
            iconName: "checkmark.circle.fill"
        ),
        Activity(
            id: "2",
            type: .badgeEarned,
            title: "Obtuviste la insignia 'Primera Semana'",
            timestamp: Date().addingTimeInterval(-86400),
            iconName: "star.fill"
        ),
        Activity(
            id: "3",
            type: .forumMessage,
            title: "Nuevo mensaje en el foro de Swift",
            timestamp: Date().addingTimeInterval(-259200),
            iconName: "message.fill"
        )
    ]
}
