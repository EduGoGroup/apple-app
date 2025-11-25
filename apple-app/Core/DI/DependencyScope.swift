//
//  DependencyScope.swift
//  apple-app
//
//  Created on 23-01-25.
//

import Foundation

/// Define el alcance (lifetime) de una dependencia registrada
public enum DependencyScope {
    /// Una única instancia compartida durante toda la vida de la app
    /// - Uso: Services, Repositories, APIClient
    /// - Ejemplo: KeychainService, AuthRepository
    case singleton

    /// Nueva instancia cada vez que se resuelve
    /// - Uso: Use Cases, objetos con estado por operación
    /// - Ejemplo: LoginUseCase, LogoutUseCase
    case factory

    /// Nueva instancia cada vez que se resuelve (alias de factory)
    /// - Uso: ViewModels, objetos de corta vida
    /// - Ejemplo: LoginViewModel (si se crea desde container)
    case transient
}
