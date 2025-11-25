//
//  TokenRefreshCoordinator.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration - Token Refresh Coordinator
//

import Foundation

/// Coordina el refresh de tokens
///
/// Nota: Implementación simplificada compatible con Swift 6 strict concurrency.
/// La versión con actor completo se implementará en una fase futura cuando
/// los servicios soporten mejor concurrency.
final class TokenRefreshCoordinator: @unchecked Sendable {

    // MARK: - Dependencies

    private let apiClient: APIClient
    private let keychainService: KeychainService
    private let jwtDecoder: JWTDecoder

    // Claves de Keychain
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"

    // MARK: - Initialization

    init(
        apiClient: APIClient,
        keychainService: KeychainService,
        jwtDecoder: JWTDecoder
    ) {
        self.apiClient = apiClient
        self.keychainService = keychainService
        self.jwtDecoder = jwtDecoder
    }

    // MARK: - Public API

    /// Obtiene un token válido, refrescándolo si es necesario
    @MainActor
    func getValidToken() async throws -> TokenInfo {
        // 1. Obtener token actual
        let currentToken = try getCurrentTokenInfo()

        // 2. Si válido (no necesita refresh), retornar
        if !currentToken.shouldRefresh {
            return currentToken
        }

        // 3. Refresh necesario
        return try await performRefresh(currentToken.refreshToken)
    }

    /// Fuerza un refresh inmediato
    @MainActor
    func forceRefresh() async throws -> TokenInfo {
        let currentToken = try getCurrentTokenInfo()
        return try await performRefresh(currentToken.refreshToken)
    }

    // MARK: - Private Methods

    /// Obtiene el TokenInfo actual desde Keychain y JWT
    @MainActor
    private func getCurrentTokenInfo() throws -> TokenInfo {
        // 1. Leer tokens de Keychain
        guard let accessToken = try keychainService.getToken(for: accessTokenKey) else {
            throw AppError.network(.unauthorized)
        }

        guard let refreshToken = try keychainService.getToken(for: refreshTokenKey) else {
            throw AppError.network(.unauthorized)
        }

        // 2. Decodificar JWT para obtener expiración
        let payload = try jwtDecoder.decode(accessToken)

        return TokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: payload.exp
        )
    }

    /// Ejecuta el refresh de token llamando al API
    @MainActor
    private func performRefresh(_ refreshToken: String) async throws -> TokenInfo {
        do {
            // 1. Llamar API de refresh
            let response: RefreshResponse = try await apiClient.execute(
                endpoint: .refresh,
                method: .post,
                body: RefreshRequest(refreshToken: refreshToken)
            )

            // 2. Crear nuevo TokenInfo
            let newTokenInfo = TokenInfo(
                accessToken: response.accessToken,
                refreshToken: refreshToken, // NO cambia en API real
                expiresIn: response.expiresIn
            )

            // 3. Guardar en Keychain (solo access token)
            try keychainService.saveToken(newTokenInfo.accessToken, for: accessTokenKey)

            return newTokenInfo

        } catch {
            // Limpiar tokens si refresh falla
            try? keychainService.deleteToken(for: accessTokenKey)
            try? keychainService.deleteToken(for: refreshTokenKey)

            throw AppError.network(.unauthorized)
        }
    }
}

// MARK: - Testing

#if DEBUG
/// Mock Token Refresh Coordinator para testing
final class MockTokenRefreshCoordinator: @unchecked Sendable {
    var tokenToReturn: TokenInfo?
    var errorToThrow: Error?
    var getValidTokenCallCount = 0
    var forceRefreshCallCount = 0

    @MainActor
    func getValidToken() async throws -> TokenInfo {
        getValidTokenCallCount += 1

        if let error = errorToThrow {
            throw error
        }

        return tokenToReturn ?? .fixture()
    }

    @MainActor
    func forceRefresh() async throws -> TokenInfo {
        forceRefreshCallCount += 1

        if let error = errorToThrow {
            throw error
        }

        return tokenToReturn ?? .fixture()
    }
}
#endif
