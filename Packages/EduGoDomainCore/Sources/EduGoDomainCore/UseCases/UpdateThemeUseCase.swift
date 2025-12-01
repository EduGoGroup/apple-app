//
//  UpdateThemeUseCase.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Protocolo para el caso de uso de actualizar tema
@MainActor
public protocol UpdateThemeUseCase: Sendable {
    /// Actualiza el tema de la aplicación
    /// - Parameter theme: Nuevo tema a aplicar
    func execute(_ theme: Theme) async
}

/// Implementación por defecto del caso de uso de actualizar tema
@MainActor
public final class DefaultUpdateThemeUseCase: UpdateThemeUseCase {
    private let preferencesRepository: PreferencesRepository

    public init(preferencesRepository: PreferencesRepository) {
        self.preferencesRepository = preferencesRepository
    }

    public func execute(_ theme: Theme) async {
        // Actualiza el tema en el repositorio
        await preferencesRepository.updateTheme(theme)
    }
}
