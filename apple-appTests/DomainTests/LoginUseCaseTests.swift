//
//  LoginUseCaseTests.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Testing
import Foundation
import SwiftUI
@testable import apple_app

@MainActor
@Suite("LoginUseCase Tests")
struct LoginUseCaseTests {
    @Test("Login with valid credentials should succeed")
    func testLoginWithValidCredentials() async throws {
        // Given
        let mockRepository = MockAuthRepository()
        mockRepository.loginResult = .success(User.mock)
        let sut = DefaultLoginUseCase(authRepository: mockRepository)
        
        // When
        let result = await sut.execute(email: "test@test.com", password: "123456")
        
        // Then
        switch result {
        case .success(let user):
            #expect(user == User.mock)
            #expect(mockRepository.loginCallCount == 1)
            #expect(mockRepository.lastLoginEmail == "test@test.com")
        case .failure:
            Issue.record("Expected success")
        }
    }
    
    @Test("Login with empty email should fail")
    func testLoginWithEmptyEmail() async throws {
        // Given
        let mockRepository = MockAuthRepository()
        let sut = DefaultLoginUseCase(authRepository: mockRepository)
        
        // When
        let result = await sut.execute(email: "", password: "123456")
        
        // Then
        #expect(result == .failure(.validation(.emptyEmail)))
        #expect(mockRepository.loginCallCount == 0)
    }
    
    @Test("Login with invalid email format should fail")
    func testLoginWithInvalidEmailFormat() async throws {
        // Given
        let mockRepository = MockAuthRepository()
        let sut = DefaultLoginUseCase(authRepository: mockRepository)
        
        // When
        let result = await sut.execute(email: "invalid-email", password: "123456")
        
        // Then
        #expect(result == .failure(.validation(.invalidEmailFormat)))
        #expect(mockRepository.loginCallCount == 0)
    }
    
    @Test("Login with empty password should fail")
    func testLoginWithEmptyPassword() async throws {
        // Given
        let mockRepository = MockAuthRepository()
        let sut = DefaultLoginUseCase(authRepository: mockRepository)
        
        // When
        let result = await sut.execute(email: "test@test.com", password: "")
        
        // Then
        #expect(result == .failure(.validation(.emptyPassword)))
        #expect(mockRepository.loginCallCount == 0)
    }
    
    @Test("Login with short password should fail")
    func testLoginWithShortPassword() async throws {
        // Given
        let mockRepository = MockAuthRepository()
        let sut = DefaultLoginUseCase(authRepository: mockRepository)
        
        // When
        let result = await sut.execute(email: "test@test.com", password: "12345")
        
        // Then
        #expect(result == .failure(.validation(.passwordTooShort)))
        #expect(mockRepository.loginCallCount == 0)
    }
    
    @Test("Login should propagate repository errors")
    func testLoginPropagatesRepositoryErrors() async throws {
        // Given
        let mockRepository = MockAuthRepository()
        mockRepository.loginResult = .failure(.network(.noConnection))
        let sut = DefaultLoginUseCase(authRepository: mockRepository)
        
        // When
        let result = await sut.execute(email: "test@test.com", password: "123456")
        
        // Then
        #expect(result == .failure(.network(.noConnection)))
        #expect(mockRepository.loginCallCount == 1)
    }
    
    @Test("Login with invalid credentials from repository")
    func testLoginWithInvalidCredentialsFromRepository() async throws {
        // Given
        let mockRepository = MockAuthRepository()
        mockRepository.loginResult = .failure(.business(.invalidCredentials))
        let sut = DefaultLoginUseCase(authRepository: mockRepository)
        
        // When
        let result = await sut.execute(email: "test@test.com", password: "wrongpass")
        
        // Then
        #expect(result == .failure(.business(.invalidCredentials)))
        #expect(mockRepository.loginCallCount == 1)
    }
}
