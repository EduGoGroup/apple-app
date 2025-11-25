//
//  MockAuthRepository.swift
//  apple-app
//
//  Created on 16-11-25.
//  Updated on 24-11-25 - SPRINT2: Actualizado para auth centralizada
//

import Foundation
@testable import apple_app

/// Mock de AuthRepository para testing
final class MockAuthRepository: AuthRepository, @unchecked Sendable {

    // MARK: - Resultados configurables

    var loginResult: Result<User, AppError> = .failure(.system(.unknown))
    var logoutResult: Result<Void, AppError> = .success(())
    var getCurrentUserResult: Result<User, AppError> = .failure(.business(.userNotFound))
    var refreshSessionResult: Result<User, AppError> = .failure(.system(.unknown))
    var refreshTokenResult: Result<AuthTokens, AppError> = .failure(.system(.unknown))
    var getTokenInfoResult: Result<TokenInfo, AppError> = .failure(.network(.unauthorized))
    var loginWithBiometricsResult: Result<User, AppError> = .failure(.system(.unknown))

    var hasActiveSessionResult: Bool = false
    var isAuthenticatedResult: Bool = false
    var validAccessToken: String? = nil

    // MARK: - Tracking de llamadas

    var loginCallCount = 0
    var logoutCallCount = 0
    var getCurrentUserCallCount = 0
    var refreshSessionCallCount = 0
    var refreshTokenCallCount = 0
    var hasActiveSessionCallCount = 0
    var isAuthenticatedCallCount = 0
    var getValidAccessTokenCallCount = 0
    var getTokenInfoCallCount = 0
    var clearLocalAuthDataCallCount = 0
    var loginWithBiometricsCallCount = 0

    var lastLoginEmail: String?
    var lastLoginPassword: String?

    // MARK: - AuthRepository Implementation

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

    func refreshToken() async -> Result<AuthTokens, AppError> {
        refreshTokenCallCount += 1
        return refreshTokenResult
    }

    func hasActiveSession() async -> Bool {
        hasActiveSessionCallCount += 1
        return hasActiveSessionResult
    }

    func isAuthenticated() async -> Bool {
        isAuthenticatedCallCount += 1
        return isAuthenticatedResult
    }

    func getValidAccessToken() async -> String? {
        getValidAccessTokenCallCount += 1
        return validAccessToken
    }

    func getTokenInfo() async -> Result<TokenInfo, AppError> {
        getTokenInfoCallCount += 1
        return getTokenInfoResult
    }

    func clearLocalAuthData() {
        clearLocalAuthDataCallCount += 1
    }

    func loginWithBiometrics() async -> Result<User, AppError> {
        loginWithBiometricsCallCount += 1
        return loginWithBiometricsResult
    }

    // MARK: - Helper para reset

    func reset() {
        loginCallCount = 0
        logoutCallCount = 0
        getCurrentUserCallCount = 0
        refreshSessionCallCount = 0
        refreshTokenCallCount = 0
        hasActiveSessionCallCount = 0
        isAuthenticatedCallCount = 0
        getValidAccessTokenCallCount = 0
        getTokenInfoCallCount = 0
        clearLocalAuthDataCallCount = 0
        loginWithBiometricsCallCount = 0
        lastLoginEmail = nil
        lastLoginPassword = nil
    }

    // MARK: - Convenience setters para tests

    func setAuthenticatedUser(_ user: User, tokens: TokenInfo? = nil) {
        loginResult = .success(user)
        getCurrentUserResult = .success(user)
        refreshSessionResult = .success(user)
        hasActiveSessionResult = true
        isAuthenticatedResult = true
        validAccessToken = tokens?.accessToken ?? "mock_access_token"

        if let tokens = tokens {
            refreshTokenResult = .success(tokens)
            getTokenInfoResult = .success(tokens)
        }
    }

    func setUnauthenticated() {
        hasActiveSessionResult = false
        isAuthenticatedResult = false
        validAccessToken = nil
        getCurrentUserResult = .failure(.network(.unauthorized))
        getTokenInfoResult = .failure(.network(.unauthorized))
    }
}
