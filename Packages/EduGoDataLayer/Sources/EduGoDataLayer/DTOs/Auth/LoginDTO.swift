//
//  LoginDTO.swift
//  EduGoDataLayer
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration - Real API DTOs
//

import Foundation
import EduGoDomainCore

// MARK: - Login Request

/// DTO para request de login (API Real EduGo)
public struct LoginRequest: Codable, Sendable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

// MARK: - Login Response

/// DTO para response de login (API Real EduGo)
/// Compatible con: api-mobile y api-admin
public struct LoginResponse: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let tokenType: String
    public let user: UserDTO

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case user
    }

    /// Convierte a TokenInfo de dominio
    /// Con Swift 6.2 Default MainActor Isolation, structs Sendable son nonisolated implícitamente
    public func toTokenInfo() -> TokenInfo {
        TokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }

    /// Convierte el usuario a entidad de dominio
    public func toDomain() -> User {
        user.toDomain()
    }
}

// MARK: - User DTO

/// DTO para usuario del API Real EduGo
/// Compatible con: api-mobile/internal/application/dto/auth_dto.go -> UserInfo
public struct UserDTO: Codable, Sendable {
    public let id: String
    public let email: String
    public let firstName: String
    public let lastName: String
    public let fullName: String
    public let role: String

    enum CodingKeys: String, CodingKey {
        case id, email, role
        case firstName = "first_name"
        case lastName = "last_name"
        case fullName = "full_name"
    }

    public init(id: String, email: String, firstName: String, lastName: String, fullName: String, role: String) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.fullName = fullName
        self.role = role
    }

    /// Convierte el DTO a entidad de dominio User
    public func toDomain() -> User {
        User(
            id: id,
            email: email,
            displayName: fullName,
            role: UserRole(rawValue: role) ?? .student,
            isEmailVerified: true // Asumimos true si login exitoso
        )
    }
}

// MARK: - Testing

#if DEBUG
extension LoginRequest {
    public static func fixture(
        email: String = "test@edugo.com",
        password: String = "password123"
    ) -> LoginRequest {
        LoginRequest(email: email, password: password)
    }
}

extension LoginResponse {
    public static func fixture() -> LoginResponse {
        LoginResponse(
            accessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test",
            refreshToken: "550e8400-e29b-41d4-a716-446655440000",
            expiresIn: 900,
            tokenType: "Bearer",
            user: UserDTO.fixture()
        )
    }
}

extension UserDTO {
    public static func fixture() -> UserDTO {
        UserDTO(
            id: "550e8400-e29b-41d4-a716-446655440000",
            email: "test@edugo.com",
            firstName: "Juan",
            lastName: "Pérez",
            fullName: "Juan Pérez",
            role: "student"
        )
    }

    public static func teacherFixture() -> UserDTO {
        UserDTO(
            id: "550e8400-e29b-41d4-a716-446655440001",
            email: "profesor@edugo.com",
            firstName: "María",
            lastName: "García",
            fullName: "María García",
            role: "teacher"
        )
    }
}
#endif
