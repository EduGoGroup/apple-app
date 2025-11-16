//
//  UpdateThemeUseCase.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Protocolo para el caso de uso de actualizar tema
protocol UpdateThemeUseCase: Sendable {
    /// Actualiza el tema de la aplicación
    /// - Parameter theme: Nuevo tema a aplicar
    func execute(_ theme: Theme) async
}

/// Implementación por defecto del caso de uso de actualizar tema
final class DefaultUpdateThemeUseCase: UpdateThemeUseCase {
    private let preferencesRepository: PreferencesRepository
    
    init(preferencesRepository: PreferencesRepository) {
        self.preferencesRepository = preferencesRepository
    }
    
    func execute(_ theme: Theme) async {
        // Actualiza el tema en el repositorio
        await preferencesRepository.updateTheme(theme)
    }
}
