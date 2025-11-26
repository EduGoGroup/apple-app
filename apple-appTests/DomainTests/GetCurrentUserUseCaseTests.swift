//
//  GetCurrentUserUseCaseTests.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Testing
import Foundation
import SwiftUI
@testable import apple_app

@MainActor
@Suite("GetCurrentUserUseCase Tests")
struct GetCurrentUserUseCaseTests {
    @Test("Get current user should succeed when session is active")
    func testGetCurrentUserWithActiveSession() async throws {
        // Given
        let mockRepository = MockAuthRepository()
        mockRepository.hasActiveSessionResult = true
        mockRepository.getCurrentUserResult = .success(User.mock)
        let sut = DefaultGetCurrentUserUseCase(authRepository: mockRepository)
        
        // When
        let result = await sut.execute()
        
        // Then
        switch result {
        case .success(let user):
            #expect(user == User.mock)
            #expect(mockRepository.hasActiveSessionCallCount == 1)
            #expect(mockRepository.getCurrentUserCallCount == 1)
        case .failure:
            Issue.record("Expected success")
        }
    }
    
    @Test("Get current user should fail when no active session")
    func testGetCurrentUserWithoutActiveSession() async throws {
        // Given
        let mockRepository = MockAuthRepository()
        mockRepository.hasActiveSessionResult = false
        let sut = DefaultGetCurrentUserUseCase(authRepository: mockRepository)
        
        // When
        let result = await sut.execute()
        
        // Then
        #expect(result == .failure(.business(.sessionExpired)))
        #expect(mockRepository.hasActiveSessionCallCount == 1)
        #expect(mockRepository.getCurrentUserCallCount == 0)
    }
    
    @Test("Get current user should refresh session on unauthorized")
    func testGetCurrentUserRefreshesOnUnauthorized() async throws {
        // Given
        let mockRepository = MockAuthRepository()
        mockRepository.hasActiveSessionResult = true
        mockRepository.getCurrentUserResult = .failure(.network(.unauthorized))
        mockRepository.refreshSessionResult = .success(User.mock)
        let sut = DefaultGetCurrentUserUseCase(authRepository: mockRepository)
        
        // When
        let result = await sut.execute()
        
        // Then
        switch result {
        case .success(let user):
            #expect(user == User.mock)
            #expect(mockRepository.getCurrentUserCallCount == 1)
            #expect(mockRepository.refreshSessionCallCount == 1)
        case .failure:
            Issue.record("Expected success after refresh")
        }
    }
    
    @Test("Get current user should propagate other errors")
    func testGetCurrentUserPropagatesErrors() async throws {
        // Given
        let mockRepository = MockAuthRepository()
        mockRepository.hasActiveSessionResult = true
        mockRepository.getCurrentUserResult = .failure(.network(.noConnection))
        let sut = DefaultGetCurrentUserUseCase(authRepository: mockRepository)
        
        // When
        let result = await sut.execute()
        
        // Then
        #expect(result == .failure(.network(.noConnection)))
        #expect(mockRepository.refreshSessionCallCount == 0)
    }
    
    @Test("Get current user should not refresh on non-auth errors")
    func testGetCurrentUserDoesNotRefreshOnNonAuthErrors() async throws {
        // Given
        let mockRepository = MockAuthRepository()
        mockRepository.hasActiveSessionResult = true
        mockRepository.getCurrentUserResult = .failure(.network(.serverError(500)))
        let sut = DefaultGetCurrentUserUseCase(authRepository: mockRepository)
        
        // When
        let result = await sut.execute()
        
        // Then
        #expect(result == .failure(.network(.serverError(500))))
        #expect(mockRepository.refreshSessionCallCount == 0)
    }
}
