//
//  Endpoint.swift
//  apple-app
//
//  Created on 16-11-25.
//  Updated on 24-01-25 - SPEC-003: Versionado y Feature Flag
//  Updated on 24-11-25 - SPRINT2-T06: URLs separadas para ecosistema
//

import Foundation

/// Endpoints disponibles en la API
///
/// ## Arquitectura de URLs
/// - Endpoints de auth (login, logout, refresh, me) → `authAPIBaseURL` (api-admin)
/// - Endpoints de contenido (materials, progress) → `mobileAPIBaseURL` (api-mobile)
/// - Endpoints de admin (schools, units) → `adminAPIBaseURL` (api-admin)
enum Endpoint: Sendable {
    case login
    case logout
    case refresh
    case currentUser

    // Futuros endpoints de contenido
    // case materials
    // case progress

    /// Path del endpoint según el modo de autenticación
    var path: String {
        let basePath: String

        // DummyJSON no usa versionado, Real API usa /v1
        switch AppEnvironment.authMode {
        case .dummyJSON:
            basePath = "/auth"
        case .realAPI:
            basePath = "/v1/auth"
        }

        switch self {
        case .login:
            return "\(basePath)/login"
        case .logout:
            return "\(basePath)/logout"
        case .refresh:
            return "\(basePath)/refresh"
        case .currentUser:
            return "\(basePath)/me"
        }
    }

    /// Indica si es un endpoint de autenticación (usa authAPIBaseURL)
    var isAuthEndpoint: Bool {
        switch self {
        case .login, .logout, .refresh, .currentUser:
            return true
        }
    }

    /// Base URL apropiada para este endpoint
    private var baseURL: URL {
        switch AppEnvironment.authMode {
        case .dummyJSON:
            // DummyJSON tiene su propia URL
            return URL(string: "https://dummyjson.com")!
        case .realAPI:
            // Endpoints de auth van a api-admin
            // Endpoints de contenido irían a api-mobile
            if isAuthEndpoint {
                return AppEnvironment.authAPIBaseURL
            } else {
                return AppEnvironment.mobileAPIBaseURL
            }
        }
    }

    /// URL completa del endpoint
    ///
    /// - En modo DummyJSON: Usa dummyjson.com
    /// - En modo Real API: Usa authAPIBaseURL para auth, mobileAPIBaseURL para contenido
    func url(baseURL: URL) -> URL {
        // Ignorar el baseURL pasado y usar el correcto según el tipo de endpoint
        return self.baseURL.appendingPathComponent(path)
    }

    /// URL completa del endpoint (sin necesidad de pasar baseURL)
    var fullURL: URL {
        baseURL.appendingPathComponent(path)
    }
}

// MARK: - Convenience

extension Endpoint {
    /// Descripción para logging
    var description: String {
        switch self {
        case .login: return "Login"
        case .logout: return "Logout"
        case .refresh: return "Refresh Token"
        case .currentUser: return "Current User"
        }
    }
}
