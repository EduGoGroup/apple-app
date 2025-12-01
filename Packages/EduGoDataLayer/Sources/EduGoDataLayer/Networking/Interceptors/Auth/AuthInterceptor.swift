//
//  AuthInterceptor.swift
//  EduGoDataLayer
//
//  Created on 24-01-25.
//  SPEC-004: Network Layer Enhancement - Auth Interceptor
//  Migrated to EduGoDataLayer on Sprint 3
//

import Foundation
import EduGoDomainCore

/// Interceptor que inyecta automáticamente el token de autenticación en los requests
///
/// ## Swift 6 Concurrency
/// FASE 3 - Refactoring: Eliminado @unchecked Sendable, marcado como @MainActor.
/// Debe ser @MainActor porque:
/// 1. TokenProvider puede ser @MainActor (ej: TokenRefreshCoordinator)
/// 2. El método intercept ya está marcado @MainActor
/// 3. No hay razón para @unchecked cuando la solución correcta es @MainActor
///
/// ## Dependency Inversion
/// Usa `TokenProvider` protocolo de dominio en lugar de `TokenRefreshCoordinator`
/// concreto para romper dependencia circular DataLayer ↔ SecurityKit
@MainActor
public final class AuthInterceptor: RequestInterceptor {
    // MARK: - Dependencies

    private let tokenProvider: TokenProvider

    // MARK: - Initialization

    public init(tokenProvider: TokenProvider) {
        self.tokenProvider = tokenProvider
    }

    // MARK: - RequestInterceptor

    public func intercept(_ request: URLRequest) async throws -> URLRequest {
        // 1. Verificar si el endpoint requiere autenticación
        guard requiresAuth(request) else {
            return request
        }

        // 2. Obtener token válido (auto-refresh si necesita)
        let tokenInfo = try await tokenProvider.getValidToken()

        // 3. Inyectar token en header
        var mutableRequest = request
        mutableRequest.setValue(
            "Bearer \(tokenInfo.accessToken)",
            forHTTPHeaderField: "Authorization"
        )

        return mutableRequest
    }

    // MARK: - Private Methods

    private func requiresAuth(_ request: URLRequest) -> Bool {
        guard let url = request.url else { return false }

        let path = url.path

        // Endpoints públicos que NO requieren autenticación
        let publicPaths = [
            "/auth/login",
            "/v1/auth/login",
            "/auth/refresh",
            "/v1/auth/refresh",
            "/health"
        ]

        return !publicPaths.contains(where: { path.contains($0) })
    }
}

// MARK: - Testing

#if DEBUG
/// Mock Auth Interceptor para testing
@MainActor
public final class MockAuthInterceptor: RequestInterceptor {
    public var shouldAddAuth: Bool = true
    public var tokenToInject: String = "mock_token"
    public var interceptCallCount = 0

    public init() {}

    public func intercept(_ request: URLRequest) async throws -> URLRequest {
        interceptCallCount += 1

        guard shouldAddAuth else {
            return request
        }

        var mutableRequest = request
        mutableRequest.setValue(
            "Bearer \(tokenToInject)",
            forHTTPHeaderField: "Authorization"
        )
        return mutableRequest
    }

    public func reset() {
        shouldAddAuth = true
        tokenToInject = "mock_token"
        interceptCallCount = 0
    }
}
#endif
