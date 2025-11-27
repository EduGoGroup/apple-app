//
//  FixtureBuilder.swift
//  apple-appTests
//
//  Created on 24-01-25.
//  SPEC-007: Testing Infrastructure - Fixture Builder Pattern
//

import Foundation
@testable import apple_app

// MARK: - UserBuilder

/// Builder para crear usuarios de test con builder pattern
@MainActor
final class UserBuilder {
    private var id: String = "550e8400-e29b-41d4-a716-446655440000"
    private var email: String = "test@edugo.com"
    private var displayName: String = "Test User"
    private var role: UserRole = .student
    private var isEmailVerified: Bool = true

    func withID(_ id: String) -> UserBuilder {
        self.id = id
        return self
    }

    func withEmail(_ email: String) -> UserBuilder {
        self.email = email
        return self
    }

    func withDisplayName(_ displayName: String) -> UserBuilder {
        self.displayName = displayName
        return self
    }

    func withRole(_ role: UserRole) -> UserBuilder {
        self.role = role
        return self
    }

    func asStudent() -> UserBuilder {
        self.role = .student
        return self
    }

    func asTeacher() -> UserBuilder {
        self.role = .teacher
        return self
    }

    func asAdmin() -> UserBuilder {
        self.role = .admin
        return self
    }

    func unverified() -> UserBuilder {
        self.isEmailVerified = false
        return self
    }

    func build() -> User {
        User(
            id: id,
            email: email,
            displayName: displayName,
            role: role,
            isEmailVerified: isEmailVerified
        )
    }
}

// MARK: - TokenInfoBuilder

/// Builder para crear tokens de test
@MainActor
final class TokenInfoBuilder {
    private var accessToken: String = "mock_access_token"
    private var refreshToken: String = "mock_refresh_token"
    private var expiresAt = Date().addingTimeInterval(900)

    func withAccessToken(_ token: String) -> TokenInfoBuilder {
        self.accessToken = token
        return self
    }

    func withRefreshToken(_ token: String) -> TokenInfoBuilder {
        self.refreshToken = token
        return self
    }

    func expiresIn(_ seconds: TimeInterval) -> TokenInfoBuilder {
        self.expiresAt = Date().addingTimeInterval(seconds)
        return self
    }

    func expired() -> TokenInfoBuilder {
        self.expiresAt = Date().addingTimeInterval(-3600)
        return self
    }

    func needsRefresh() -> TokenInfoBuilder {
        self.expiresAt = Date().addingTimeInterval(240) // 4 min
        return self
    }

    func build() -> TokenInfo {
        TokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt
        )
    }
}

// MARK: - Convenience Extensions

extension User {
    @MainActor
    static func build(_ configure: (UserBuilder) -> UserBuilder) -> User {
        configure(UserBuilder()).build()
    }
}

extension TokenInfo {
    @MainActor
    static func build(_ configure: (TokenInfoBuilder) -> TokenInfoBuilder) -> TokenInfo {
        configure(TokenInfoBuilder()).build()
    }
}
