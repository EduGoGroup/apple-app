//
//  SettingsViewModel.swift
//  EduGoFeatures
//
//  Created on 16-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//

import Foundation
import Observation
import EduGoDomainCore

/// ViewModel para la pantalla de Settings
@Observable
@MainActor
public final class SettingsViewModel {
    public private(set) var currentTheme: Theme = .system
    public private(set) var currentLanguage: Language = .default
    public private(set) var isLoading = false

    private let updateThemeUseCase: UpdateThemeUseCase
    private let preferencesRepository: PreferencesRepository

    public nonisolated init(
        updateThemeUseCase: UpdateThemeUseCase,
        preferencesRepository: PreferencesRepository
    ) {
        self.updateThemeUseCase = updateThemeUseCase
        self.preferencesRepository = preferencesRepository
    }

    /// Carga las preferencias actuales
    public func loadPreferences() async {
        let preferences = await preferencesRepository.getPreferences()
        currentTheme = preferences.theme
        currentLanguage = Language(rawValue: preferences.language) ?? .default
    }

    /// Actualiza el tema de la aplicación
    /// - Parameter theme: Nuevo tema a aplicar
    public func updateTheme(_ theme: Theme) async {
        isLoading = true
        await updateThemeUseCase.execute(theme)
        currentTheme = theme
        isLoading = false
    }

    /// Actualiza el idioma de la aplicación
    /// - Parameter language: Nuevo idioma a aplicar
    public func updateLanguage(_ language: Language) async {
        isLoading = true
        await preferencesRepository.updateLanguage(language)
        currentLanguage = language
        isLoading = false
    }
}
