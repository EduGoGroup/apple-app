//
//  PreferencesRepositoryImpl.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Implementación del repositorio de preferencias usando UserDefaults
///
/// ## Swift 6 Concurrency
/// Esta clase está marcada como `@MainActor` porque:
/// 1. UserDefaults es thread-safe pero funciona mejor en main thread
/// 2. Se usa principalmente desde UI (SwiftUI views)
/// 3. NotificationCenter observers se ejecutan en main queue
/// 4. El protocolo PreferencesRepository requiere @MainActor
///
/// FASE 1 - Refactoring: Eliminado @unchecked Sendable de la clase principal
/// Nota: Se mantiene un wrapper mínimo para NSObjectProtocol (limitación del SDK)
@MainActor
final class PreferencesRepositoryImpl: PreferencesRepository {
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

    func updateLanguage(_ language: Language) async {
        var preferences = await getPreferences()
        preferences.language = language.rawValue
        await savePreferences(preferences)
    }

    func updateBiometricsEnabled(_ enabled: Bool) async {
        var preferences = await getPreferences()
        preferences.biometricsEnabled = enabled
        await savePreferences(preferences)
    }

    func observeTheme() -> AsyncStream<Theme> {
        AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            // Enviar valor actual (ya estamos en @MainActor)
            Task { @MainActor in
                let preferences = await self.getPreferences()
                continuation.yield(preferences.theme)
            }

            // Observar cambios en main queue (NotificationCenter)
            let observer = NotificationCenter.default.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }

                // Ya estamos en main queue, ejecutar directamente
                Task { @MainActor in
                    let preferences = await self.getPreferences()
                    continuation.yield(preferences.theme)
                }
            }

            // ============================================================
            // EXCEPCIÓN DE CONCURRENCIA DOCUMENTADA
            // ============================================================
            // Tipo: SDK de Apple no marcado Sendable
            // Componente: NSObjectProtocol (NotificationCenter observer)
            // Justificación: NSObjectProtocol no es Sendable en el SDK de Apple,
            //                pero el observer es inmutable (let) y solo se usa
            //                en la closure @Sendable de terminación.
            //                NotificationCenter garantiza thread-safety del observer.
            // Referencia: https://developer.apple.com/documentation/foundation/notificationcenter
            // Ticket: N/A (limitación del SDK de Apple)
            // Fecha: 2025-11-26
            // Revisión: Revisar cuando Apple actualice NSObjectProtocol para Swift 6
            // ============================================================
            final class ObserverWrapper: @unchecked Sendable {
                let observer: NSObjectProtocol
                init(_ observer: NSObjectProtocol) {
                    self.observer = observer
                }
            }

            let wrapper = ObserverWrapper(observer)

            // Cleanup cuando el stream termine
            continuation.onTermination = { @Sendable _ in
                NotificationCenter.default.removeObserver(wrapper.observer)
            }
        }
    }

    func observePreferences() -> AsyncStream<UserPreferences> {
        AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            // Enviar valor actual (ya estamos en @MainActor)
            Task { @MainActor in
                let preferences = await self.getPreferences()
                continuation.yield(preferences)
            }

            // Observar cambios en main queue (NotificationCenter)
            let observer = NotificationCenter.default.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }

                // Ya estamos en main queue, ejecutar directamente
                Task { @MainActor in
                    let preferences = await self.getPreferences()
                    continuation.yield(preferences)
                }
            }

            // ============================================================
            // EXCEPCIÓN DE CONCURRENCIA DOCUMENTADA
            // ============================================================
            // Tipo: SDK de Apple no marcado Sendable
            // Componente: NSObjectProtocol (NotificationCenter observer)
            // Justificación: NSObjectProtocol no es Sendable en el SDK de Apple,
            //                pero el observer es inmutable (let) y solo se usa
            //                en la closure @Sendable de terminación.
            //                NotificationCenter garantiza thread-safety del observer.
            // Referencia: https://developer.apple.com/documentation/foundation/notificationcenter
            // Ticket: N/A (limitación del SDK de Apple)
            // Fecha: 2025-11-26
            // Revisión: Revisar cuando Apple actualice NSObjectProtocol para Swift 6
            // ============================================================
            final class ObserverWrapper: @unchecked Sendable {
                let observer: NSObjectProtocol
                init(_ observer: NSObjectProtocol) {
                    self.observer = observer
                }
            }

            let wrapper = ObserverWrapper(observer)

            // Cleanup cuando el stream termine
            continuation.onTermination = { @Sendable _ in
                NotificationCenter.default.removeObserver(wrapper.observer)
            }
        }
    }
}
