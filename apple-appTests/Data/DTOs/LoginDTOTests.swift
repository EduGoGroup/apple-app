//
//  LoginDTOTests.swift
//  apple-appTests
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration
//

import Testing
import Foundation
@testable import apple_app

@Suite("LoginDTO Tests")
struct LoginDTOTests {

    // MARK: - LoginRequest Tests

    @Test("LoginRequest has correct properties")
    func loginRequestProperties() {
        let request = LoginRequest(email: "test@edugo.com", password: "password123")

        #expect(request.email == "test@edugo.com")
        #expect(request.password == "password123")
    }

    @Test("LoginRequest is Codable")
    func loginRequestCodable() throws {
        let request = LoginRequest.fixture()

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LoginRequest.self, from: data)

        #expect(decoded.email == request.email)
        #expect(decoded.password == request.password)
    }

    // MARK: - LoginResponse Tests

    @Test("LoginResponse decodes from snake_case JSON")
    func loginResponseDecoding() throws {
        let json = """
        {
            "access_token": "eyJhbGc...",
            "refresh_token": "550e8400-...",
            "expires_in": 900,
            "token_type": "Bearer",
            "user": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "email": "test@edugo.com",
                "first_name": "Juan",
                "last_name": "Pérez",
                "full_name": "Juan Pérez",
                "role": "student"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(LoginResponse.self, from: data)

        #expect(response.accessToken == "eyJhbGc...")
        #expect(response.refreshToken == "550e8400-...")
        #expect(response.expiresIn == 900)
        #expect(response.tokenType == "Bearer")
        #expect(response.user.email == "test@edugo.com")
    }

    @Test("LoginResponse converts to TokenInfo")
    func loginResponseToTokenInfo() {
        let response = LoginResponse.fixture()
        let tokenInfo = response.toTokenInfo()

        #expect(tokenInfo.accessToken == response.accessToken)
        #expect(tokenInfo.refreshToken == response.refreshToken)
        #expect(!tokenInfo.isExpired)
    }

    @Test("LoginResponse converts to User domain")
    func loginResponseToDomain() {
        let response = LoginResponse.fixture()
        let user = response.toDomain()

        #expect(user.email == "test@edugo.com")
        #expect(user.displayName == "Juan Pérez")
        #expect(user.role == .student)
    }

    // MARK: - UserDTO Tests

    @Test("UserDTO decodes from snake_case JSON")
    func userDTODecoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "email": "test@edugo.com",
            "first_name": "Juan",
            "last_name": "Pérez",
            "full_name": "Juan Pérez",
            "role": "student"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let userDTO = try decoder.decode(UserDTO.self, from: data)

        #expect(userDTO.id == "550e8400-e29b-41d4-a716-446655440000")
        #expect(userDTO.email == "test@edugo.com")
        #expect(userDTO.firstName == "Juan")
        #expect(userDTO.lastName == "Pérez")
        #expect(userDTO.fullName == "Juan Pérez")
        #expect(userDTO.role == "student")
    }

    @Test("UserDTO converts to User domain entity")
    func userDTOToDomain() {
        let dto = UserDTO.fixture()
        let user = dto.toDomain()

        #expect(user.id == dto.id)
        #expect(user.email == dto.email)
        #expect(user.displayName == dto.fullName)
        #expect(user.role == .student)
        #expect(user.isEmailVerified == true)
    }

    @Test("UserDTO handles different roles")
    func userDTODifferentRoles() {
        let teacherDTO = UserDTO.teacherFixture()
        let teacher = teacherDTO.toDomain()

        #expect(teacher.role == .teacher)
        #expect(teacher.isTeacher == true)
    }

    @Test("UserDTO handles invalid role gracefully")
    func userDTOInvalidRole() {
        let dto = UserDTO(
            id: "123",
            email: "test@test.com",
            firstName: "Test",
            lastName: "User",
            fullName: "Test User",
            role: "invalid_role"
        )

        let user = dto.toDomain()

        // Debe caer a .student por defecto
        #expect(user.role == .student)
    }

    @Test("LoginResponse fixture creates valid data")
    func loginResponseFixture() {
        let response = LoginResponse.fixture()

        #expect(!response.accessToken.isEmpty)
        #expect(!response.refreshToken.isEmpty)
        #expect(response.expiresIn == 900)
        #expect(response.tokenType == "Bearer")
        #expect(response.user.email == "test@edugo.com")
    }
}
