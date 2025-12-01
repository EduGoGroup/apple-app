//
//  AnalyticsProvider.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Data/Services/Analytics/Providers/
//  SPEC-011: Analytics & Telemetry
//

import Foundation

/// Protocol para providers de analytics
///
/// ## Responsabilidad
/// Define la interfaz que deben implementar todos los providers de analytics
/// (Firebase, Mixpanel, Console, etc).
///
/// ## Concurrency
/// - **Sendable:** Protocol puro ✅
/// - **Métodos async:** Permite implementaciones thread-safe
/// - **Implementations:** Pueden ser struct Sendable o actor
///
/// ## Pattern
/// Este es el patrón Strategy para permitir múltiples backends de analytics:
/// - ConsoleAnalyticsProvider: Para debug (imprime en consola)
/// - FirebaseAnalyticsProvider: Para producción
/// - NoOpAnalyticsProvider: Cuando tracking está deshabilitado
///
/// ## Implementaciones Disponibles
/// - `ConsoleAnalyticsProvider` - Debug (struct Sendable)
/// - `FirebaseAnalyticsProvider` - Producción (struct Sendable)
/// - `NoOpAnalyticsProvider` - Disabled (struct Sendable)
public protocol AnalyticsProvider: Sendable {
    /// Nombre del provider
    ///
    /// Usado para logging y debugging.
    ///
    /// ## Concurrency
    /// - nonisolated: Accesible desde cualquier contexto sin async
    nonisolated var name: String { get }

    /// Indica si el provider está disponible
    ///
    /// Por ejemplo, FirebaseAnalyticsProvider retorna false si
    /// el SDK no está importado o configurado.
    ///
    /// ## Concurrency
    /// - nonisolated: Accesible desde cualquier contexto sin async
    nonisolated var isAvailable: Bool { get }

    /// Inicializa el provider
    ///
    /// Llamado una vez durante configuración inicial.
    ///
    /// ## Concurrency
    /// - async: Permite inicialización que cruza isolation boundaries
    func initialize() async

    /// Log un evento
    ///
    /// ## Concurrency
    /// - async: Permite crossing isolation boundaries
    ///
    /// ## Parámetros Sendable
    /// - `[String: String]` es Sendable ✅
    ///
    /// - Parameters:
    ///   - name: Nombre del evento
    ///   - parameters: Parámetros del evento (opcional)
    func logEvent(_ name: String, parameters: [String: String]?) async

    /// Establece una propiedad de usuario
    ///
    /// ## Concurrency
    /// - async: Permite crossing isolation boundaries
    ///
    /// - Parameters:
    ///   - name: Nombre de la propiedad
    ///   - value: Valor (nil para remover)
    func setUserProperty(_ name: String, value: String?) async

    /// Establece el ID del usuario
    ///
    /// ## Concurrency
    /// - async: Permite crossing isolation boundaries
    ///
    /// - Parameter userId: ID del usuario (nil para remover)
    func setUserId(_ userId: String?) async

    /// Resetea todos los datos
    ///
    /// ## Concurrency
    /// - async: Permite crossing isolation boundaries
    func reset() async
}
