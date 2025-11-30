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

    /// Pantalla de cursos
    case courses

    /// Pantalla de calendario
    case calendar

    /// Pantalla de progreso
    case progress

    /// Pantalla de comunidad
    case community

    /// Pantalla de configuración
    case settings
}
