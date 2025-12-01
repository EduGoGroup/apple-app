//
//  DummyJSONDTO.swift
//  EduGoDataLayer
//
//  Created on 24-01-25.
//  SPEC-003: Legacy DTOs for DummyJSON API (Feature Flag Support)
//

import Foundation
import EduGoDomainCore

// MARK: - DummyJSON DTOs (Deprecated - Solo para feature flag)

/// DTO para request de login de DummyJSON
public struct DummyJSONLoginRequest: Codable, Sendable {
    public let username: String
    public let password: String
    public let expiresInMins: Int?

    public init(username: String, password: String, expiresInMins: Int? = nil) {
        self.username = username
        self.password = password
        self.expiresInMins = expiresInMins
    }
}

/// DTO para response de login de DummyJSON
public struct DummyJSONLoginResponse: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let id: Int
    public let username: String
    public let email: String
    public let firstName: String
    public let lastName: String
    public let gender: String
    public let image: String

    /// Convierte el DTO a entidad de dominio User
    /// Con Swift 6.2 Default MainActor Isolation, structs Sendable son nonisolated implícitamente
    public func toDomain() -> User {
        User(
            id: String(id),
            email: email,
            displayName: "\(firstName) \(lastName)",
            role: .student, // DummyJSON no tiene roles, asumimos student
            isEmailVerified: true
        )
    }

    /// Convierte a TokenInfo (estimando expiración)
    public func toTokenInfo() -> TokenInfo {
        // DummyJSON no proporciona expiresIn, asumimos 30 minutos
        TokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: 1800 // 30 minutos
        )
    }
}

/// DTO para request de refresh de DummyJSON
public struct DummyJSONRefreshRequest: Codable, Sendable {
    public let refreshToken: String
    public let expiresInMins: Int?

    public init(refreshToken: String, expiresInMins: Int? = nil) {
        self.refreshToken = refreshToken
        self.expiresInMins = expiresInMins
    }
}

/// DTO para usuario de DummyJSON
public struct DummyJSONUserDTO: Codable, Sendable {
    public let id: Int
    public let username: String
    public let email: String
    public let firstName: String
    public let lastName: String
    public let gender: String
    public let image: String

    /// Convierte el DTO a entidad de dominio User
    public func toDomain() -> User {
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
    public static func fixture() -> DummyJSONLoginRequest {
        DummyJSONLoginRequest(
            username: "emilys",
            password: "emilyspass",
            expiresInMins: 30
        )
    }
}

extension DummyJSONLoginResponse {
    public static func fixture() -> DummyJSONLoginResponse {
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
