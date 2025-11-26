//
//  LogoutDTO.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration - Real API DTOs
//

import Foundation

// MARK: - Logout Request

/// DTO para request de logout (API Real EduGo)
///
/// Requiere el refresh token para revocar la sesión en el servidor.
struct LogoutRequest: Codable, Sendable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

// MARK: - Logout Response

/// El API retorna 204 No Content, por lo que no hay response body

// MARK: - Testing

#if DEBUG
extension LogoutRequest {
    static func fixture(
        refreshToken: String = "550e8400-e29b-41d4-a716-446655440000"
    ) -> LogoutRequest {
        LogoutRequest(refreshToken: refreshToken)
    }
}
#endif
