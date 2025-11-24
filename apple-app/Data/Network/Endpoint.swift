//
//  Endpoint.swift
//  apple-app
//
//  Created on 16-11-25.
//  Updated on 24-01-25 - SPEC-003: Versionado y Feature Flag
//

import Foundation

/// Endpoints disponibles en la API
enum Endpoint: Sendable {
    case login
    case logout
    case refresh
    case currentUser

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

    /// URL completa del endpoint
    ///
    /// DummyJSON usa su propia base URL, Real API usa la configurada en Environment
    func url(baseURL: URL) -> URL {
        switch AppEnvironment.authMode {
        case .dummyJSON:
            // DummyJSON tiene su propia URL
            return URL(string: "https://dummyjson.com\(path)")!
        case .realAPI:
            // Usar baseURL del environment
            return baseURL.appendingPathComponent(path)
        }
    }
}
