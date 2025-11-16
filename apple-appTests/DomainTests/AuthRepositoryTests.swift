//
//  AuthRepositoryTests.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Testing
@testable import apple_app

@Suite("AuthRepository Protocol Tests")
struct AuthRepositoryTests {
    
    @Test("MockAuthRepository should track login calls")
    func testLoginTracking() async throws {
        // Given
        let mock = MockAuthRepository()
        mock.loginResult = .success(User.mock)
        
        // When
        let result = await mock.login(email: "test@test.com", password: "password123")
        
        // Then
        #expect(mock.loginCallCount == 1)
        #expect(mock.lastLoginEmail == "test@test.com")
        #expect(mock.lastLoginPassword == "password123")
        
        switch result {
        case .success(let user):
            #expect(user == User.mock)
        case .failure:
            Issue.record("Expected success")
        }
    }
    
    @Test("MockAuthRepository should return configured login result")
    func testLoginResult() async throws {
        // Given
        let mock = MockAuthRepository()
        let expectedError = AppError.validation(.emptyEmail)
        mock.loginResult = .failure(expectedError)
        
        // When
        let result = await mock.login(email: "", password: "")
        
        // Then
        switch result {
        case .success:
            Issue.record("Expected failure")
        case .failure(let error):
            #expect(error == expectedError)
        }
    }
    
    @Test("MockAuthRepository should track logout calls")
    func testLogoutTracking() async throws {
        // Given
        let mock = MockAuthRepository()
        mock.logoutResult = .success(())
        
        // When
        let result = await mock.logout()
        
        // Then
        #expect(mock.logoutCallCount == 1)
        
        switch result {
        case .success:
            break // Expected
        case .failure:
            Issue.record("Expected success")
        }
    }
    
    @Test("MockAuthRepository should track getCurrentUser calls")
    func testGetCurrentUserTracking() async throws {
        // Given
        let mock = MockAuthRepository()
        mock.getCurrentUserResult = .success(User.mock)
        
        // When
        _ = await mock.getCurrentUser()
        
        // Then
        #expect(mock.getCurrentUserCallCount == 1)
    }
    
    @Test("MockAuthRepository should track refreshSession calls")
    func testRefreshSessionTracking() async throws {
        // Given
        let mock = MockAuthRepository()
        mock.refreshSessionResult = .success(User.mock)
        
        // When
        _ = await mock.refreshSession()
        
        // Then
        #expect(mock.refreshSessionCallCount == 1)
    }
    
    @Test("MockAuthRepository should track hasActiveSession calls")
    func testHasActiveSessionTracking() async throws {
        // Given
        let mock = MockAuthRepository()
        mock.hasActiveSessionResult = true
        
        // When
        let hasSession = await mock.hasActiveSession()
        
        // Then
        #expect(mock.hasActiveSessionCallCount == 1)
        #expect(hasSession == true)
    }
    
    @Test("MockAuthRepository reset should clear all state")
    func testReset() async throws {
        // Given
        let mock = MockAuthRepository()
        _ = await mock.login(email: "test@test.com", password: "pass")
        _ = await mock.logout()
        
        // When
        mock.reset()
        
        // Then
        #expect(mock.loginCallCount == 0)
        #expect(mock.logoutCallCount == 0)
        #expect(mock.getCurrentUserCallCount == 0)
        #expect(mock.refreshSessionCallCount == 0)
        #expect(mock.hasActiveSessionCallCount == 0)
        #expect(mock.lastLoginEmail == nil)
        #expect(mock.lastLoginPassword == nil)
    }
    
    @Test("Multiple login calls should accumulate count")
    func testMultipleLoginCalls() async throws {
        // Given
        let mock = MockAuthRepository()
        mock.loginResult = .success(User.mock)
        
        // When
        _ = await mock.login(email: "user1@test.com", password: "pass1")
        _ = await mock.login(email: "user2@test.com", password: "pass2")
        _ = await mock.login(email: "user3@test.com", password: "pass3")
        
        // Then
        #expect(mock.loginCallCount == 3)
        #expect(mock.lastLoginEmail == "user3@test.com")
        #expect(mock.lastLoginPassword == "pass3")
    }
}
