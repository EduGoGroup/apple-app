//
//  MockFactory.swift
//  apple-appTests
//
//  Created on 25-11-25.
//  SPEC-007: Testing Infrastructure - Mock Factory
//

import Foundation
@testable import apple_app

/// Factory centralizado para crear mocks y fixtures de testing
@MainActor
enum MockFactory {

    // MARK: - Domain Entities

    /// Crea un User fixture con valores por defecto personalizables
    static func makeUser(
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

    /// Crea un TokenInfo fixture
    static func makeTokenInfo(
        accessToken: String = "mock_access_token",
        refreshToken: String = "mock_refresh_token",
        expiresIn: TimeInterval = 900
    ) -> TokenInfo {
        TokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: Int(expiresIn)
        )
    }

    /// Crea un TokenInfo expirado
    static func makeExpiredTokenInfo() -> TokenInfo {
        TokenInfo(
            accessToken: "expired_token",
            refreshToken: "expired_refresh",
            expiresAt: Date().addingTimeInterval(-3600)
        )
    }

    /// Crea un TokenInfo que necesita refresh
    static func makeTokenNeedingRefresh() -> TokenInfo {
        TokenInfo(
            accessToken: "soon_to_expire",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(60) // Expira en 1 min
        )
    }

    // MARK: - DTOs

    /// Crea un LoginResponse fixture
    static func makeLoginResponse(
        accessToken: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        refreshToken: String = "550e8400-e29b-41d4-a716-446655440000",
        expiresIn: Int = 900,
        user: UserDTO? = nil
    ) -> LoginResponse {
        LoginResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn,
            tokenType: "Bearer",
            user: user ?? makeUserDTO()
        )
    }

    /// Crea un UserDTO fixture
    static func makeUserDTO(
        id: String = "550e8400-e29b-41d4-a716-446655440000",
        email: String = "test@edugo.com",
        firstName: String = "Test",
        lastName: String = "User",
        role: String = "student"
    ) -> UserDTO {
        UserDTO(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            fullName: "\(firstName) \(lastName)",
            role: role
        )
    }

    /// Crea un RefreshResponse fixture
    static func makeRefreshResponse(
        accessToken: String = "new_access_token",
        expiresIn: Int = 900
    ) -> RefreshResponse {
        RefreshResponse(
            accessToken: accessToken,
            expiresIn: expiresIn,
            tokenType: "Bearer"
        )
    }

    // MARK: - JWT

    /// Crea un JWTPayload fixture
    static func makeJWTPayload(
        sub: String = "550e8400-e29b-41d4-a716-446655440000",
        email: String = "test@edugo.com",
        role: String = "student",
        expiresIn: TimeInterval = 900
    ) -> JWTPayload {
        JWTPayload(
            sub: sub,
            email: email,
            role: role,
            exp: Date().addingTimeInterval(expiresIn),
            iat: Date(),
            iss: AppEnvironment.jwtIssuer
        )
    }

    // MARK: - Errors

    /// Crea un NetworkError común
    static func makeNetworkError(_ type: NetworkErrorType = .unauthorized) -> NetworkError {
        switch type {
        case .noConnection:
            return .noConnection
        case .timeout:
            return .timeout
        case .unauthorized:
            return .unauthorized
        case .serverError:
            return .serverError(500)
        }
    }

    enum NetworkErrorType {
        case noConnection, timeout, unauthorized, serverError
    }
}

// MARK: - Builder Pattern Extensions

extension MockFactory {

    /// Builder para User con API fluida
    @MainActor
    struct UserBuilder {
        private var id = "550e8400-e29b-41d4-a716-446655440000"
        private var email = "test@edugo.com"
        private var displayName = "Test User"
        private var role: UserRole = .student
        private var isEmailVerified = true

        func withId(_ id: String) -> UserBuilder {
            var builder = self
            builder.id = id
            return builder
        }

        func withEmail(_ email: String) -> UserBuilder {
            var builder = self
            builder.email = email
            return builder
        }

        func withDisplayName(_ displayName: String) -> UserBuilder {
            var builder = self
            builder.displayName = displayName
            return builder
        }

        func withRole(_ role: UserRole) -> UserBuilder {
            var builder = self
            builder.role = role
            return builder
        }

        func verified(_ isVerified: Bool = true) -> UserBuilder {
            var builder = self
            builder.isEmailVerified = isVerified
            return builder
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

    /// Inicia un builder de User
    static func user() -> UserBuilder {
        UserBuilder()
    }
}

// MARK: - Usage Examples

/*
 // Ejemplo de uso:

 // Simple
 let user = MockFactory.makeUser()
 let token = MockFactory.makeTokenInfo()

 // Con builder
 let teacher = MockFactory.user()
     .withRole(.teacher)
     .withDisplayName("Prof. García")
     .verified()
     .build()

 // DTOs
 let loginResponse = MockFactory.makeLoginResponse()

 // Tokens especiales
 let expired = MockFactory.makeExpiredTokenInfo()
 let needsRefresh = MockFactory.makeTokenNeedingRefresh()
 */
