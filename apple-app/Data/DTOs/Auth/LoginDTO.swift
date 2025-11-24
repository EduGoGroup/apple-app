//
//  LoginDTO.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration - Real API DTOs
//

import Foundation

// MARK: - Login Request

/// DTO para request de login (API Real EduGo)
struct LoginRequest: Codable, Sendable {
    let email: String
    let password: String

    init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

// MARK: - Login Response

/// DTO para response de login (API Real EduGo)
struct LoginResponse: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let user: UserDTO

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case user
    }

    /// Convierte a TokenInfo de dominio
    func toTokenInfo() -> TokenInfo {
        TokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }

    /// Convierte el usuario a entidad de dominio
    func toDomain() -> User {
        user.toDomain()
    }
}

// MARK: - User DTO

/// DTO para usuario del API Real EduGo
struct UserDTO: Codable, Sendable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let fullName: String
    let role: String

    enum CodingKeys: String, CodingKey {
        case id, email, role
        case firstName = "first_name"
        case lastName = "last_name"
        case fullName = "full_name"
    }

    /// Convierte el DTO a entidad de dominio User
    func toDomain() -> User {
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
    static func fixture(
        email: String = "test@edugo.com",
        password: String = "password123"
    ) -> LoginRequest {
        LoginRequest(email: email, password: password)
    }
}

extension LoginResponse {
    static func fixture() -> LoginResponse {
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
    static func fixture() -> UserDTO {
        UserDTO(
            id: "550e8400-e29b-41d4-a716-446655440000",
            email: "test@edugo.com",
            firstName: "Juan",
            lastName: "Pérez",
            fullName: "Juan Pérez",
            role: "student"
        )
    }

    static func teacherFixture() -> UserDTO {
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
