//
//  User.swift
//  apple-app
//
//  Created on 16-11-25.
//  Updated on 24-01-25 - SPEC-003: Added role support
//

import Foundation

/// Representa un usuario autenticado en el sistema
public struct User: Codable, Identifiable, Equatable, Sendable {
    /// Identificador único del usuario (UUID)
    public let id: String

    /// Correo electrónico del usuario
    public let email: String

    /// Nombre para mostrar del usuario
    public let displayName: String

    /// Rol del usuario en el sistema
    public let role: UserRole

    /// Indica si el email ha sido verificado
    public let isEmailVerified: Bool

    // MARK: - Computed Properties

    /// Retorna las iniciales del nombre (primeras 2 letras en mayúsculas)
    public var initials: String {
        String(displayName.prefix(2).uppercased())
    }

    /// Indica si el usuario es estudiante
    public var isStudent: Bool {
        role == .student
    }

    /// Indica si el usuario es profesor
    public var isTeacher: Bool {
        role == .teacher
    }

    /// Indica si el usuario es administrador
    public var isAdmin: Bool {
        role == .admin
    }

    /// Indica si el usuario es padre/tutor
    public var isParent: Bool {
        role == .parent
    }

    // MARK: - Initializers

    public init(
        id: String,
        email: String,
        displayName: String,
        role: UserRole,
        isEmailVerified: Bool = false
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.role = role
        self.isEmailVerified = isEmailVerified
    }
}

// MARK: - Previews & Testing

public extension User {
    // Mock básico siempre disponible para previews
    static let mock = User(
        id: "550e8400-e29b-41d4-a716-446655440000",
        email: "test@edugo.com",
        displayName: "Test User",
        role: .student,
        isEmailVerified: true
    )
}

#if DEBUG
public extension User {
    /// Usuario fixture para testing con valores por defecto
    static func fixture(
        id: String = "550e8400-e29b-41d4-a716-446655440000",
        email: String = "test@edugo.com",
        displayName: String = "Test User",
        role: UserRole = .student,
        isEmailVerified: Bool = true
    ) -> User {
        User(
            id: id,
            email: email,
            displayName: displayName,
            role: role,
            isEmailVerified: isEmailVerified
        )
    }

    /// Usuario estudiante para testing
    static var studentFixture: User {
        fixture(
            displayName: "Juan Pérez",
            role: .student
        )
    }

    /// Usuario profesor para testing
    static var teacherFixture: User {
        fixture(
            id: "550e8400-e29b-41d4-a716-446655440001",
            email: "profesor@edugo.com",
            displayName: "Prof. García",
            role: .teacher
        )
    }

    /// Usuario administrador para testing
    static var adminFixture: User {
        fixture(
            id: "550e8400-e29b-41d4-a716-446655440002",
            email: "admin@edugo.com",
            displayName: "Admin Sistema",
            role: .admin
        )
    }

    /// Usuario sin verificar para testing
    static let mockUnverified = fixture(isEmailVerified: false)
}
#endif
