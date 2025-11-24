//
//  AuthDTO.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

// MARK: - Login Request

/// DTO para request de login
struct LoginRequest: Codable {
    let username: String
    let password: String
    let expiresInMins: Int?

    init(username: String, password: String, expiresInMins: Int? = nil) {
        self.username = username
        self.password = password
        self.expiresInMins = expiresInMins
    }
}

// MARK: - Login Response

/// DTO para response de login
struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let id: Int
    let username: String
    let email: String
    let firstName: String
    let lastName: String
    let gender: String
    let image: String

    /// Convierte el DTO a entidad de dominio User
    func toDomain() -> User {
        User(
            id: String(id),
            email: email,
            displayName: "\(firstName) \(lastName)",
            role: .student, // DummyJSON no proporciona role, asumimos student
            isEmailVerified: true // DummyJSON no proporciona este campo, asumimos true
        )
    }
}

// MARK: - Refresh Request

/// DTO para request de refresh de tokens
struct RefreshRequest: Codable {
    let refreshToken: String
    let expiresInMins: Int?

    init(refreshToken: String, expiresInMins: Int? = nil) {
        self.refreshToken = refreshToken
        self.expiresInMins = expiresInMins
    }
}

// MARK: - User DTO

/// DTO para usuario del API
struct UserDTO: Codable {
    let id: Int
    let username: String
    let email: String
    let firstName: String
    let lastName: String
    let gender: String
    let image: String

    /// Convierte el DTO a entidad de dominio User
    func toDomain() -> User {
        User(
            id: String(id),
            email: email,
            displayName: "\(firstName) \(lastName)",
            role: .student, // DummyJSON no proporciona role, asumimos student
            isEmailVerified: true
        )
    }
}
