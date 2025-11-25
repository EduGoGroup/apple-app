//
//  Route.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Rutas de navegación de la aplicación
enum Route: Hashable, Sendable {
    /// Pantalla de login
    case login

    /// Pantalla principal (home)
    case home

    /// Pantalla de configuración
    case settings
}
