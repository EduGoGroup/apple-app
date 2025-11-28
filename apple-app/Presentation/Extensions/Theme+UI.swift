//
//  Theme+UI.swift
//  apple-app
//
//  Created on 28-11-25.
//  Extension de Theme para propiedades de presentación
//

import SwiftUI

/// Extensión de Theme con propiedades específicas de UI
///
/// Esta extensión contiene todas las propiedades que dependen de SwiftUI
/// o que son específicas de presentación, manteniendo el enum `Theme`
/// en Domain Layer puro.
///
/// Separación de responsabilidades:
/// - **Domain/Entities/Theme.swift**: Lógica de negocio (isExplicit, prefersDark)
/// - **Presentation/Extensions/Theme+UI.swift**: Propiedades de UI (colorScheme, displayName, iconName)
extension Theme {

    // MARK: - SwiftUI Integration

    /// ColorScheme para usar con `.preferredColorScheme()`
    ///
    /// Retorna nil para `.system` para permitir que SwiftUI
    /// use las preferencias del sistema operativo.
    ///
    /// ```swift
    /// .preferredColorScheme(preferences.theme.colorScheme)
    /// ```
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil  // SwiftUI usará preferencias del sistema
        }
    }

    // MARK: - Display Properties

    /// Nombre localizado para mostrar en UI
    ///
    /// - Note: Usa String(localized:) para soporte multiidioma (SPEC-010)
    var displayName: LocalizedStringKey {
        switch self {
        case .light:
            return "settings.theme.light"
        case .dark:
            return "settings.theme.dark"
        case .system:
            return "settings.theme.system"
        }
    }

    /// Versión String del displayName (para contextos no-SwiftUI)
    var displayNameString: String {
        switch self {
        case .light:
            return String(localized: "settings.theme.light")
        case .dark:
            return String(localized: "settings.theme.dark")
        case .system:
            return String(localized: "settings.theme.system")
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

    // MARK: - Additional UI Properties

    /// Color de preview para el tema
    var previewColor: Color {
        switch self {
        case .light:
            return .white
        case .dark:
            return .black
        case .system:
            return .gray
        }
    }

    /// Label de accesibilidad para el tema
    var accessibilityLabel: String {
        switch self {
        case .light:
            return String(localized: "settings.theme.light.accessibility")
        case .dark:
            return String(localized: "settings.theme.dark.accessibility")
        case .system:
            return String(localized: "settings.theme.system.accessibility")
        }
    }
}
