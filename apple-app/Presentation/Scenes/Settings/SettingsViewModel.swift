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
    private(set) var currentLanguage: Language = .default // SPEC-010
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
        currentLanguage = Language(rawValue: preferences.language) ?? .default // SPEC-010
    }

    /// Actualiza el tema de la aplicación
    /// - Parameter theme: Nuevo tema a aplicar
    func updateTheme(_ theme: Theme) async {
        isLoading = true
        await updateThemeUseCase.execute(theme)
        currentTheme = theme
        isLoading = false
    }

    /// SPEC-010: Actualiza el idioma de la aplicación
    /// - Parameter language: Nuevo idioma a aplicar
    func updateLanguage(_ language: Language) async {
        isLoading = true
        await preferencesRepository.updateLanguage(language)
        currentLanguage = language
        isLoading = false
    }
}
