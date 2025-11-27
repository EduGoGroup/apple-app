//
//  UserRole.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration
//

import Foundation

/// Roles de usuario en el sistema EduGo
enum UserRole: String, Codable, Sendable {
    case student
    case teacher
    case admin
    case parent

    /// Nombre descriptivo del rol para UI
    var displayName: String {
        switch self {
        case .student:
            return "Estudiante"
        case .teacher:
            return "Profesor"
        case .admin:
            return "Administrador"
        case .parent:
            return "Padre/Tutor"
        }
    }

    /// Emoji representativo del rol
    var emoji: String {
        switch self {
        case .student:
            return "🎓"
        case .teacher:
            return "👨‍🏫"
        case .admin:
            return "⚙️"
        case .parent:
            return "👨‍👩‍👧"
        }
    }
}

// MARK: - Convenience

extension UserRole: CustomStringConvertible {
    var description: String {
        "\(emoji) \(displayName)"
    }
}
