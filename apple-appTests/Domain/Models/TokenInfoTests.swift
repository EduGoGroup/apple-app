//
//  TokenInfoTests.swift
//  apple-appTests
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration
//

import Testing
import Foundation
@testable import apple_app

@MainActor
@Suite("TokenInfo Tests")
struct TokenInfoTests {

    @Test("Token is expired when past expiration date")
    func tokenIsExpired() {
        let token = TokenInfo.expired
        #expect(token.isExpired == true)
    }

    @Test("Token is not expired when before expiration date")
    func tokenIsNotExpired() {
        let token = TokenInfo.fresh
        #expect(token.isExpired == false)
    }

    @Test("Token needs refresh when expires in less than 5 minutes")
    func tokenNeedsRefresh() {
        let token = TokenInfo.needingRefresh
        #expect(token.needsRefresh == true)
    }

    @Test("Fresh token does not need refresh")
    func freshTokenDoesNotNeedRefresh() {
        let token = TokenInfo.fresh
        #expect(token.needsRefresh == false)
    }

    @Test("Time until expiration is calculated correctly")
    func timeUntilExpiration() {
        let token = TokenInfo.fresh

        // Debería tener aproximadamente 15 minutos (900 segundos)
        #expect(token.timeUntilExpiration > 890)
        #expect(token.timeUntilExpiration <= 900)
    }

    @Test("Expired token has zero time until expiration")
    func expiredTokenHasZeroTime() {
        let token = TokenInfo.expired
        // timeUntilExpiration usa max(0, ...) por lo que nunca es negativo
        #expect(token.timeUntilExpiration == 0)
    }

    @Test("Remaining life percentage for fresh token is near 100%")
    func freshTokenLifePercentage() {
        let token = TokenInfo.fresh

        // Debería estar cerca de 1.0 (100%)
        #expect(token.remainingLifePercentage > 0.95)
        #expect(token.remainingLifePercentage <= 1.0)
    }

    @Test("Remaining life percentage for expired token is 0%")
    func expiredTokenLifePercentage() {
        let token = TokenInfo.expired
        #expect(token.remainingLifePercentage == 0.0)
    }

    @Test("Create token from expiresIn seconds")
    func createFromExpiresIn() {
        let token = TokenInfo(
            accessToken: "token",
            refreshToken: "refresh",
            expiresIn: 900
        )

        // Debería expirar en aproximadamente 900 segundos
        #expect(token.timeUntilExpiration > 890)
        #expect(token.timeUntilExpiration <= 900)
    }

    @Test("Create token from specific expiration date")
    func createFromExpiresAt() {
        let expiresAt = Date().addingTimeInterval(1800) // 30 minutos
        let token = TokenInfo(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: expiresAt
        )

        #expect(token.expiresAt == expiresAt)
        #expect(token.timeUntilExpiration > 1790)
        #expect(token.timeUntilExpiration <= 1800)
    }

    @Test("TokenInfo is Equatable")
    func equatable() {
        // Para que sean iguales, deben tener las mismas fechas
        let fixedDate = Date()
        let expiresAt = fixedDate.addingTimeInterval(900)

        let token1 = TokenInfo(accessToken: "token1", refreshToken: "refresh", expiresAt: expiresAt, createdAt: fixedDate)
        let token2 = TokenInfo(accessToken: "token1", refreshToken: "refresh", expiresAt: expiresAt, createdAt: fixedDate)
        let token3 = TokenInfo(accessToken: "token2", refreshToken: "refresh", expiresAt: expiresAt, createdAt: fixedDate)

        #expect(token1 == token2)
        #expect(token1 != token3)
    }

    @Test("TokenInfo is Codable")
    func codable() throws {
        let original = TokenInfo.fixture()

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TokenInfo.self, from: data)

        #expect(decoded == original)
    }

    @Test("TokenInfo is Sendable (thread-safe)")
    func sendable() {
        let token = TokenInfo.fresh

        Task {
            let _ = token.isExpired // Puede usarse en async context
        }
    }

    @Test("Fixture creates valid token")
    func fixtureCreation() {
        let token = TokenInfo.fixture()

        #expect(token.accessToken == "mock_access_token")
        #expect(token.refreshToken == "mock_refresh_token")
        #expect(token.isExpired == false)
    }

    @Test("Custom fixture with parameters")
    func customFixture() {
        let token = TokenInfo.fixture(
            accessToken: "custom_token",
            refreshToken: "custom_refresh",
            expiresIn: 300 // 5 minutos
        )

        #expect(token.accessToken == "custom_token")
        #expect(token.refreshToken == "custom_refresh")
        #expect(token.timeUntilExpiration <= 300)
    }
}
