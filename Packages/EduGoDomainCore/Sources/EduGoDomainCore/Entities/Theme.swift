//
//  Theme.swift
//  apple-app
//
//  Created on 16-11-25.
//  Updated on 28-11-25: Removido SwiftUI para cumplir Clean Architecture
//

import Foundation

/// Representa los temas de apariencia disponibles en la aplicación
///
/// Esta entidad de Domain es pura y no tiene dependencias de UI.
/// Para propiedades de presentación (colorScheme, displayName, iconName),
/// ver la extensión en `Presentation/Extensions/Theme+UI.swift`.
///
/// - Note: Cumple Clean Architecture - Domain Layer puro
public enum Theme: String, Codable, CaseIterable, Sendable {
    /// Tema claro
    case light

    /// Tema oscuro
    case dark

    /// Tema automático (según preferencias del sistema)
    case system

    // MARK: - Business Logic Properties

    /// Tema por defecto para nuevos usuarios
    public static let `default`: Theme = .system

    /// Indica si es un tema explícito (no sigue al sistema)
    ///
    /// Útil para determinar si el usuario ha seleccionado activamente
    /// un tema o si está usando el predeterminado del sistema.
    public var isExplicit: Bool {
        self != .system
    }

    /// Indica si el tema representa modo oscuro
    ///
    /// - Note: Para `.system`, esto es indeterminado y devuelve false.
    ///   Use `colorScheme` en la extensión UI para obtener el valor real.
    public var prefersDark: Bool {
        self == .dark
    }
}
