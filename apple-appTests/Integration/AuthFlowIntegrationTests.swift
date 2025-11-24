//
//  AuthFlowIntegrationTests.swift
//  apple-appTests
//
//  Created on 24-01-25.
//  SPEC-007: Testing Infrastructure - Auth Flow E2E Tests
//

import Testing
import Foundation
@testable import apple_app

@Suite("Auth Flow Integration Tests")
@MainActor
struct AuthFlowIntegrationTests {

    // MARK: - Full Login Flow

    @Test("Complete login flow with Real API")
    func fullLoginFlow() async throws {
        // Given: Container con mocks configurados
        let testCase = IntegrationTestCase()

        testCase.mockAPI.mockResponse = MockFactory.makeLoginResponse()
        testCase.mockJWT.payloadToReturn = MockFactory.makeJWTPayload()

        let loginUseCase = testCase.container.resolve(LoginUseCase.self)

        // When: Usuario hace login
        let result = await loginUseCase.execute(
            email: "test@edugo.com",
            password: "password123"
        )

        // Then: Login exitoso
        let user = expectSuccess(result)
        #expect(user != nil)
        #expect(user?.email == "test@edugo.com")

        // Verify: Tokens guardados
        let savedToken = try? testCase.mockKeychain.getToken(for: "access_token")
        #expect(savedToken != nil)
    }

    @Test("Login flow handles network error")
    func loginWithNetworkError() async {
        // Given
        let testCase = IntegrationTestCase()
        testCase.mockAPI.errorToThrow = NetworkError.serverError(500)

        let loginUseCase = testCase.container.resolve(LoginUseCase.self)

        // When
        let result = await loginUseCase.execute(email: "test@test.com", password: "123")

        // Then
        let error = expectFailure(result)
        #expect(error != nil)
    }

    // MARK: - Token Refresh Flow

    @Test("Token refresh flow when token expires")
    func tokenRefreshFlow() async throws {
        // Given: Token que necesita refresh
        let testCase = IntegrationTestCase()

        testCase.mockKeychain.tokens = [
            "access_token": "expiring_token",
            "refresh_token": "refresh_123"
        ]

        testCase.mockJWT.payloadToReturn = JWTPayload(
            sub: "123",
            email: "test@test.com",
            role: "student",
            exp: Date().addingTimeInterval(120), // 2 minutos
            iat: Date(),
            iss: "edugo-mobile"
        )

        testCase.mockAPI.mockResponse = MockFactory.makeRefreshResponse()

        let coordinator = testCase.container.resolve(TokenRefreshCoordinator.self)

        // When: Solicitar token válido
        let token = try await coordinator.getValidToken()

        // Then: Debe haber refrescado
        #expect(token.accessToken != "expiring_token")
        #expect(testCase.mockAPI.executeCallCount == 1)
    }

    // MARK: - Logout Flow

    @Test("Complete logout flow")
    func logoutFlow() async throws {
        // Given: Usuario autenticado
        let testCase = IntegrationTestCase()

        testCase.mockKeychain.tokens = [
            "access_token": "token",
            "refresh_token": "refresh"
        ]

        let logoutUseCase = testCase.container.resolve(LogoutUseCase.self)

        // When: Logout
        let result = await logoutUseCase.execute()

        // Then: Tokens eliminados
        expectSuccess(result)
        #expect(testCase.mockKeychain.tokens.isEmpty)
    }

    // MARK: - Biometric Auth Flow

    @Test("Biometric login flow success")
    func biometricLoginFlow() async {
        // Given: Biometric disponible y credentials guardadas
        let testCase = IntegrationTestCase()

        testCase.mockBiometric.isAvailableValue = true
        testCase.mockBiometric.authenticateResult = true

        testCase.mockKeychain.tokens = [
            "stored_email": "test@test.com",
            "stored_password": "password123"
        ]

        testCase.mockAPI.mockResponse = MockFactory.makeLoginResponse()
        testCase.mockJWT.payloadToReturn = MockFactory.makeJWTPayload()

        let authRepo = testCase.container.resolve(AuthRepository.self)

        // When: Login con biometría
        let result = await authRepo.loginWithBiometrics()

        // Then: Exitoso
        let user = expectSuccess(result)
        #expect(user != nil)
        #expect(testCase.mockBiometric.authenticateCallCount == 1)
    }

    @Test("Biometric login fails when not available")
    func biometricNotAvailable() async {
        // Given
        let testCase = IntegrationTestCase()
        testCase.mockBiometric.isAvailableValue = false

        let authRepo = testCase.container.resolve(AuthRepository.self)

        // When
        let result = await authRepo.loginWithBiometrics()

        // Then
        expectFailure(result)
    }

    // MARK: - Full User Journey

    @Test("Complete user journey: Login → Get User → Logout")
    func completeUserJourney() async throws {
        let testCase = IntegrationTestCase()

        // 1. Login
        testCase.mockAPI.mockResponse = MockFactory.makeLoginResponse()
        testCase.mockJWT.payloadToReturn = MockFactory.makeJWTPayload()

        let loginUseCase = testCase.container.resolve(LoginUseCase.self)
        let loginResult = await loginUseCase.execute(email: "test@test.com", password: "123")

        let user = expectSuccess(loginResult)
        #expect(user != nil)

        // 2. Get Current User
        let getUserUseCase = testCase.container.resolve(GetCurrentUserUseCase.self)
        let getUserResult = await getUserUseCase.execute()

        let currentUser = expectSuccess(getUserResult)
        #expect(currentUser?.email == user?.email)

        // 3. Logout
        let logoutUseCase = testCase.container.resolve(LogoutUseCase.self)
        let logoutResult = await logoutUseCase.execute()

        expectSuccess(logoutResult)
        #expect(testCase.mockKeychain.tokens.isEmpty)
    }
}
