//
//  AuthenticationState.swift
//  apple-app
//
//  Created on 23-11-25.
//

import Foundation
import Observation

/// Estado global de autenticación
/// Controla si el usuario está autenticado y qué root view mostrar
@Observable
@MainActor
final class AuthenticationState {
    /// Usuario actualmente autenticado (nil si no hay sesión)
    var currentUser: User?

    /// Indica si el usuario está autenticado
    var isAuthenticated: Bool {
        currentUser != nil
    }

    /// Marca al usuario como autenticado
    func authenticate(user: User) {
        currentUser = user
    }

    /// Cierra la sesión del usuario
    func logout() {
        currentUser = nil
    }
}
