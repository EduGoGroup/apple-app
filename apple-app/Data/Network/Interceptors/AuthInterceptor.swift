//
//  AuthInterceptor.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-004: Network Layer Enhancement - Auth Interceptor
//

import Foundation

/// Interceptor que inyecta automáticamente el token de autenticación en los requests
///
/// ## Swift 6 Concurrency
/// FASE 3 - Refactoring: Eliminado @unchecked Sendable, marcado como @MainActor.
/// Debe ser @MainActor porque:
/// 1. TokenRefreshCoordinator es @MainActor (dependencia)
/// 2. El método intercept ya está marcado @MainActor
/// 3. No hay razón para @unchecked cuando la solución correcta es @MainActor
@MainActor
final class AuthInterceptor: RequestInterceptor {

    // MARK: - Dependencies

    private let tokenCoordinator: TokenRefreshCoordinator

    // MARK: - Initialization

    init(tokenCoordinator: TokenRefreshCoordinator) {
        self.tokenCoordinator = tokenCoordinator
    }

    // MARK: - RequestInterceptor

    func intercept(_ request: URLRequest) async throws -> URLRequest {
        // 1. Verificar si el endpoint requiere autenticación
        guard requiresAuth(request) else {
            return request
        }

        // 2. Obtener token válido (auto-refresh si necesita)
        let tokenInfo = try await tokenCoordinator.getValidToken()

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
