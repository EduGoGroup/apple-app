//
//  KeychainServiceTests.swift
//  apple-appTests
//
//  Created on 16-11-25.
//

import Testing
import Foundation
import SwiftUI
@testable import apple_app

// MARK: - Keychain Integration Tests (requieren Keychain real)
// Nota: Estos tests se saltan en CI/simulador donde Keychain no está disponible
// debido a falta de entitlements (errSecMissingEntitlement = -34018).
// Se ejecutan correctamente en dispositivos físicos o Xcode con host app.

@MainActor
@Suite("KeychainService Tests", .disabled("Keychain no disponible en simulador CI - requiere entitlements"))
struct KeychainServiceTests {
    let sut = DefaultKeychainService.shared
    let testKey = "test_token_key"

    // MARK: - Save Token Tests

    @Test("Guardar token exitosamente")
    func testSaveTokenSuccessfully() throws {
        // Given
        let token = "test_token_123456"

        // When
        try sut.saveToken(token, for: testKey)

        // Then
        let retrieved = try sut.getToken(for: testKey)
        #expect(retrieved == token)

        // Cleanup
        try sut.deleteToken(for: testKey)
    }

    @Test("Guardar token sobrescribe valor anterior")
    func testSaveTokenOverwritesPreviousValue() throws {
        // Given
        let firstToken = "first_token"
        let secondToken = "second_token"

        // When
        try sut.saveToken(firstToken, for: testKey)
        try sut.saveToken(secondToken, for: testKey)

        // Then
        let retrieved = try sut.getToken(for: testKey)
        #expect(retrieved == secondToken)

        // Cleanup
        try sut.deleteToken(for: testKey)
    }

    @Test("Guardar múltiples tokens con diferentes keys")
    func testSaveMultipleTokensWithDifferentKeys() throws {
        // Given
        let key1 = "test_key_1"
        let key2 = "test_key_2"
        let token1 = "token_1"
        let token2 = "token_2"

        // When
        try sut.saveToken(token1, for: key1)
        try sut.saveToken(token2, for: key2)

        // Then
        let retrieved1 = try sut.getToken(for: key1)
        let retrieved2 = try sut.getToken(for: key2)
        #expect(retrieved1 == token1)
        #expect(retrieved2 == token2)

        // Cleanup
        try sut.deleteToken(for: key1)
        try sut.deleteToken(for: key2)
    }

    // MARK: - Get Token Tests

    @Test("Obtener token que no existe retorna nil")
    func testGetNonExistentTokenReturnsNil() throws {
        // Given
        let nonExistentKey = "non_existent_key_12345"

        // When
        let result = try sut.getToken(for: nonExistentKey)

        // Then
        #expect(result == nil)
    }

    @Test("Obtener token que existe retorna el valor correcto")
    func testGetExistingTokenReturnsCorrectValue() throws {
        // Given
        let token = "my_secure_token"
        try sut.saveToken(token, for: testKey)

        // When
        let retrieved = try sut.getToken(for: testKey)

        // Then
        #expect(retrieved == token)

        // Cleanup
        try sut.deleteToken(for: testKey)
    }

    // MARK: - Delete Token Tests

    @Test("Eliminar token exitosamente")
    func testDeleteTokenSuccessfully() throws {
        // Given
        let token = "token_to_delete"
        try sut.saveToken(token, for: testKey)

        // When
        try sut.deleteToken(for: testKey)

        // Then
        let retrieved = try sut.getToken(for: testKey)
        #expect(retrieved == nil)
    }

    @Test("Eliminar token que no existe no lanza error")
    func testDeleteNonExistentTokenDoesNotThrow() throws {
        // Given
        let nonExistentKey = "key_that_does_not_exist"

        // When & Then (no debería lanzar error)
        try sut.deleteToken(for: nonExistentKey)
    }

    @Test("Eliminar token múltiples veces no lanza error")
    func testDeleteTokenMultipleTimesDoesNotThrow() throws {
        // Given
        let token = "token"
        try sut.saveToken(token, for: testKey)

        // When & Then
        try sut.deleteToken(for: testKey)
        try sut.deleteToken(for: testKey) // Segunda vez no debería fallar
    }

    // MARK: - Integration Tests

    @Test("Ciclo completo: save -> get -> delete")
    func testCompleteLifecycle() throws {
        // Given
        let token = "lifecycle_token"

        // When - Save
        try sut.saveToken(token, for: testKey)
        var retrieved = try sut.getToken(for: testKey)

        // Then - Verify saved
        #expect(retrieved == token)

        // When - Delete
        try sut.deleteToken(for: testKey)
        retrieved = try sut.getToken(for: testKey)

        // Then - Verify deleted
        #expect(retrieved == nil)
    }

    @Test("Tokens con caracteres especiales")
    func testTokensWithSpecialCharacters() throws {
        // Given
        let specialToken = "token.with-special_chars@123!#$%"

        // When
        try sut.saveToken(specialToken, for: testKey)
        let retrieved = try sut.getToken(for: testKey)

        // Then
        #expect(retrieved == specialToken)

        // Cleanup
        try sut.deleteToken(for: testKey)
    }

    @Test("Tokens largos")
    func testLongTokens() throws {
        // Given
        let longToken = String(repeating: "a", count: 1000)

        // When
        try sut.saveToken(longToken, for: testKey)
        let retrieved = try sut.getToken(for: testKey)

        // Then
        #expect(retrieved == longToken)

        // Cleanup
        try sut.deleteToken(for: testKey)
    }
}

// MARK: - KeychainError Tests

@MainActor
@Suite("KeychainError Tests")
struct KeychainErrorTests {
    @Test("KeychainError tiene mensajes descriptivos")
    func testKeychainErrorLocalizedDescriptions() {
        #expect(KeychainError.unableToSave.localizedDescription.contains("guardar"))
        #expect(KeychainError.unableToRetrieve.localizedDescription.contains("recuperar"))
        #expect(KeychainError.unableToDelete.localizedDescription.contains("eliminar"))
        #expect(KeychainError.itemNotFound.localizedDescription.contains("no existe"))
        #expect(KeychainError.invalidData.localizedDescription.contains("no son válidos"))
    }

    @Test("KeychainError es Equatable")
    func testKeychainErrorEquatable() {
        #expect(KeychainError.unableToSave == KeychainError.unableToSave)
        #expect(KeychainError.unableToSave != KeychainError.unableToRetrieve)
    }
}
