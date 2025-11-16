//
//  MockAuthRepository.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation
@testable import apple_app

/// Mock de AuthRepository para testing
final class MockAuthRepository: AuthRepository {
    // Resultados configurables
    var loginResult: Result<User, AppError> = .failure(.system(.unknown))
    var logoutResult: Result<Void, AppError> = .success(())
    var getCurrentUserResult: Result<User, AppError> = .failure(.business(.userNotFound))
    var refreshSessionResult: Result<User, AppError> = .failure(.system(.unknown))
    var hasActiveSessionResult: Bool = false
    
    // Tracking de llamadas
    var loginCallCount = 0
    var logoutCallCount = 0
    var getCurrentUserCallCount = 0
    var refreshSessionCallCount = 0
    var hasActiveSessionCallCount = 0
    
    var lastLoginEmail: String?
    var lastLoginPassword: String?
    
    func login(email: String, password: String) async -> Result<User, AppError> {
        loginCallCount += 1
        lastLoginEmail = email
        lastLoginPassword = password
        return loginResult
    }
    
    func logout() async -> Result<Void, AppError> {
        logoutCallCount += 1
        return logoutResult
    }
    
    func getCurrentUser() async -> Result<User, AppError> {
        getCurrentUserCallCount += 1
        return getCurrentUserResult
    }
    
    func refreshSession() async -> Result<User, AppError> {
        refreshSessionCallCount += 1
        return refreshSessionResult
    }
    
    func hasActiveSession() async -> Bool {
        hasActiveSessionCallCount += 1
        return hasActiveSessionResult
    }
    
    // Helper para reset
    func reset() {
        loginCallCount = 0
        logoutCallCount = 0
        getCurrentUserCallCount = 0
        refreshSessionCallCount = 0
        hasActiveSessionCallCount = 0
        lastLoginEmail = nil
        lastLoginPassword = nil
    }
}
