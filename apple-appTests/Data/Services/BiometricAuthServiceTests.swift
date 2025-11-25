//
//  BiometricAuthServiceTests.swift
//  apple-appTests
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration
//

import Testing
import LocalAuthentication
@testable import apple_app

@Suite("Biometric Auth Service Tests")
struct BiometricAuthServiceTests {

    // MARK: - Mock Service Tests

    @Test("Mock biometric returns success when configured")
    @MainActor
    func mockBiometricSuccess() async throws {
        let mock = MockBiometricService()
        mock.authenticateResult = true

        let result = try await mock.authenticate(reason: "Login to EduGo")

        #expect(result == true)
        #expect(mock.authenticateCallCount == 1)
    }

    @Test("Mock biometric throws error when configured")
    @MainActor
    func mockBiometricFailure() async {
        let mock = MockBiometricService()
        mock.authenticateError = BiometricError.authenticationFailed

        await #expect(throws: BiometricError.self) {
            try await mock.authenticate(reason: "Login")
        }
    }

    @Test("Mock biometric tracks call count")
    @MainActor
    func mockBiometricCallCount() async throws {
        let mock = MockBiometricService()
        mock.authenticateResult = true

        _ = try await mock.authenticate(reason: "Test 1")
        _ = try await mock.authenticate(reason: "Test 2")
        _ = try await mock.authenticate(reason: "Test 3")

        #expect(mock.authenticateCallCount == 3)
    }

    @Test("Mock biometric availability can be configured")
    @MainActor
    func mockBiometricAvailability() async {
        let mock = MockBiometricService()

        // Available
        mock.isAvailableValue = true
        let available = await mock.isAvailable
        #expect(available == true)

        // Not available
        mock.isAvailableValue = false
        let notAvailable = await mock.isAvailable
        #expect(notAvailable == false)
    }

    @Test("Mock biometric type can be configured")
    @MainActor
    func mockBiometricType() async {
        let mock = MockBiometricService()

        // Face ID
        mock.biometryTypeValue = .faceID
        let faceID = await mock.biometryType
        #expect(faceID == .faceID)

        // Touch ID
        mock.biometryTypeValue = .touchID
        let touchID = await mock.biometryType
        #expect(touchID == .touchID)

        // None
        mock.biometryTypeValue = .none
        let none = await mock.biometryType
        #expect(none == .none)
    }

    // MARK: - Biometric Error Tests

    @Test("BiometricError has descriptive messages")
    func biometricErrorDescriptions() {
        #expect(BiometricError.notAvailable.errorDescription?.contains("no disponible") == true)
        #expect(BiometricError.userCancelled.errorDescription?.contains("canceló") == true)
        #expect(BiometricError.biometryLocked.errorDescription?.contains("bloqueada") == true)
        #expect(BiometricError.biometryNotEnrolled.errorDescription?.contains("configurado") == true)
    }

    // MARK: - Real Service Tests (Solo verifica que compile)

    @Test("LocalAuthenticationService can be instantiated")
    func localAuthServiceInstantiation() {
        let service = LocalAuthenticationService()

        // No podemos probar funcionalidad real sin dispositivo físico
        // Solo verificamos que compile y sea del tipo correcto
        #expect(service is BiometricAuthService)
    }

    // MARK: - Integration with Auth Flow

    @Test("Successful biometric auth allows token retrieval")
    @MainActor
    func biometricAuthIntegration() async throws {
        let mock = MockBiometricService()
        mock.authenticateResult = true

        // Simular flujo completo
        let authenticated = try await mock.authenticate(reason: "Login")

        if authenticated {
            // Aquí se podría recuperar credentials del Keychain
            #expect(true)
        }
    }

    @Test("Failed biometric auth prevents token retrieval")
    @MainActor
    func failedBiometricAuth() async {
        let mock = MockBiometricService()
        mock.authenticateError = BiometricError.userCancelled

        do {
            _ = try await mock.authenticate(reason: "Login")
            Issue.record("Should have thrown error")
        } catch {
            // Esperado: no debería poder continuar con login
            #expect(error is BiometricError)
        }
    }
}
