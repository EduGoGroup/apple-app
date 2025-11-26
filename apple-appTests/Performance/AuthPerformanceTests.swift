//
//  AuthPerformanceTests.swift
//  apple-appTests
//
//  Created on 25-11-25.
//  SPEC-007: Testing Infrastructure - Performance Tests
//

import Testing
import Foundation
@testable import apple_app

/// Tests de performance para operaciones de autenticación
/// Con Swift 6 @MainActor, los tests async heredan el contexto
@Suite("Auth Performance Tests")
@MainActor
struct AuthPerformanceTests {

    // MARK: - JWT Decoding Performance

    @Test("JWT decoding debe ser < 10ms")
    func jwtDecodingPerformance() async throws {
        let decoder = DefaultJWTDecoder()

        // Token JWT válido de prueba
        let validToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NTBlODQwMCIsImVtYWlsIjoidGVzdEBlZHVnby5jb20iLCJyb2xlIjoic3R1ZGVudCIsImV4cCI6OTk5OTk5OTk5OSwiaWF0IjoxNzA2MDU0NDAwLCJpc3MiOiJlZHVnby1jZW50cmFsIn0.SIGNATURE"

        let start = Date()

        // Ejecutar múltiples veces para promedio
        for _ in 0..<100 {
            _ = try await decoder.decode(validToken)
        }

        let elapsed = Date().timeIntervalSince(start)
        let averageTime = elapsed / 100.0 * 1000.0 // En milisegundos

        // Debe ser menor a 10ms en promedio
        #expect(averageTime < 10.0, "JWT decoding took \(averageTime)ms, expected < 10ms")
    }

    // MARK: - Token Refresh Performance

    @Test("Token refresh debe ser < 500ms")
    func tokenRefreshPerformance() async throws {
        let mockKeychain = MockKeychainService()

        // Configurar token que necesita refresh
        let mockJWT = MockJWTDecoder()
        let mockAPI = MockAPIClient()

        let expiringPayload = JWTPayload(
            sub: "123",
            email: "test@test.com",
            role: "student",
            exp: Date().addingTimeInterval(60), // Expira en 1 min
            iat: Date(),
            iss: AppEnvironment.jwtIssuer
        )
        mockJWT.payloadToReturn = expiringPayload

        mockKeychain.tokens = [
            "access_token": "expiring_token",
            "refresh_token": "refresh_123"
        ]

        mockAPI.mockResponse = RefreshResponse(
            accessToken: "new_token",
            expiresIn: 900,
            tokenType: "Bearer"
        )

        let coordinator = TokenRefreshCoordinator(
            apiClient: mockAPI,
            keychainService: mockKeychain,
            jwtDecoder: mockJWT
        )

        let start = Date()
        _ = try await coordinator.getValidToken()
        let elapsed = Date().timeIntervalSince(start) * 1000.0 // En ms

        // Debe ser menor a 500ms
        #expect(elapsed < 500.0, "Token refresh took \(elapsed)ms, expected < 500ms")
    }

    // MARK: - Keychain Performance

    // Nota: Este test usa el Keychain real que no funciona en simulador CI
    // debido a falta de entitlements (errSecMissingEntitlement = -34018)
    @Test("Keychain save/get debe ser < 50ms", .disabled("Keychain no disponible en simulador CI"))
    func keychainPerformance() async throws {
        let keychain = DefaultKeychainService.shared
        let token = "test_token_\(UUID().uuidString)"
        let key = "perf_test_\(UUID().uuidString)"

        let start = Date()

        // Save
        try await keychain.saveToken(token, for: key)

        // Get
        _ = try await keychain.getToken(for: key)

        // Delete
        try await keychain.deleteToken(for: key)

        let elapsed = Date().timeIntervalSince(start) * 1000.0 // En ms

        // Debe ser menor a 50ms
        #expect(elapsed < 50.0, "Keychain operations took \(elapsed)ms, expected < 50ms")
    }

    // MARK: - Input Validation Performance

    @Test("Input validation debe ser < 5ms")
    func inputValidationPerformance() async {
        let validator = DefaultInputValidator()
        let email = "test@edugo.com"

        let start = Date()

        // Ejecutar múltiples validaciones
        for _ in 0..<1000 {
            _ = validator.isValidEmail(email)
            _ = validator.sanitize(email)
            _ = validator.isSafeSQLInput(email)
        }

        let elapsed = Date().timeIntervalSince(start)
        let averageTime = elapsed / 1000.0 * 1000.0 // En ms

        // Debe ser menor a 5ms por validación
        #expect(averageTime < 5.0, "Input validation took \(averageTime)ms, expected < 5ms")
    }
}
