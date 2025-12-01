//
//  AuthenticationState.swift
//  EduGoFeatures
//
//  Created on 23-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//

import Foundation
import Observation
import EduGoDomainCore

/// Estado global de autenticación
/// Controla si el usuario está autenticado y qué root view mostrar
@Observable
@MainActor
public final class AuthenticationState {
    /// Usuario actualmente autenticado (nil si no hay sesión)
    public var currentUser: User?

    /// Indica si el usuario está autenticado
    public var isAuthenticated: Bool {
        currentUser != nil
    }

    // MARK: - Initialization

    public nonisolated init(currentUser: User? = nil) {
        self.currentUser = currentUser
    }

    // MARK: - Public Methods

    /// Marca al usuario como autenticado
    public func authenticate(user: User) {
        currentUser = user
    }

    /// Cierra la sesión del usuario
    public func logout() {
        currentUser = nil
    }
}
