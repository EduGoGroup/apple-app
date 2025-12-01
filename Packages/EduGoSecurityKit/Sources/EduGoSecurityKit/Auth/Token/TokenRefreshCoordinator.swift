//
//  TokenRefreshCoordinator.swift
//  EduGoSecurityKit
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration - Token Refresh Coordinator
//  Migrated to EduGoSecurityKit on Sprint 3
//

import Foundation
import EduGoDomainCore
import EduGoSecureStorage

// MARK: - Token Refresh Service Protocol

/// Protocolo para el servicio de refresh de tokens
/// Permite inyectar diferentes implementaciones (real API, mock)
public protocol TokenRefreshService: Sendable {
    /// Ejecuta el refresh de token llamando al API
    /// - Parameter refreshToken: Token de refresh actual
    /// - Returns: Nuevo access token y tiempo de expiración
    func refreshToken(_ refreshToken: String) async throws -> (accessToken: String, expiresIn: Int)
}

// MARK: - Token Refresh Coordinator

/// Coordina el refresh de tokens con deduplicación de requests concurrentes
///
/// ## Swift 6 Concurrency
/// FASE 2 - Refactoring: Eliminado @unchecked Sendable, marcado como @MainActor.
/// Usa @MainActor porque:
/// 1. Se llama principalmente desde interceptors en main thread
/// 2. Deduplicación de refreshes se mantiene con Task tracking
///
/// ## Deduplicación
/// Si múltiples requests piden token simultáneamente y el token está expirado,
/// solo se ejecuta UN refresh. Los demás esperan al resultado del refresh en progreso.
@MainActor
public final class TokenRefreshCoordinator: TokenProvider {
    // MARK: - Dependencies

    private let refreshService: TokenRefreshService
    private let keychainService: KeychainService
    private let jwtDecoder: JWTDecoder

    // Claves de Keychain
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"

    // Task para deduplicar refreshes concurrentes
    private var ongoingRefresh: Task<TokenInfo, Error>?

    // MARK: - Initialization

    public init(
        refreshService: TokenRefreshService,
        keychainService: KeychainService,
        jwtDecoder: JWTDecoder
    ) {
        self.refreshService = refreshService
        self.keychainService = keychainService
        self.jwtDecoder = jwtDecoder
    }

    // MARK: - Public API

    /// Obtiene un token válido, refrescándolo si es necesario
    public func getValidToken() async throws -> TokenInfo {
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
    public func forceRefresh() async throws -> TokenInfo {
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
            throw TokenRefreshError.noTokenAvailable
        }

        guard let refreshToken = try await keychainService.getToken(for: refreshTokenKey) else {
            throw TokenRefreshError.noTokenAvailable
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
            // 1. Llamar API de refresh via servicio inyectado
            let (newAccessToken, expiresIn) = try await refreshService.refreshToken(refreshToken)

            // 2. Crear nuevo TokenInfo
            let newTokenInfo = TokenInfo(
                accessToken: newAccessToken,
                refreshToken: refreshToken, // NO cambia en API real
                expiresIn: expiresIn
            )

            // 3. Guardar en Keychain (solo access token)
            try await keychainService.saveToken(newTokenInfo.accessToken, for: accessTokenKey)

            return newTokenInfo
        } catch {
            // Limpiar tokens si refresh falla
            try? await keychainService.deleteToken(for: accessTokenKey)
            try? await keychainService.deleteToken(for: refreshTokenKey)

            throw TokenRefreshError.refreshFailed(underlying: error)
        }
    }
}

// MARK: - Errors

/// Errores del coordinador de refresh de tokens
public enum TokenRefreshError: Error, LocalizedError, Sendable {
    case noTokenAvailable
    case refreshFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .noTokenAvailable:
            return "No hay token disponible para refresh"
        case .refreshFailed(let error):
            return "Error al refrescar token: \(error.localizedDescription)"
        }
    }
}

// MARK: - Testing

#if DEBUG
/// Mock Token Refresh Service para testing
@MainActor
public final class MockTokenRefreshService: TokenRefreshService {
    public var accessTokenToReturn: String = "mock_access_token"
    public var expiresInToReturn: Int = 900
    public var errorToThrow: Error?
    public var refreshCallCount = 0

    public init() {}

    nonisolated public func refreshToken(_ refreshToken: String) async throws -> (accessToken: String, expiresIn: Int) {
        try await MainActor.run {
            refreshCallCount += 1
            if let error = errorToThrow {
                throw error
            }
            return (accessTokenToReturn, expiresInToReturn)
        }
    }

    public func reset() {
        accessTokenToReturn = "mock_access_token"
        expiresInToReturn = 900
        errorToThrow = nil
        refreshCallCount = 0
    }
}

/// Mock Token Refresh Coordinator para testing
@MainActor
public final class MockTokenRefreshCoordinator {
    public var tokenToReturn: TokenInfo?
    public var errorToThrow: Error?
    public var getValidTokenCallCount = 0
    public var forceRefreshCallCount = 0

    public init() {}

    public func getValidToken() async throws -> TokenInfo {
        getValidTokenCallCount += 1

        if let error = errorToThrow {
            throw error
        }

        return tokenToReturn ?? .fixture()
    }

    public func forceRefresh() async throws -> TokenInfo {
        forceRefreshCallCount += 1

        if let error = errorToThrow {
            throw error
        }

        return tokenToReturn ?? .fixture()
    }

    public func reset() {
        tokenToReturn = nil
        errorToThrow = nil
        getValidTokenCallCount = 0
        forceRefreshCallCount = 0
    }
}
#endif
