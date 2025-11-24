//
//  AuthPerformanceTests.swift
//  apple-appTests
//
//  Created on 24-01-25.
//  SPEC-007: Testing Infrastructure - Performance Tests
//

import Testing
import Foundation
@testable import apple_app

@Suite("Auth Performance Tests")
struct AuthPerformanceTests {

    let validToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NTBlODQwMCIsImVtYWlsIjoidGVzdEBlZHVnby5jb20iLCJyb2xlIjoic3R1ZGVudCIsImV4cCI6OTk5OTk5OTk5OSwiaWF0IjoxNzA2MDU0NDAwLCJpc3MiOiJlZHVnby1tb2JpbGUifQ.SIGNATURE"

    @Test("JWT decoding performance - should be < 10ms")
    func jwtDecodingPerformance() async throws {
        let decoder = DefaultJWTDecoder()

        let start = Date()

        // Decodificar 100 veces
        for _ in 0..<100 {
            _ = try decoder.decode(validToken)
        }

        let duration = Date().timeIntervalSince(start)
        let avgDuration = duration / 100

        // Promedio debe ser < 10ms
        #expect(avgDuration < 0.01, "JWT decode took \(avgDuration * 1000)ms, expected < 10ms")
    }

    @Test("TokenInfo validation performance")
    func tokenInfoValidation() {
        let token = TokenInfo.fixture()

        let start = Date()

        // Validar 10,000 veces
        for _ in 0..<10_000 {
            _ = token.isExpired
            _ = token.needsRefresh
        }

        let duration = Date().timeIntervalSince(start)

        // Debe completar en < 100ms
        #expect(duration < 0.1, "Validation took \(duration * 1000)ms, expected < 100ms")
    }

    @Test("User role helpers performance")
    func userRoleHelpers() {
        let user = MockFactory.makeStudent()

        let start = Date()

        // Verificar 10,000 veces
        for _ in 0..<10_000 {
            _ = user.isStudent
            _ = user.isTeacher
            _ = user.isAdmin
        }

        let duration = Date().timeIntervalSince(start)

        // Debe completar en < 50ms
        #expect(duration < 0.05, "Role helpers took \(duration * 1000)ms, expected < 50ms")
    }

    @Test("UserBuilder performance")
    func userBuilderPerformance() {
        let start = Date()

        // Crear 1,000 usuarios con builder
        for i in 0..<1_000 {
            _ = UserBuilder()
                .withEmail("user\(i)@test.com")
                .withDisplayName("User \(i)")
                .asStudent()
                .build()
        }

        let duration = Date().timeIntervalSince(start)

        // Debe completar en < 500ms
        #expect(duration < 0.5, "Builder took \(duration * 1000)ms, expected < 500ms")
    }

    @Test("MockFactory performance")
    func mockFactoryPerformance() {
        let start = Date()

        // Crear 1,000 objetos via factory
        for _ in 0..<1_000 {
            _ = MockFactory.makeUser()
            _ = MockFactory.makeTokenInfo()
            _ = MockFactory.makeJWTPayload()
        }

        let duration = Date().timeIntervalSince(start)

        // Debe completar en < 200ms
        #expect(duration < 0.2, "Factory took \(duration * 1000)ms, expected < 200ms")
    }
}
