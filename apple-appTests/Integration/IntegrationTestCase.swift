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
///     let testCase = IntegrationTestCase()
///     testCase.mockAPI.mockResponse = MockFactory.makeLoginResponse()
///
///     let result = await testCase.container.resolve(AuthRepository.self).login(...)
///     try expectSuccess(result)
/// }
/// ```
@MainActor
final class IntegrationTestCase {
    // MARK: - Properties

    let container: DependencyContainer
    let mockAPI: MockAPIClient
    let mockKeychain: MockKeychainService
    let mockJWT: MockJWTDecoder
    let mockBiometric: MockBiometricService
    let mockNetworkMonitor: MockNetworkMonitor
    let mockCertPinner: MockCertificatePinner
    let mockSecurityValidator: MockSecurityValidator

    // MARK: - Initialization

    // Justificación: Configuración completa de DI para integration tests requiere registro de todas las dependencias (66 líneas).
    // swiftlint:disable function_body_length
    init() {
        // Crear mocks primero
        let api = MockAPIClient()
        let keychain = MockKeychainService()
        let jwt = MockJWTDecoder()
        let biometric = MockBiometricService()
        let networkMonitor = MockNetworkMonitor()
        let certPinner = MockCertificatePinner()
        let securityValidator = MockSecurityValidator()

        // Guardar referencias
        self.mockAPI = api
        self.mockKeychain = keychain
        self.mockJWT = jwt
        self.mockBiometric = biometric
        self.mockNetworkMonitor = networkMonitor
        self.mockCertPinner = certPinner
        self.mockSecurityValidator = securityValidator

        // Crear container
        let container = DependencyContainer()

        // Registrar mocks en container
        container.register(KeychainService.self, scope: .singleton) { keychain }
        container.register(NetworkMonitor.self, scope: .singleton) { networkMonitor }
        container.register(JWTDecoder.self, scope: .singleton) { jwt }
        container.register(BiometricAuthService.self, scope: .singleton) { biometric }
        container.register(CertificatePinner.self, scope: .singleton) { certPinner }
        container.register(SecurityValidator.self, scope: .singleton) { securityValidator }
        container.register(APIClient.self, scope: .singleton) { api }

        // TokenRefreshCoordinator con mocks
        container.register(TokenRefreshCoordinator.self, scope: .singleton) {
            TokenRefreshCoordinator(
                apiClient: api,
                keychainService: keychain,
                jwtDecoder: jwt
            )
        }

        // Validators
        container.register(InputValidator.self, scope: .singleton) {
            DefaultInputValidator()
        }

        // Repositories
        container.register(AuthRepository.self, scope: .singleton) {
            AuthRepositoryImpl(
                apiClient: api,
                keychainService: keychain,
                jwtDecoder: jwt,
                tokenCoordinator: container.resolve(TokenRefreshCoordinator.self),
                biometricService: biometric
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

        self.container = container
    }
    // swiftlint:enable function_body_length

    // MARK: - Convenience Configuration

    /// Configura mocks para un login exitoso
    func configureSuccessfulLogin() {
        mockAPI.mockResponse = MockFactory.makeLoginResponse()
        mockJWT.payloadToReturn = MockFactory.makeJWTPayload()
    }

    /// Configura mocks para un login fallido
    func configureFailedLogin(error: NetworkError = .unauthorized) {
        mockAPI.errorToThrow = error
    }

    /// Configura mocks para biometric authentication exitosa
    func configureSuccessfulBiometric() {
        mockBiometric.authenticateResult = true
        mockKeychain.tokens = [
            "stored_email": "test@edugo.com",
            "stored_password": "password123"
        ]
        configureSuccessfulLogin()
    }
}

// MARK: - Mock Network Monitor

@MainActor
final class MockNetworkMonitor: NetworkMonitor {
    var isConnectedValue: Bool = true
    var connectionTypeValue: ConnectionType = .wifi

    var isConnected: Bool {
        get async { isConnectedValue }
    }

    var connectionType: ConnectionType {
        get async { connectionTypeValue }
    }

    func connectionStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            continuation.yield(isConnectedValue)
        }
    }
}
