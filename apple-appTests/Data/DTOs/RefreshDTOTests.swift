//
//  RefreshDTOTests.swift
//  apple-appTests
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration
//

import Testing
import Foundation
@testable import apple_app

@MainActor
@Suite("RefreshDTO Tests")
struct RefreshDTOTests {
    // MARK: - RefreshRequest Tests

    @Test("RefreshRequest has correct properties")
    func refreshRequestProperties() {
        let request = RefreshRequest(refreshToken: "550e8400-...")

        #expect(request.refreshToken == "550e8400-...")
    }

    @Test("RefreshRequest encodes to snake_case JSON")
    func refreshRequestEncoding() throws {
        let request = RefreshRequest.fixture()

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)

        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("refresh_token"))
    }

    @Test("RefreshRequest is Codable")
    func refreshRequestCodable() throws {
        let request = RefreshRequest.fixture()

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RefreshRequest.self, from: data)

        #expect(decoded.refreshToken == request.refreshToken)
    }

    // MARK: - RefreshResponse Tests

    @Test("RefreshResponse decodes from snake_case JSON")
    func refreshResponseDecoding() throws {
        let json = """
        {
            "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.new",
            "expires_in": 900,
            "token_type": "Bearer"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(RefreshResponse.self, from: data)

        #expect(response.accessToken == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.new")
        #expect(response.expiresIn == 900)
        #expect(response.tokenType == "Bearer")
    }

    @Test("RefreshResponse updates TokenInfo correctly")
    func refreshResponseUpdatesTokenInfo() {
        let currentToken = TokenInfo.fixture(
            accessToken: "old_token",
            refreshToken: "refresh_123",
            expiresIn: 60 // Casi expirado
        )

        let response = RefreshResponse.fixture()
        let updatedToken = response.updateTokenInfo(currentToken)

        // Access token debe cambiar
        #expect(updatedToken.accessToken != currentToken.accessToken)
        #expect(updatedToken.accessToken == response.accessToken)

        // Refresh token NO debe cambiar (característica del API real)
        #expect(updatedToken.refreshToken == currentToken.refreshToken)
        #expect(updatedToken.refreshToken == "refresh_123")

        // Nueva expiración
        #expect(!updatedToken.needsRefresh)
    }

    @Test("RefreshResponse preserves refresh token")
    func refreshResponsePreservesRefreshToken() {
        let originalRefreshToken = "original_refresh_token_123"
        let currentToken = TokenInfo.fixture(refreshToken: originalRefreshToken)

        let response = RefreshResponse(
            accessToken: "new_access_token",
            expiresIn: 900,
            tokenType: "Bearer"
        )

        let updatedToken = response.updateTokenInfo(currentToken)

        // El refresh token debe permanecer igual
        #expect(updatedToken.refreshToken == originalRefreshToken)
    }

    @Test("RefreshResponse extends token lifetime")
    func refreshResponseExtendsLifetime() {
        // Token casi expirado
        let expiringToken = TokenInfo(
            accessToken: "expiring",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(60) // 1 minuto
        )

        #expect(expiringToken.needsRefresh == true)

        // Refresh
        let response = RefreshResponse(
            accessToken: "new_token",
            expiresIn: 900,
            tokenType: "Bearer"
        )

        let refreshedToken = response.updateTokenInfo(expiringToken)

        // Ahora no debe necesitar refresh
        #expect(refreshedToken.needsRefresh == false)
        #expect(refreshedToken.timeUntilExpiration > 890)
    }

    @Test("RefreshResponse fixture creates valid data")
    func refreshResponseFixture() {
        let response = RefreshResponse.fixture()

        #expect(!response.accessToken.isEmpty)
        #expect(response.expiresIn == 900)
        #expect(response.tokenType == "Bearer")
    }
}
