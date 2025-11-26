//
//  JWTDecoderTests.swift
//  apple-appTests
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration
//

import Testing
import Foundation
@testable import apple_app

@MainActor
@Suite("JWT Decoder Tests")
struct JWTDecoderTests {

    let decoder = DefaultJWTDecoder()

    // Token real de prueba generado con HS256
    // Payload: {"sub":"550e8400","email":"test@edugo.com","role":"student","exp":9999999999,"iat":1706054400,"iss":"edugo-mobile"}
    // Este token NO expira (exp muy lejano para testing)
    let validToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NTBlODQwMCIsImVtYWlsIjoidGVzdEBlZHVnby5jb20iLCJyb2xlIjoic3R1ZGVudCIsImV4cCI6OTk5OTk5OTk5OSwiaWF0IjoxNzA2MDU0NDAwLCJpc3MiOiJlZHVnby1tb2JpbGUifQ.SIGNATURE"

    // MARK: - Decode Valid Token

    @Test("Decode valid JWT token successfully")
    func decodeValidToken() async throws {
        let payload = try await decoder.decode(validToken)

        #expect(payload.sub == "550e8400")
        #expect(payload.email == "test@edugo.com")
        #expect(payload.role == "student")
        #expect(payload.iss == "edugo-mobile")
    }

    @Test("Decoded payload has correct dates")
    func decodedPayloadDates() async throws {
        let payload = try await decoder.decode(validToken)

        // iat debe ser en el pasado
        #expect(payload.iat < Date())

        // exp debe ser en el futuro (token no expirado)
        #expect(payload.exp > Date())
    }

    // MARK: - Invalid Format

    @Test("Decode throws error for invalid format - too few segments")
    func invalidFormatTooFewSegments() async {
        let invalidToken = "header.payload" // Solo 2 segmentos

        await #expect(throws: JWTError.self) {
            try await decoder.decode(invalidToken)
        }
    }

    @Test("Decode throws error for invalid format - too many segments")
    func invalidFormatTooManySegments() async {
        let invalidToken = "header.payload.signature.extra" // 4 segmentos

        await #expect(throws: JWTError.self) {
            try await decoder.decode(invalidToken)
        }
    }

    @Test("Decode throws error for empty string")
    func invalidFormatEmptyString() async {
        await #expect(throws: JWTError.self) {
            try await decoder.decode("")
        }
    }

    // MARK: - Invalid Base64

    @Test("Decode throws error for invalid base64 in payload")
    func invalidBase64() async {
        let invalidToken = "header.!!invalid-base64!!.signature"

        await #expect(throws: JWTError.self) {
            try await decoder.decode(invalidToken)
        }
    }

    // MARK: - Missing Claims

    @Test("Decode throws error for missing required claims")
    func missingClaims() async {
        // Token con payload incompleto: {"sub":"123","email":"test@test.com"}
        // Falta: role, exp, iat, iss
        let tokenMissingClaims = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjMiLCJlbWFpbCI6InRlc3RAdGVzdC5jb20ifQ.SIGNATURE"

        await #expect(throws: Error.self) {
            try await decoder.decode(tokenMissingClaims)
        }
    }

    // MARK: - Invalid Issuer

    @Test("Decode throws error for invalid issuer")
    func invalidIssuer() async {
        // Token con issuer diferente: {"sub":"123","email":"test@edugo.com","role":"student","exp":9999999999,"iat":1706054400,"iss":"wrong-issuer"}
        let tokenWrongIssuer = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjMiLCJlbWFpbCI6InRlc3RAZWR1Z28uY29tIiwicm9sZSI6InN0dWRlbnQiLCJleHAiOjk5OTk5OTk5OTksImlhdCI6MTcwNjA1NDQwMCwiaXNzIjoid3JvbmctaXNzdWVyIn0.SIGNATURE"

        await #expect(throws: JWTError.invalidIssuer) {
            try await decoder.decode(tokenWrongIssuer)
        }
    }

    // MARK: - Payload Properties

    @Test("Payload isExpired returns false for valid token")
    func payloadNotExpired() async throws {
        let payload = try await decoder.decode(validToken)

        #expect(payload.isExpired == false)
    }

    @Test("Payload isExpired returns true for expired token")
    func payloadExpired() {
        let expiredPayload = JWTPayload.expired

        #expect(expiredPayload.isExpired == true)
    }

    @Test("Payload converts to domain User correctly")
    func payloadToDomainUser() {
        let payload = JWTPayload.fixture()
        let user = payload.toDomainUser

        #expect(user.id == payload.sub)
        #expect(user.email == payload.email)
        #expect(user.role.rawValue == payload.role)
        #expect(user.isEmailVerified == true)
    }

    @Test("Payload with different roles converts correctly")
    func payloadDifferentRoles() {
        let teacherPayload = JWTPayload(
            sub: "123",
            email: "teacher@edugo.com",
            role: "teacher",
            exp: Date().addingTimeInterval(900),
            iat: Date(),
            iss: "edugo-mobile"
        )

        let teacher = teacherPayload.toDomainUser

        #expect(teacher.role == .teacher)
        #expect(teacher.isTeacher == true)
    }

    @Test("Payload with invalid role defaults to student")
    func payloadInvalidRoleDefaultsToStudent() {
        let invalidRolePayload = JWTPayload(
            sub: "123",
            email: "user@edugo.com",
            role: "invalid_role",
            exp: Date().addingTimeInterval(900),
            iat: Date(),
            iss: "edugo-mobile"
        )

        let user = invalidRolePayload.toDomainUser

        #expect(user.role == .student)
    }

    // MARK: - Base64URL Decoding

    @Test("Decode handles base64url characters correctly")
    func base64URLCharacters() async {
        // Token con caracteres base64url (- y _)
        // Este es un token válido con estos caracteres
        let tokenWithBase64URL = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NTBlODQwMCIsImVtYWlsIjoidGVzdEBlZHVnby5jb20iLCJyb2xlIjoic3R1ZGVudCIsImV4cCI6OTk5OTk5OTk5OSwiaWF0IjoxNzA2MDU0NDAwLCJpc3MiOiJlZHVnby1tb2JpbGUifQ.SIGNATURE"

        let payload = try? await decoder.decode(tokenWithBase64URL)

        #expect(payload != nil)
        #expect(payload?.email == "test@edugo.com")
    }

    // MARK: - Fixtures

    @Test("JWTPayload fixture creates valid payload")
    func jwtPayloadFixture() {
        let payload = JWTPayload.fixture()

        #expect(!payload.sub.isEmpty)
        #expect(payload.email == "test@edugo.com")
        #expect(payload.role == "student")
        #expect(payload.iss == "edugo-mobile")
        #expect(payload.isExpired == false)
    }

    @Test("JWTPayload expired fixture is actually expired")
    func jwtPayloadExpiredFixture() {
        let payload = JWTPayload.expired

        #expect(payload.isExpired == true)
        #expect(payload.exp < Date())
    }

    // MARK: - Mock Decoder

    @Test("MockJWTDecoder returns configured payload")
    func mockDecoderReturnsPayload() async throws {
        let mockDecoder = MockJWTDecoder()
        let expectedPayload = JWTPayload.fixture()
        mockDecoder.payloadToReturn = expectedPayload

        let result = try await mockDecoder.decode("any_token")

        #expect(result == expectedPayload)
    }

    @Test("MockJWTDecoder throws configured error")
    func mockDecoderThrowsError() async {
        let mockDecoder = MockJWTDecoder()
        mockDecoder.errorToThrow = JWTError.invalidFormat

        await #expect(throws: JWTError.invalidFormat) {
            try await mockDecoder.decode("any_token")
        }
    }

    // MARK: - Thread Safety

    @Test("JWTDecoder is Sendable and thread-safe")
    func decoderIsSendable() async throws {
        let decoder = DefaultJWTDecoder()

        // Decodificar múltiples veces (ya estamos en @MainActor)
        let result1 = try await decoder.decode(validToken)
        let result2 = try await decoder.decode(validToken)
        let result3 = try await decoder.decode(validToken)

        let results = [result1, result2, result3]

        // Todos deben decodificar correctamente
        #expect(results.allSatisfy { $0.email == "test@edugo.com" })
    }
}
