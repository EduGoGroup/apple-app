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
public struct Activity: Identifiable, Equatable, Sendable {
    public let id: String
    public let type: ActivityType
    public let title: String
    public let timestamp: Date
    public let iconName: String

    public init(
        id: String,
        type: ActivityType,
        title: String,
        timestamp: Date,
        iconName: String
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.timestamp = timestamp
        self.iconName = iconName
    }

    public enum ActivityType: String, Sendable, CaseIterable {
        case moduleCompleted = "module_completed"
        case badgeEarned = "badge_earned"
        case forumMessage = "forum_message"
        case courseStarted = "course_started"
        case quizCompleted = "quiz_completed"

        public var color: Color {
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

public extension Activity {
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

public extension Activity {
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
