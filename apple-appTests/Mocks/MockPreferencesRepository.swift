//
//  MockPreferencesRepository.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation
@testable import apple_app

/// Mock de PreferencesRepository para testing
///
/// ## Swift 6 Concurrency
/// Marcado como @MainActor para cumplir con el protocolo PreferencesRepository.
/// FASE 1 - Refactoring: Alineado con la implementación real
@MainActor
final class MockPreferencesRepository: PreferencesRepository {
    // Estado actual
    var storedPreferences: UserPreferences = .default

    // Tracking de llamadas
    var getPreferencesCallCount = 0
    var savePreferencesCallCount = 0
    var updateThemeCallCount = 0
    var updateLanguageCallCount = 0
    var updateBiometricsEnabledCallCount = 0
    var observeThemeCallCount = 0
    var observePreferencesCallCount = 0

    // Streams
    private var themeContinuation: AsyncStream<Theme>.Continuation?
    private var preferencesContinuation: AsyncStream<UserPreferences>.Continuation?

    func getPreferences() async -> UserPreferences {
        getPreferencesCallCount += 1
        return storedPreferences
    }

    func savePreferences(_ preferences: UserPreferences) async {
        savePreferencesCallCount += 1
        storedPreferences = preferences
        preferencesContinuation?.yield(preferences)
    }

    func updateTheme(_ theme: Theme) async {
        updateThemeCallCount += 1
        storedPreferences.theme = theme
        themeContinuation?.yield(theme)
        preferencesContinuation?.yield(storedPreferences)
    }

    func updateLanguage(_ language: Language) async {
        updateLanguageCallCount += 1
        storedPreferences.language = language.rawValue
        preferencesContinuation?.yield(storedPreferences)
    }

    func updateBiometricsEnabled(_ enabled: Bool) async {
        updateBiometricsEnabledCallCount += 1
        storedPreferences.biometricsEnabled = enabled
        preferencesContinuation?.yield(storedPreferences)
    }

    func observeTheme() -> AsyncStream<Theme> {
        observeThemeCallCount += 1
        return AsyncStream { continuation in
            self.themeContinuation = continuation
            continuation.yield(self.storedPreferences.theme)
        }
    }

    func observePreferences() -> AsyncStream<UserPreferences> {
        observePreferencesCallCount += 1
        return AsyncStream { continuation in
            self.preferencesContinuation = continuation
            continuation.yield(self.storedPreferences)
        }
    }

    // Helper para reset
    func reset() {
        storedPreferences = .default
        getPreferencesCallCount = 0
        savePreferencesCallCount = 0
        updateThemeCallCount = 0
        updateLanguageCallCount = 0
        updateBiometricsEnabledCallCount = 0
        observeThemeCallCount = 0
        observePreferencesCallCount = 0
        themeContinuation = nil
        preferencesContinuation = nil
    }
}
