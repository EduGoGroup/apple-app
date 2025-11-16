//
//  Theme.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Representa los temas de apariencia disponibles en la aplicación
enum Theme: String, Codable, CaseIterable, Sendable {
    /// Tema claro
    case light
    
    /// Tema oscuro
    case dark
    
    /// Tema automático (según preferencias del sistema)
    case system
    
    /// Retorna el ColorScheme correspondiente al tema
    /// - Returns: ColorScheme de SwiftUI, o nil para seguir el sistema
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
    
    /// Nombre localizado para mostrar en UI
    var displayName: String {
        switch self {
        case .light:
            return "Claro"
        case .dark:
            return "Oscuro"
        case .system:
            return "Sistema"
        }
    }
    
    /// Ícono SF Symbol para el tema
    var iconName: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "circle.lefthalf.filled"
        }
    }
}
