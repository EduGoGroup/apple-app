//
//  CachedUser.swift
//  EduGoDataLayer
//
//  Created on 25-11-25.
//  SPEC-005: SwiftData Integration - Cached User Model
//

import Foundation
import SwiftData
import EduGoDomainCore

/// Usuario cacheado localmente con SwiftData
///
/// Permite acceso offline a información del usuario.
/// Se sincroniza con el backend cuando hay conexión.
@Model
public final class CachedUser {
    // MARK: - Properties

    @Attribute(.unique) public var id: String
    public var email: String
    public var displayName: String
    public var role: String
    public var isEmailVerified: Bool
    public var lastUpdated: Date

    // MARK: - Initialization

    public init(
        id: String,
        email: String,
        displayName: String,
        role: String,
        isEmailVerified: Bool = true
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.role = role
        self.isEmailVerified = isEmailVerified
        self.lastUpdated = Date()
    }

    // MARK: - Domain Conversion

    /// Convierte a entidad de dominio
    @MainActor
    public func toDomain() -> User {
        User(
            id: id,
            email: email,
            displayName: displayName,
            role: UserRole(rawValue: role) ?? .student,
            isEmailVerified: isEmailVerified
        )
    }

    /// Crea desde entidad de dominio
    public static func from(_ user: User) -> CachedUser {
        CachedUser(
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            role: user.role.rawValue,
            isEmailVerified: user.isEmailVerified
        )
    }

    /// Actualiza con datos de dominio
    public func update(from user: User) {
        self.email = user.email
        self.displayName = user.displayName
        self.role = user.role.rawValue
        self.isEmailVerified = user.isEmailVerified
        self.lastUpdated = Date()
    }
}
