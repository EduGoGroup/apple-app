//
//  Endpoint.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Endpoints disponibles en la API
enum Endpoint: Sendable {
    case login
    case logout
    case refresh
    case currentUser
    
    /// Path del endpoint
    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .logout:
            return "/auth/logout"
        case .refresh:
            return "/auth/refresh"
        case .currentUser:
            return "/auth/me"
        }
    }
}
