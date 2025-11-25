//
//  AuthEndpoints.swift
//  apple-app
//
//  Created on 24-11-25.
//  SPRINT2-T02: Endpoints de autenticación centralizados
//

import Foundation

/// Endpoints de autenticación centralizados
///
/// Todos apuntan a `api-admin` como servicio central de autenticación.
/// Los tokens emitidos por estos endpoints funcionan con todos los servicios
/// del ecosistema EduGo (api-mobile, api-admin).
///
/// ## Uso
/// ```swift
/// let url = AuthEndpoints.login.url
/// let method = AuthEndpoints.login.method
/// ```
enum AuthEndpoints: Sendable {
    case login
    case refresh
    case logout
    case me
    case verify

    // MARK: - Path

    /// Path del endpoint (sin base URL)
    var path: String {
        switch self {
        case .login:
            return "/v1/auth/login"
        case .refresh:
            return "/v1/auth/refresh"
        case .logout:
            return "/v1/auth/logout"
        case .me:
            return "/v1/auth/me"
        case .verify:
            return "/v1/auth/verify"
        }
    }

    // MARK: - URL

    /// URL completa del endpoint
    ///
    /// Usa `authAPIBaseURL` de AppEnvironment (api-admin)
    var url: URL {
        AppEnvironment.authAPIBaseURL.appendingPathComponent(path)
    }

    // MARK: - HTTP Method

    /// Método HTTP del endpoint
    var method: HTTPMethod {
        switch self {
        case .login, .refresh, .logout, .verify:
            return .post
        case .me:
            return .get
        }
    }

    // MARK: - Authentication

    /// Indica si el endpoint requiere autenticación (Bearer token)
    var requiresAuth: Bool {
        switch self {
        case .login, .refresh:
            return false
        case .logout, .me, .verify:
            return true
        }
    }

    // MARK: - Description

    /// Descripción del endpoint para logging
    var description: String {
        switch self {
        case .login:
            return "Login - Autenticación con email/password"
        case .refresh:
            return "Refresh - Renovar access token"
        case .logout:
            return "Logout - Revocar refresh token"
        case .me:
            return "Me - Obtener usuario actual"
        case .verify:
            return "Verify - Validar token (interno)"
        }
    }
}

// MARK: - Request Bodies

extension AuthEndpoints {

    /// Request body para login
    /// Mapea a `LoginRequest` existente en DTOs
    struct LoginRequestBody: Encodable, Sendable {
        let email: String
        let password: String
    }

    /// Request body para refresh
    /// Mapea a `RefreshRequest` existente en DTOs
    struct RefreshRequestBody: Encodable, Sendable {
        let refreshToken: String

        enum CodingKeys: String, CodingKey {
            case refreshToken = "refresh_token"
        }
    }

    /// Request body para logout
    /// Mapea a `LogoutRequest` existente en DTOs
    struct LogoutRequestBody: Encodable, Sendable {
        let refreshToken: String

        enum CodingKeys: String, CodingKey {
            case refreshToken = "refresh_token"
        }
    }

    /// Request body para verify (uso interno entre servicios)
    struct VerifyRequestBody: Encodable, Sendable {
        let tokens: [String]
    }
}

// MARK: - Response Bodies

extension AuthEndpoints {

    /// Response de login exitoso
    /// Compatible con `LoginResponse` existente en DTOs
    struct LoginResponseBody: Decodable, Sendable {
        let accessToken: String
        let refreshToken: String
        let expiresIn: Int
        let tokenType: String
        let user: UserResponseBody

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case tokenType = "token_type"
            case user
        }
    }

    /// Response de refresh exitoso
    /// Compatible con `RefreshResponse` existente en DTOs
    struct RefreshResponseBody: Decodable, Sendable {
        let accessToken: String
        let expiresIn: Int
        let tokenType: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
            case tokenType = "token_type"
        }
    }

    /// Información del usuario en respuestas
    struct UserResponseBody: Decodable, Sendable {
        let id: String
        let email: String
        let firstName: String
        let lastName: String
        let fullName: String
        let role: String

        enum CodingKeys: String, CodingKey {
            case id
            case email
            case firstName = "first_name"
            case lastName = "last_name"
            case fullName = "full_name"
            case role
        }
    }

    /// Response de verify (uso interno)
    struct VerifyResponseBody: Decodable, Sendable {
        let results: [TokenValidationResult]

        struct TokenValidationResult: Decodable, Sendable {
            let token: String
            let valid: Bool
            let error: String?
            let claims: TokenClaims?
        }

        struct TokenClaims: Decodable, Sendable {
            let sub: String
            let email: String
            let role: String
            let exp: Int
            let iat: Int
            let iss: String
        }
    }
}

// MARK: - Mappers a Domain

extension AuthEndpoints.LoginResponseBody {

    /// Convierte la respuesta de login a TokenInfo del dominio
    func toTokenInfo() -> TokenInfo {
        TokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }

    /// Convierte la respuesta de login a User del dominio
    func toUser() -> User {
        user.toUser()
    }
}

extension AuthEndpoints.RefreshResponseBody {

    /// Actualiza un TokenInfo existente con el nuevo access token
    /// - Parameter current: TokenInfo actual (el refresh token no cambia)
    /// - Returns: TokenInfo actualizado
    func updateTokenInfo(_ current: TokenInfo) -> TokenInfo {
        TokenInfo(
            accessToken: accessToken,
            refreshToken: current.refreshToken,
            expiresIn: expiresIn
        )
    }
}

extension AuthEndpoints.UserResponseBody {

    /// Convierte el response body a entidad User del dominio
    func toUser() -> User {
        User(
            id: id,
            email: email,
            displayName: fullName,
            role: UserRole(rawValue: role) ?? .student,
            isEmailVerified: true
        )
    }
}

// MARK: - Convenience Factory Methods

extension AuthEndpoints {

    /// Crea un URLRequest configurado para este endpoint
    /// - Parameter body: Body opcional para enviar
    /// - Returns: URLRequest configurado
    func makeRequest<T: Encodable>(body: T? = nil) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }

    /// Crea un URLRequest configurado con token de autenticación
    /// - Parameters:
    ///   - body: Body opcional para enviar
    ///   - token: Access token para Authorization header
    /// - Returns: URLRequest configurado
    func makeAuthenticatedRequest<T: Encodable>(body: T? = nil, token: String) throws -> URLRequest {
        var request = try makeRequest(body: body)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

// MARK: - Debug

#if DEBUG
extension AuthEndpoints: CustomDebugStringConvertible {
    var debugDescription: String {
        """
        AuthEndpoint.\(self):
          URL: \(url.absoluteString)
          Method: \(method.rawValue)
          RequiresAuth: \(requiresAuth)
        """
    }
}
#endif
