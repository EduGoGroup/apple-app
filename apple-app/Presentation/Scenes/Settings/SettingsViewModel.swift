//
//  SettingsViewModel.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation
import Observation

/// ViewModel para la pantalla de Settings
@Observable
@MainActor
final class SettingsViewModel {
    private(set) var currentTheme: Theme = .system
    private(set) var isLoading = false

    private let updateThemeUseCase: UpdateThemeUseCase
    private let preferencesRepository: PreferencesRepository

    init(
        updateThemeUseCase: UpdateThemeUseCase,
        preferencesRepository: PreferencesRepository
    ) {
        self.updateThemeUseCase = updateThemeUseCase
        self.preferencesRepository = preferencesRepository
    }

    /// Carga las preferencias actuales
    func loadPreferences() async {
        let preferences = await preferencesRepository.getPreferences()
        currentTheme = preferences.theme
    }

    /// Actualiza el tema de la aplicación
    /// - Parameter theme: Nuevo tema a aplicar
    func updateTheme(_ theme: Theme) async {
        isLoading = true
        await updateThemeUseCase.execute(theme)
        currentTheme = theme
        isLoading = false
    }
}
