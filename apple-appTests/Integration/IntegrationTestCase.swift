//
//  IntegrationTestCase.swift
//  apple-appTests
//
//  Created on 25-11-25.
//  SPEC-007: Testing Infrastructure - Integration Test Base
//

import Foundation
import Testing
@testable import apple_app

/// Base para integration tests con DI container configurado
///
/// Proporciona un container de testing con todos los servicios mock
/// configurados y listos para usar en tests de integración.
///
/// ## Uso
/// ```swift
/// @Test func completeAuthFlow() async throws {
///     let container = createTestContainer()
///     let authRepo = container.resolve(AuthRepository.self)
///
///     let result = await authRepo.login(email: "test@test.com", password: "pass")
///     try expectSuccess(result)
/// }
/// ```
struct IntegrationTestCase {

    // MARK: - Container Creation

    /// Crea un DependencyContainer configurado para testing
    static func createTestContainer() -> DependencyContainer {
        let container = DependencyContainer()

        // Mock services
        container.register(KeychainService.self, scope: .singleton) {
            MockKeychainService()
        }

        container.register(NetworkMonitor.self, scope: .singleton) {
            MockNetworkMonitor()
        }

        container.register(JWTDecoder.self, scope: .singleton) {
            MockJWTDecoder()
        }

        container.register(BiometricAuthService.self, scope: .singleton) {
            MockBiometricService()
        }

        container.register(CertificatePinner.self, scope: .singleton) {
            MockCertificatePinner()
        }

        container.register(SecurityValidator.self, scope: .singleton) {
            MockSecurityValidator()
        }

        // Mock APIClient
        container.register(APIClient.self, scope: .singleton) {
            MockAPIClient()
        }

        // TokenRefreshCoordinator con mocks
        container.register(TokenRefreshCoordinator.self, scope: .singleton) {
            TokenRefreshCoordinator(
                apiClient: container.resolve(APIClient.self),
                keychainService: container.resolve(KeychainService.self),
                jwtDecoder: container.resolve(JWTDecoder.self)
            )
        }

        // Validators
        container.register(InputValidator.self, scope: .singleton) {
            DefaultInputValidator()
        }

        // Repositories
        container.register(AuthRepository.self, scope: .singleton) {
            AuthRepositoryImpl(
                apiClient: container.resolve(APIClient.self),
                keychainService: container.resolve(KeychainService.self),
                jwtDecoder: container.resolve(JWTDecoder.self),
                tokenCoordinator: container.resolve(TokenRefreshCoordinator.self),
                biometricService: container.resolve(BiometricAuthService.self)
            )
        }

        container.register(PreferencesRepository.self, scope: .singleton) {
            PreferencesRepositoryImpl()
        }

        // Use Cases
        container.register(LoginUseCase.self, scope: .factory) {
            DefaultLoginUseCase(
                authRepository: container.resolve(AuthRepository.self),
                validator: container.resolve(InputValidator.self)
            )
        }

        container.register(LoginWithBiometricsUseCase.self, scope: .factory) {
            DefaultLoginWithBiometricsUseCase(
                authRepository: container.resolve(AuthRepository.self)
            )
        }

        container.register(LogoutUseCase.self, scope: .factory) {
            DefaultLogoutUseCase(
                authRepository: container.resolve(AuthRepository.self)
            )
        }

        container.register(GetCurrentUserUseCase.self, scope: .factory) {
            DefaultGetCurrentUserUseCase(
                authRepository: container.resolve(AuthRepository.self)
            )
        }

        return container
    }

    // MARK: - Configured Mocks

    /// Configura mocks para un login exitoso
    static func configureSuccessfulLogin(in container: DependencyContainer) {
        let mockAPI = container.resolve(APIClient.self) as! MockAPIClient
        mockAPI.mockResponse = MockFactory.makeLoginResponse()

        let mockJWT = container.resolve(JWTDecoder.self) as! MockJWTDecoder
        mockJWT.payloadToReturn = MockFactory.makeJWTPayload()
    }

    /// Configura mocks para un login fallido
    static func configureFailedLogin(in container: DependencyContainer, error: NetworkError = .unauthorized) {
        let mockAPI = container.resolve(APIClient.self) as! MockAPIClient
        mockAPI.errorToThrow = error
    }

    /// Configura mocks para biometric authentication exitosa
    static func configureSuccessfulBiometric(in container: DependencyContainer) {
        let mockBiometric = container.resolve(BiometricAuthService.self) as! MockBiometricService
        mockBiometric.authenticateResult = true

        let mockKeychain = container.resolve(KeychainService.self) as! MockKeychainService
        mockKeychain.tokens = [
            "stored_email": "test@edugo.com",
            "stored_password": "password123"
        ]

        configureSuccessfulLogin(in: container)
    }
}

// MARK: - Mock Network Monitor

class MockNetworkMonitor: NetworkMonitor {
    var isConnected: Bool = true
    var connectionChangedCallCount = 0

    func startMonitoring() {
        // No-op en tests
    }

    func stopMonitoring() {
        // No-op en tests
    }
}
