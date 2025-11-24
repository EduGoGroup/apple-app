//
//  MockFactory.swift
//  apple-appTests
//
//  Created on 24-01-25.
//  SPEC-007: Testing Infrastructure - Mock Factory
//

import Foundation
@testable import apple_app

/// Factory centralizado para crear mocks y fixtures de testing
enum MockFactory {

    // MARK: - Users

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

    static func makeStudent() -> User {
        makeUser(role: .student, displayName: "Estudiante Test")
    }

    static func makeTeacher() -> User {
        makeUser(
            id: "550e8400-e29b-41d4-a716-446655440001",
            email: "profesor@edugo.com",
            displayName: "Prof. García",
            role: .teacher
        )
    }

    static func makeAdmin() -> User {
        makeUser(
            id: "550e8400-e29b-41d4-a716-446655440002",
            email: "admin@edugo.com",
            displayName: "Admin Sistema",
            role: .admin
        )
    }

    // MARK: - Tokens

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

    static func makeExpiredToken() -> TokenInfo {
        TokenInfo(
            accessToken: "expired_token",
            refreshToken: "expired_refresh",
            expiresAt: Date().addingTimeInterval(-3600)
        )
    }

    static func makeRefreshingToken() -> TokenInfo {
        TokenInfo(
            accessToken: "soon_to_expire",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(240) // 4 minutos
        )
    }

    // MARK: - JWT Payload

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
            iss: "edugo-mobile"
        )
    }

    // MARK: - DTOs

    static func makeLoginRequest(
        email: String = "test@edugo.com",
        password: String = "password123"
    ) -> LoginRequest {
        LoginRequest(email: email, password: password)
    }

    static func makeLoginResponse(
        accessToken: String = "eyJhbGc...",
        refreshToken: String = "550e8400-...",
        user: UserDTO? = nil
    ) -> LoginResponse {
        LoginResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: 900,
            tokenType: "Bearer",
            user: user ?? makeUserDTO()
        )
    }

    static func makeUserDTO(
        id: String = "550e8400-e29b-41d4-a716-446655440000",
        email: String = "test@edugo.com",
        firstName: String = "Juan",
        lastName: String = "Pérez",
        fullName: String = "Juan Pérez",
        role: String = "student"
    ) -> UserDTO {
        UserDTO(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            fullName: fullName,
            role: role
        )
    }

    static func makeRefreshRequest(
        refreshToken: String = "550e8400-e29b-41d4-a716-446655440000"
    ) -> RefreshRequest {
        RefreshRequest(refreshToken: refreshToken)
    }

    static func makeRefreshResponse(
        accessToken: String = "new_token",
        expiresIn: Int = 900
    ) -> RefreshResponse {
        RefreshResponse(
            accessToken: accessToken,
            expiresIn: expiresIn,
            tokenType: "Bearer"
        )
    }

    // MARK: - Errors

    static func makeNetworkError(_ type: NetworkError = .serverError(500)) -> AppError {
        .network(type)
    }

    static func makeSystemError(_ message: String = "Test error") -> AppError {
        .system(.system(message))
    }

    // MARK: - Mocks

    static func makeTestContainer() -> DependencyContainer {
        let container = DependencyContainer()

        // Register mocks
        container.register(KeychainService.self, scope: .singleton) {
            MockKeychainService()
        }

        container.register(APIClient.self, scope: .singleton) {
            MockAPIClient()
        }

        container.register(JWTDecoder.self, scope: .singleton) {
            MockJWTDecoder()
        }

        container.register(BiometricAuthService.self, scope: .singleton) {
            MockBiometricService()
        }

        return container
    }
}
