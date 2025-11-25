//
//  LogoutUseCaseTests.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Testing
import Foundation
import SwiftUI
@testable import apple_app

@MainActor
@Suite("LogoutUseCase Tests")
struct LogoutUseCaseTests {
    
    @Test("Logout should succeed when repository succeeds")
    func testLogoutSuccess() async throws {
        // Given
        let mockRepository = MockAuthRepository()
        mockRepository.logoutResult = .success(())
        let sut = DefaultLogoutUseCase(authRepository: mockRepository)
        
        // When
        let result = await sut.execute()
        
        // Then
        switch result {
        case .success:
            #expect(mockRepository.logoutCallCount == 1)
        case .failure:
            Issue.record("Expected success")
        }
    }
    
    @Test("Logout should propagate repository errors")
    func testLogoutPropagatesErrors() async throws {
        // Given
        let mockRepository = MockAuthRepository()
        mockRepository.logoutResult = .failure(.network(.noConnection))
        let sut = DefaultLogoutUseCase(authRepository: mockRepository)
        
        // When
        let result = await sut.execute()
        
        // Then
        switch result {
        case .success:
            Issue.record("Expected failure")
        case .failure(let error):
            if case .network(.noConnection) = error {
                #expect(mockRepository.logoutCallCount == 1)
            } else {
                Issue.record("Expected network error, got \(error)")
            }
        }
    }
    
    @Test("Multiple logout calls should accumulate count")
    func testMultipleLogoutCalls() async throws {
        // Given
        let mockRepository = MockAuthRepository()
        mockRepository.logoutResult = .success(())
        let sut = DefaultLogoutUseCase(authRepository: mockRepository)
        
        // When
        _ = await sut.execute()
        _ = await sut.execute()
        _ = await sut.execute()
        
        // Then
        #expect(mockRepository.logoutCallCount == 3)
    }
}
