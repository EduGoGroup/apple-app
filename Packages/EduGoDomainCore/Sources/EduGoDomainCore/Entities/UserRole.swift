//
//  UserRole.swift
//  apple-app
//
//  Created on 24-01-25.
//  Updated on 28-11-25: Removidas propiedades UI para cumplir Clean Architecture
//  SPEC-003: Authentication Real API Migration
//

import Foundation

/// Roles de usuario en el sistema EduGo
///
/// Esta entidad de Domain contiene solo lógica de negocio.
/// Para propiedades de presentación (displayName, emoji, iconName),
/// ver la extensión en `Presentation/Extensions/UserRole+UI.swift`.
///
/// - Note: Cumple Clean Architecture - Domain Layer puro
enum UserRole: String, Codable, Sendable {
    case student
    case teacher
    case admin
    case parent

    // MARK: - Business Logic Properties

    /// Indica si el rol tiene privilegios administrativos
    var hasAdminPrivileges: Bool {
        self == .admin
    }

    /// Indica si el rol puede gestionar estudiantes
    var canManageStudents: Bool {
        switch self {
        case .teacher, .admin:
            return true
        case .student, .parent:
            return false
        }
    }

    /// Indica si el rol puede crear contenido educativo
    var canCreateContent: Bool {
        switch self {
        case .teacher, .admin:
            return true
        case .student, .parent:
            return false
        }
    }

    /// Indica si el rol puede ver reportes de progreso
    var canViewProgressReports: Bool {
        switch self {
        case .teacher, .admin, .parent:
            return true
        case .student:
            return false
        }
    }

    /// Indica si el rol puede calificar trabajos
    var canGrade: Bool {
        switch self {
        case .teacher, .admin:
            return true
        case .student, .parent:
            return false
        }
    }

    /// Nivel jerárquico del rol (para ordenamiento)
    var hierarchyLevel: Int {
        switch self {
        case .admin:
            return 3
        case .teacher:
            return 2
        case .parent:
            return 1
        case .student:
            return 0
        }
    }
}
