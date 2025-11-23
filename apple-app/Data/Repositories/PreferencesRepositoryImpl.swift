//
//  PreferencesRepositoryImpl.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Implementación del repositorio de preferencias usando UserDefaults
final class PreferencesRepositoryImpl: PreferencesRepository, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let preferencesKey = "user_preferences"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func getPreferences() async -> UserPreferences {
        if let data = userDefaults.data(forKey: preferencesKey),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            return preferences
        }
        return .default
    }

    func savePreferences(_ preferences: UserPreferences) async {
        if let data = try? JSONEncoder().encode(preferences) {
            userDefaults.set(data, forKey: preferencesKey)
        }
    }

    func updateTheme(_ theme: Theme) async {
        var preferences = await getPreferences()
        preferences.theme = theme
        await savePreferences(preferences)
    }

    func updateLanguage(_ language: String) async {
        var preferences = await getPreferences()
        preferences.language = language
        await savePreferences(preferences)
    }

    func updateBiometricsEnabled(_ enabled: Bool) async {
        var preferences = await getPreferences()
        preferences.biometricsEnabled = enabled
        await savePreferences(preferences)
    }

    func observeTheme() -> AsyncStream<Theme> {
        AsyncStream { continuation in
            // Enviar valor actual
            Task {
                let preferences = await self.getPreferences()
                continuation.yield(preferences.theme)
            }

            // Observar cambios (simplificado)
            // Usamos una clase wrapper para hacer el observation Sendable
            final class ObserverBox: @unchecked Sendable {
                var observer: NSObjectProtocol?
            }

            let box = ObserverBox()
            box.observer = NotificationCenter.default.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task {
                    let preferences = await self.getPreferences()
                    continuation.yield(preferences.theme)
                }
            }

            continuation.onTermination = { @Sendable _ in
                if let observer = box.observer {
                    NotificationCenter.default.removeObserver(observer)
                }
            }
        }
    }

    func observePreferences() -> AsyncStream<UserPreferences> {
        AsyncStream { continuation in
            // Enviar valor actual
            Task {
                let preferences = await self.getPreferences()
                continuation.yield(preferences)
            }

            // Observar cambios
            // Usamos una clase wrapper para hacer el observation Sendable
            final class ObserverBox: @unchecked Sendable {
                var observer: NSObjectProtocol?
            }

            let box = ObserverBox()
            box.observer = NotificationCenter.default.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task {
                    let preferences = await self.getPreferences()
                    continuation.yield(preferences)
                }
            }

            continuation.onTermination = { @Sendable _ in
                if let observer = box.observer {
                    NotificationCenter.default.removeObserver(observer)
                }
            }
        }
    }
}
