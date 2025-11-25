//
//  IntegrationTestCase.swift
//  apple-appTests
//
//  Created on 24-01-25.
//  Updated on 24-11-25 - Fix closure capture semantics
//  SPEC-007: Testing Infrastructure - Integration Test Base
//

import Testing
import Foundation
@testable import apple_app

/// Base class para integration tests con DI container pre-configurado
@MainActor
class IntegrationTestCase {

    var container: DependencyContainer!
    var mockKeychain: MockKeychainService!
    var mockAPI: MockAPIClient!
    var mockJWT: MockJWTDecoder!
    var mockBiometric: MockBiometricService!
    var mockNetwork: MockNetworkMonitor!

    init() {
        setupContainer()
    }

    func setupContainer() {
        container = DependencyContainer()

        // Create mocks
        mockKeychain = MockKeychainService()
        mockAPI = MockAPIClient()
        mockJWT = MockJWTDecoder()
        mockBiometric = MockBiometricService()
        mockNetwork = MockNetworkMonitor()

        // Capture references for closures
        let keychain = mockKeychain!
        let api = mockAPI!
        let jwt = mockJWT!
        let biometric = mockBiometric!
        let network = mockNetwork!
        let containerRef = container!

        // Register mocks
        container.register(KeychainService.self, scope: .singleton) {
            keychain
        }

        container.register(NetworkMonitor.self, scope: .singleton) {
            network
        }

        container.register(APIClient.self, scope: .singleton) {
            api
        }

        container.register(JWTDecoder.self, scope: .singleton) {
            jwt
        }

        container.register(BiometricAuthService.self, scope: .singleton) {
            biometric
        }

        container.register(TokenRefreshCoordinator.self, scope: .singleton) {
            TokenRefreshCoordinator(
                apiClient: api,
                keychainService: keychain,
                jwtDecoder: jwt
            )
        }

        container.register(AuthRepository.self, scope: .singleton) {
            AuthRepositoryImpl(
                apiClient: api,
                keychainService: keychain,
                jwtDecoder: jwt,
                tokenCoordinator: containerRef.resolve(TokenRefreshCoordinator.self),
                biometricService: biometric,
                authMode: .realAPI // Siempre usar Real API en tests
            )
        }

        container.register(InputValidator.self, scope: .singleton) {
            DefaultInputValidator()
        }

        // Use Cases
        container.register(LoginUseCase.self) {
            DefaultLoginUseCase(
                authRepository: containerRef.resolve(AuthRepository.self),
                validator: containerRef.resolve(InputValidator.self)
            )
        }

        container.register(LogoutUseCase.self) {
            DefaultLogoutUseCase(
                authRepository: containerRef.resolve(AuthRepository.self)
            )
        }

        container.register(GetCurrentUserUseCase.self) {
            DefaultGetCurrentUserUseCase(
                authRepository: containerRef.resolve(AuthRepository.self)
            )
        }
    }

    func reset() {
        mockKeychain.tokens.removeAll()
        mockAPI.executeCallCount = 0
        mockAPI.mockResponse = nil
        mockAPI.errorToThrow = nil
        mockJWT.payloadToReturn = nil
        mockJWT.errorToThrow = nil
        mockBiometric.authenticateCallCount = 0
        mockBiometric.authenticateResult = true
        mockNetwork.isConnectedValue = true
    }
}
