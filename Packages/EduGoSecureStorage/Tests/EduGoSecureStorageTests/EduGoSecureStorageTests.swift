//
//  EduGoSecureStorageTests.swift
//  EduGoSecureStorage
//
//  Created on 30-11-25.
//

import Testing
import Foundation
import LocalAuthentication
@testable import EduGoSecureStorage

@Suite("EduGoSecureStorage Tests")
struct EduGoSecureStorageTests {

    // MARK: - KeychainError Tests

    @Test("KeychainError cases have correct descriptions")
    func keychainErrorDescriptions() {
        #expect(KeychainError.unableToSave.localizedDescription.contains("guardar"))
        #expect(KeychainError.unableToRetrieve.localizedDescription.contains("recuperar"))
        #expect(KeychainError.unableToDelete.localizedDescription.contains("eliminar"))
        #expect(KeychainError.itemNotFound.localizedDescription.contains("no existe"))
        #expect(KeychainError.invalidData.localizedDescription.contains("válidos"))
    }

    @Test("KeychainError is Equatable")
    func keychainErrorEquatable() {
        #expect(KeychainError.unableToSave == KeychainError.unableToSave)
        #expect(KeychainError.unableToSave != KeychainError.invalidData)
    }

    // MARK: - BiometricError Tests

    @Test("BiometricError cases have correct descriptions")
    func biometricErrorDescriptions() {
        #expect(BiometricError.notAvailable.errorDescription?.contains("no disponible") == true)
        #expect(BiometricError.authenticationFailed.errorDescription?.contains("falló") == true)
        #expect(BiometricError.userCancelled.errorDescription?.contains("canceló") == true)
        #expect(BiometricError.biometryLocked.errorDescription?.contains("bloqueada") == true)
        #expect(BiometricError.biometryNotEnrolled.errorDescription?.contains("configurado") == true)
        #expect(BiometricError.passcodeNotSet.errorDescription?.contains("código") == true)
    }

    // MARK: - MockKeychainService Tests

    #if DEBUG
    @Test("MockKeychainService save and get token")
    func mockKeychainSaveAndGet() async throws {
        let mock = MockKeychainService()

        try await mock.saveToken("test-token", for: "test-key")
        let retrieved = try await mock.getToken(for: "test-key")

        #expect(retrieved == "test-token")
        #expect(await mock.saveCallCount == 1)
        #expect(await mock.getCallCount == 1)
    }

    @Test("MockKeychainService delete token")
    func mockKeychainDelete() async throws {
        let mock = MockKeychainService()

        try await mock.saveToken("test-token", for: "test-key")
        try await mock.deleteToken(for: "test-key")
        let retrieved = try await mock.getToken(for: "test-key")

        #expect(retrieved == nil)
        #expect(await mock.deleteCallCount == 1)
    }

    @Test("MockKeychainService throws configured error")
    func mockKeychainThrowsError() async {
        let mock = MockKeychainService()
        await mock.setShouldThrowError(.invalidData)

        do {
            try await mock.saveToken("token", for: "key")
            Issue.record("Expected error to be thrown")
        } catch let error as KeychainError {
            #expect(error == .invalidData)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("MockKeychainService reset clears state")
    func mockKeychainReset() async throws {
        let mock = MockKeychainService()

        try await mock.saveToken("token", for: "key")
        await mock.reset()

        let retrieved = try await mock.getToken(for: "key")
        #expect(retrieved == nil)
        #expect(await mock.saveCallCount == 0)
    }

    // MARK: - MockBiometricService Tests

    @Test("MockBiometricService returns configured values")
    @MainActor
    func mockBiometricValues() async {
        let mock = MockBiometricService()
        mock.isAvailableValue = true
        mock.biometryTypeValue = .faceID

        let isAvailable = await mock.isAvailable
        let biometryType = await mock.biometryType

        #expect(isAvailable == true)
        #expect(biometryType == .faceID)
    }

    @Test("MockBiometricService authenticate succeeds")
    @MainActor
    func mockBiometricAuthenticateSuccess() async throws {
        let mock = MockBiometricService()
        mock.authenticateResult = true

        let result = try await mock.authenticate(reason: "Test")

        #expect(result == true)
        #expect(mock.authenticateCallCount == 1)
    }

    @Test("MockBiometricService authenticate throws error")
    @MainActor
    func mockBiometricAuthenticateError() async {
        let mock = MockBiometricService()
        mock.authenticateError = BiometricError.userCancelled

        do {
            _ = try await mock.authenticate(reason: "Test")
            Issue.record("Expected error to be thrown")
        } catch let error as BiometricError {
            #expect(error == .userCancelled)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("MockBiometricService reset clears state")
    @MainActor
    func mockBiometricReset() async throws {
        let mock = MockBiometricService()
        mock.isAvailableValue = false
        mock.authenticateCallCount = 5

        mock.reset()

        #expect(mock.isAvailableValue == true)
        #expect(mock.authenticateCallCount == 0)
    }
    #endif
}

// MARK: - Helper extension for MockKeychainService

#if DEBUG
extension MockKeychainService {
    func setShouldThrowError(_ error: KeychainError?) async {
        shouldThrowError = error
    }
}
#endif
