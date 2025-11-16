//
//  PreferencesRepository.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Protocolo que define las operaciones para gestionar preferencias del usuario
protocol PreferencesRepository: Sendable {
    /// Obtiene las preferencias actuales del usuario
    /// - Returns: UserPreferences configuradas (nunca falla, retorna default si no existen)
    func getPreferences() async -> UserPreferences
    
    /// Guarda las preferencias completas del usuario
    /// - Parameter preferences: Preferencias a guardar
    func savePreferences(_ preferences: UserPreferences) async
    
    /// Actualiza solo el tema de apariencia
    /// - Parameter theme: Nuevo tema a aplicar
    func updateTheme(_ theme: Theme) async
    
    /// Actualiza el idioma de la aplicación
    /// - Parameter language: Código de idioma (ej: "es", "en")
    func updateLanguage(_ language: String) async
    
    /// Actualiza la configuración de biometría
    /// - Parameter enabled: true para habilitar, false para deshabilitar
    func updateBiometricsEnabled(_ enabled: Bool) async
    
    /// Observa los cambios en el tema
    /// - Returns: AsyncStream que emite cada cambio de tema
    func observeTheme() -> AsyncStream<Theme>
    
    /// Observa los cambios en las preferencias completas
    /// - Returns: AsyncStream que emite cada cambio en preferencias
    func observePreferences() -> AsyncStream<UserPreferences>
}
