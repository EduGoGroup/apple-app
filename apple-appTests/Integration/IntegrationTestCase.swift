//
//  IntegrationTestCase.swift
//  apple-appTests
//
//  Created on 24-01-25.
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

        // Register mocks
        container.register(KeychainService.self, scope: .singleton) {
            self.mockKeychain
        }

        container.register(NetworkMonitor.self, scope: .singleton) {
            self.mockNetwork
        }

        container.register(APIClient.self, scope: .singleton) {
            self.mockAPI
        }

        container.register(JWTDecoder.self, scope: .singleton) {
            self.mockJWT
        }

        container.register(BiometricAuthService.self, scope: .singleton) {
            self.mockBiometric
        }

        container.register(TokenRefreshCoordinator.self, scope: .singleton) {
            TokenRefreshCoordinator(
                apiClient: self.mockAPI,
                keychainService: self.mockKeychain,
                jwtDecoder: self.mockJWT
            )
        }

        container.register(AuthRepository.self, scope: .singleton) {
            AuthRepositoryImpl(
                apiClient: self.mockAPI,
                keychainService: self.mockKeychain,
                jwtDecoder: self.mockJWT,
                tokenCoordinator: container.resolve(TokenRefreshCoordinator.self),
                biometricService: self.mockBiometric,
                authMode: .realAPI // Siempre usar Real API en tests
            )
        }

        container.register(InputValidator.self, scope: .singleton) {
            DefaultInputValidator()
        }

        // Use Cases
        container.register(LoginUseCase.self) {
            DefaultLoginUseCase(
                authRepository: container.resolve(AuthRepository.self),
                validator: container.resolve(InputValidator.self)
            )
        }

        container.register(LogoutUseCase.self) {
            DefaultLogoutUseCase(
                authRepository: container.resolve(AuthRepository.self)
            )
        }

        container.register(GetCurrentUserUseCase.self) {
            DefaultGetCurrentUserUseCase(
                authRepository: container.resolve(AuthRepository.self)
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
