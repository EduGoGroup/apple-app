//
//  DummyJSONDTO.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-003: Legacy DTOs for DummyJSON API (Feature Flag Support)
//

import Foundation

// MARK: - DummyJSON DTOs (Deprecated - Solo para feature flag)

/// DTO para request de login de DummyJSON
struct DummyJSONLoginRequest: Codable, Sendable {
    let username: String
    let password: String
    let expiresInMins: Int?

    init(username: String, password: String, expiresInMins: Int? = nil) {
        self.username = username
        self.password = password
        self.expiresInMins = expiresInMins
    }
}

/// DTO para response de login de DummyJSON
struct DummyJSONLoginResponse: Codable, Sendable {
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
            role: .student, // DummyJSON no tiene roles, asumimos student
            isEmailVerified: true
        )
    }

    /// Convierte a TokenInfo (estimando expiración)
    func toTokenInfo() -> TokenInfo {
        // DummyJSON no proporciona expiresIn, asumimos 30 minutos
        TokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: 1800 // 30 minutos
        )
    }
}

/// DTO para request de refresh de DummyJSON
struct DummyJSONRefreshRequest: Codable, Sendable {
    let refreshToken: String
    let expiresInMins: Int?

    init(refreshToken: String, expiresInMins: Int? = nil) {
        self.refreshToken = refreshToken
        self.expiresInMins = expiresInMins
    }
}

/// DTO para usuario de DummyJSON
struct DummyJSONUserDTO: Codable, Sendable {
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
            role: .student,
            isEmailVerified: true
        )
    }
}

// MARK: - Testing

#if DEBUG
extension DummyJSONLoginRequest {
    static func fixture() -> DummyJSONLoginRequest {
        DummyJSONLoginRequest(
            username: "emilys",
            password: "emilyspass",
            expiresInMins: 30
        )
    }
}

extension DummyJSONLoginResponse {
    static func fixture() -> DummyJSONLoginResponse {
        DummyJSONLoginResponse(
            accessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy",
            refreshToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh",
            id: 1,
            username: "emilys",
            email: "emily.johnson@x.dummyjson.com",
            firstName: "Emily",
            lastName: "Johnson",
            gender: "female",
            image: "https://dummyjson.com/icon/emilys/128"
        )
    }
}
#endif
