//
//  TokenRefreshCoordinatorTests.swift
//  apple-appTests
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration
//

import Testing
import Foundation
@testable import apple_app

@Suite("Token Refresh Coordinator Tests")
struct TokenRefreshCoordinatorTests {

    // MARK: - Helper para crear mocks

    func createMockedCoordinator(
        tokenInKeychain: TokenInfo? = nil,
        apiResponse: RefreshResponse? = nil,
        apiError: Error? = nil
    ) -> (TokenRefreshCoordinator, MockKeychainService, MockAPIClient, MockJWTDecoder) {
        let mockKeychain = MockKeychainService()
        let mockAPI = MockAPIClient()
        let mockJWT = MockJWTDecoder()

        // Setup tokens en Keychain
        if let token = tokenInKeychain {
            mockKeychain.tokens = [
                "access_token": token.accessToken,
                "refresh_token": token.refreshToken
            ]

            // Setup JWT decoder para retornar payload con expiración correcta
            mockJWT.payloadToReturn = JWTPayload(
                sub: "123",
                email: "test@test.com",
                role: "student",
                exp: token.expiresAt,
                iat: Date(),
                iss: "edugo-mobile"
            )
        }

        // Setup API response o error
        if let response = apiResponse {
            mockAPI.mockResponse = response
        }
        if let error = apiError {
            mockAPI.errorToThrow = error
        }

        let coordinator = TokenRefreshCoordinator(
            apiClient: mockAPI,
            keychainService: mockKeychain,
            jwtDecoder: mockJWT
        )

        return (coordinator, mockKeychain, mockAPI, mockJWT)
    }

    // MARK: - getValidToken Tests

    @Test("getValidToken returns current token when it's fresh")
    func getValidTokenWhenFresh() async throws {
        // Given: Token válido que no necesita refresh (expira en 15 min)
        let freshToken = TokenInfo.fresh

        let (coordinator, _, mockAPI, _) = createMockedCoordinator(
            tokenInKeychain: freshToken
        )

        // When
        let token = try await coordinator.getValidToken()

        // Then: Debe retornar el token actual sin llamar API
        #expect(token.accessToken == freshToken.accessToken)
        #expect(mockAPI.executeCallCount == 0) // No llamó API
    }

    @Test("getValidToken triggers refresh when token needs it")
    func getValidTokenTriggersRefresh() async throws {
        // Given: Token que necesita refresh (expira en 2 minutos)
        let expiringToken = TokenInfo.needingRefresh

        let (coordinator, mockKeychain, mockAPI, _) = createMockedCoordinator(
            tokenInKeychain: expiringToken,
            apiResponse: RefreshResponse.fixture()
        )

        // When
        let token = try await coordinator.getValidToken()

        // Then: Debe haber llamado API y actualizado token
        #expect(mockAPI.executeCallCount == 1)
        #expect(mockKeychain.tokens["access_token"] != expiringToken.accessToken)
        #expect(!token.needsRefresh)
    }

    @Test("getValidToken throws error when no tokens in keychain")
    func getValidTokenNoTokens() async throws {
        // Given: Sin tokens en Keychain
        let (coordinator, _, _, _) = createMockedCoordinator()

        // When/Then: Debe throw error
        await #expect(throws: AppError.self) {
            try await coordinator.getValidToken()
        }
    }

    @Test("getValidToken preserves refresh token after refresh")
    func getValidTokenPreservesRefreshToken() async throws {
        // Given: Token que necesita refresh
        let originalRefreshToken = "original_refresh_123"
        let expiringToken = TokenInfo(
            accessToken: "expiring",
            refreshToken: originalRefreshToken,
            expiresAt: Date().addingTimeInterval(120) // 2 min
        )

        let (coordinator, mockKeychain, _, _) = createMockedCoordinator(
            tokenInKeychain: expiringToken,
            apiResponse: RefreshResponse.fixture()
        )

        // When
        let newToken = try await coordinator.getValidToken()

        // Then: Refresh token NO debe cambiar
        #expect(newToken.refreshToken == originalRefreshToken)
        #expect(mockKeychain.tokens["refresh_token"] == originalRefreshToken)
    }

    // MARK: - Concurrent Refresh Tests

    @Test("Multiple concurrent calls wait for same refresh task")
    func concurrentCallsUseSameRefreshTask() async throws {
        // Given: Token que necesita refresh
        let expiringToken = TokenInfo.needingRefresh

        let (coordinator, _, mockAPI, _) = createMockedCoordinator(
            tokenInKeychain: expiringToken,
            apiResponse: RefreshResponse.fixture()
        )

        // When: 3 requests concurrentes
        async let token1 = coordinator.getValidToken()
        async let token2 = coordinator.getValidToken()
        async let token3 = coordinator.getValidToken()

        let tokens = try await [token1, token2, token3]

        // Then: Solo 1 llamada al API (mismo refresh para todos)
        #expect(mockAPI.executeCallCount == 1)

        // Todos reciben el mismo nuevo token
        #expect(tokens.allSatisfy { $0.accessToken == tokens[0].accessToken })
    }

    @Test("Sequential calls after refresh don't trigger new refresh")
    func sequentialCallsAfterRefreshDontRefresh() async throws {
        // Given: Token que necesita refresh
        let expiringToken = TokenInfo.needingRefresh

        let (coordinator, _, mockAPI, _) = createMockedCoordinator(
            tokenInKeychain: expiringToken,
            apiResponse: RefreshResponse.fixture()
        )

        // When: Primera llamada (trigger refresh)
        _ = try await coordinator.getValidToken()

        // Segunda llamada (debe usar token refrescado)
        _ = try await coordinator.getValidToken()

        // Then: Solo 1 refresh
        #expect(mockAPI.executeCallCount == 1)
    }

    // MARK: - forceRefresh Tests

    @Test("forceRefresh always triggers refresh")
    func forceRefreshAlwaysTriggers() async throws {
        // Given: Token fresco que NO necesita refresh
        let freshToken = TokenInfo.fresh

        let (coordinator, _, mockAPI, _) = createMockedCoordinator(
            tokenInKeychain: freshToken,
            apiResponse: RefreshResponse.fixture()
        )

        // When: Force refresh
        _ = try await coordinator.forceRefresh()

        // Then: Debe haber llamado API aunque token esté fresco
        #expect(mockAPI.executeCallCount == 1)
    }

    // MARK: - Error Handling Tests

    @Test("Refresh failure clears tokens from keychain")
    func refreshFailureClearsTokens() async throws {
        // Given: Token que necesita refresh y API que falla
        let expiringToken = TokenInfo.needingRefresh

        let (coordinator, mockKeychain, _, _) = createMockedCoordinator(
            tokenInKeychain: expiringToken,
            apiError: NetworkError.serverError(500, "Internal Error")
        )

        // When: Intenta refresh
        await #expect(throws: AppError.self) {
            try await coordinator.getValidToken()
        }

        // Then: Tokens deben estar eliminados
        #expect(mockKeychain.tokens["access_token"] == nil)
        #expect(mockKeychain.tokens["refresh_token"] == nil)
    }

    @Test("Refresh with invalid token throws unauthorized")
    func refreshInvalidToken() async throws {
        // Given: Token que necesita refresh y API que retorna 401
        let expiringToken = TokenInfo.needingRefresh

        let (coordinator, _, _, _) = createMockedCoordinator(
            tokenInKeychain: expiringToken,
            apiError: NetworkError.unauthorized
        )

        // When/Then
        await #expect(throws: AppError.network(.unauthorized)) {
            try await coordinator.getValidToken()
        }
    }

    // MARK: - Mock Coordinator Tests

    @Test("MockTokenRefreshCoordinator returns configured token")
    func mockCoordinatorReturnsToken() async throws {
        let mock = MockTokenRefreshCoordinator()
        let expectedToken = TokenInfo.fixture()
        mock.tokenToReturn = expectedToken

        let result = try await mock.getValidToken()

        #expect(result.accessToken == expectedToken.accessToken)
        #expect(mock.getValidTokenCallCount == 1)
    }

    @Test("MockTokenRefreshCoordinator throws configured error")
    func mockCoordinatorThrowsError() async {
        let mock = MockTokenRefreshCoordinator()
        mock.errorToThrow = AppError.network(.unauthorized)

        await #expect(throws: AppError.self) {
            try await mock.getValidToken()
        }
    }

    @Test("MockTokenRefreshCoordinator tracks call count")
    func mockCoordinatorTracksCallCount() async throws {
        let mock = MockTokenRefreshCoordinator()
        mock.tokenToReturn = TokenInfo.fixture()

        _ = try await mock.getValidToken()
        _ = try await mock.getValidToken()
        _ = try await mock.forceRefresh()

        #expect(mock.getValidTokenCallCount == 2)
        #expect(mock.forceRefreshCallCount == 1)
    }
}
