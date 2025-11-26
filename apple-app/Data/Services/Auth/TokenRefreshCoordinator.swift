//
//  TokenRefreshCoordinator.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration - Token Refresh Coordinator
//

import Foundation

/// Coordina el refresh de tokens con deduplicación de requests concurrentes
///
/// ## Swift 6 Concurrency
/// FASE 2 - Refactoring: Eliminado @unchecked Sendable, marcado como @MainActor.
/// Usa @MainActor porque:
/// 1. APIClient es @MainActor (requisito de dependencia)
/// 2. Se llama principalmente desde interceptors en main thread
/// 3. Deduplicación de refreshes se mantiene con Task tracking
///
/// ## Deduplicación
/// Si múltiples requests piden token simultáneamente y el token está expirado,
/// solo se ejecuta UN refresh. Los demás esperan al resultado del refresh en progreso.
@MainActor
final class TokenRefreshCoordinator {

    // MARK: - Dependencies

    private let apiClient: APIClient
    private let keychainService: KeychainService
    private let jwtDecoder: JWTDecoder

    // Claves de Keychain
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"

    // Task para deduplicar refreshes concurrentes
    private var ongoingRefresh: Task<TokenInfo, Error>?

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
    func getValidToken() async throws -> TokenInfo {
        // 1. Obtener token actual
        let currentToken = try await getCurrentTokenInfo()

        // 2. Si válido (no necesita refresh), retornar
        if !currentToken.shouldRefresh {
            return currentToken
        }

        // 3. Si hay un refresh en progreso, esperar a ese
        if let existingRefresh = ongoingRefresh {
            return try await existingRefresh.value
        }

        // 4. Iniciar nuevo refresh y deduplicar
        let refreshTask = Task {
            defer { self.ongoingRefresh = nil }
            return try await self.performRefresh(currentToken.refreshToken)
        }

        ongoingRefresh = refreshTask
        return try await refreshTask.value
    }

    /// Fuerza un refresh inmediato
    func forceRefresh() async throws -> TokenInfo {
        // Cancelar refresh en progreso si existe
        ongoingRefresh?.cancel()
        ongoingRefresh = nil

        let currentToken = try await getCurrentTokenInfo()
        return try await performRefresh(currentToken.refreshToken)
    }

    // MARK: - Private Methods

    /// Obtiene el TokenInfo actual desde Keychain y JWT
    private func getCurrentTokenInfo() async throws -> TokenInfo {
        // 1. Leer tokens de Keychain
        guard let accessToken = try await keychainService.getToken(for: accessTokenKey) else {
            throw AppError.network(.unauthorized)
        }

        guard let refreshToken = try await keychainService.getToken(for: refreshTokenKey) else {
            throw AppError.network(.unauthorized)
        }

        // 2. Decodificar JWT para obtener expiración
        let payload = try await jwtDecoder.decode(accessToken)

        return TokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: payload.exp
        )
    }

    /// Ejecuta el refresh de token llamando al API
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
            try await keychainService.saveToken(newTokenInfo.accessToken, for: accessTokenKey)

            return newTokenInfo

        } catch {
            // Limpiar tokens si refresh falla
            try? await keychainService.deleteToken(for: accessTokenKey)
            try? await keychainService.deleteToken(for: refreshTokenKey)

            throw AppError.network(.unauthorized)
        }
    }
}

// MARK: - Testing

#if DEBUG
/// Mock Token Refresh Coordinator para testing
///
/// ## Swift 6 Concurrency
/// FASE 2 - Refactoring: Marcado como @MainActor para alinearse con implementación real
@MainActor
final class MockTokenRefreshCoordinator {
    var tokenToReturn: TokenInfo?
    var errorToThrow: Error?
    var getValidTokenCallCount = 0
    var forceRefreshCallCount = 0

    func getValidToken() async throws -> TokenInfo {
        getValidTokenCallCount += 1

        if let error = errorToThrow {
            throw error
        }

        return tokenToReturn ?? .fixture()
    }

    func forceRefresh() async throws -> TokenInfo {
        forceRefreshCallCount += 1

        if let error = errorToThrow {
            throw error
        }

        return tokenToReturn ?? .fixture()
    }

    // Helpers para configurar mock
    func reset() {
        tokenToReturn = nil
        errorToThrow = nil
        getValidTokenCallCount = 0
        forceRefreshCallCount = 0
    }
}
#endif
