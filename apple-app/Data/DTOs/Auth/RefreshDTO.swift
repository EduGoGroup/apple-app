//
//  RefreshDTO.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration - Real API DTOs
//

import Foundation

// MARK: - Refresh Request

/// DTO para request de refresh de tokens (API Real EduGo)
struct RefreshRequest: Codable, Sendable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }

    init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

// MARK: - Refresh Response

/// DTO para response de refresh (API Real EduGo)
///
/// Nota: El API real solo retorna el nuevo access token.
/// El refresh token NO cambia (permanece igual).
struct RefreshResponse: Codable, Sendable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }

    /// Actualiza TokenInfo existente con nuevo access token
    /// - Parameter current: TokenInfo actual
    /// - Returns: TokenInfo actualizado con nuevo access token
    func updateTokenInfo(_ current: TokenInfo) -> TokenInfo {
        TokenInfo(
            accessToken: accessToken,
            refreshToken: current.refreshToken, // NO cambia en API real
            expiresIn: expiresIn
        )
    }
}

// MARK: - Testing

#if DEBUG
extension RefreshRequest {
    static func fixture(
        refreshToken: String = "550e8400-e29b-41d4-a716-446655440000"
    ) -> RefreshRequest {
        RefreshRequest(refreshToken: refreshToken)
    }
}

extension RefreshResponse {
    static func fixture() -> RefreshResponse {
        RefreshResponse(
            accessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.new_token",
            expiresIn: 900,
            tokenType: "Bearer"
        )
    }
}
#endif
