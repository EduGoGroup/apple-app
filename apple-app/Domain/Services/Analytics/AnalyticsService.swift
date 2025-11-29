//
//  AnalyticsService.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-011: Analytics & Telemetry
//

import Foundation

/// Servicio de analytics para tracking de eventos y propiedades de usuario
///
/// ## Responsabilidad
/// - Tracking de eventos de usuario
/// - Gestión de propiedades de usuario
/// - Control de opt-in/opt-out
///
/// ## Concurrency
/// - **Protocol:** Sendable (puro, sin implementación)
/// - **Métodos async:** Permite implementaciones actor
/// - **Thread-safety:** Garantizado por implementación (actor)
///
/// ## Implementaciones
/// - `AnalyticsManager` (actor) - Implementación principal con múltiples providers
///
/// ## Uso Típico
/// ```swift
/// let analytics = AnalyticsManager.shared
/// await analytics.track(.userLoggedIn, parameters: ["method": "email"])
/// ```
protocol AnalyticsService: Sendable {
    /// Track un evento de analytics
    ///
    /// ## Concurrency
    /// - async: Permite crossing isolation boundaries
    ///
    /// ## Parámetros Sendable
    /// - `[String: String]` es Sendable ✅
    /// - Para valores no-String, convertir a String antes de enviar
    ///
    /// - Parameters:
    ///   - event: Evento a trackear
    ///   - parameters: Parámetros adicionales del evento (opcional)
    func track(_ event: AnalyticsEvent, parameters: [String: String]?) async

    /// Establece una propiedad de usuario
    ///
    /// Las propiedades de usuario persisten entre sesiones y se envían
    /// con todos los eventos subsecuentes.
    ///
    /// ## Concurrency
    /// - async: Permite crossing isolation boundaries
    ///
    /// - Parameters:
    ///   - property: Propiedad a establecer
    ///   - value: Valor de la propiedad (nil para remover)
    func setUserProperty(_ property: AnalyticsUserProperty, value: String?) async

    /// Establece el ID del usuario
    ///
    /// ## Concurrency
    /// - async: Permite crossing isolation boundaries
    ///
    /// - Parameter userId: ID del usuario (nil para remover)
    func setUserId(_ userId: String?) async

    /// Resetea todos los datos de analytics
    ///
    /// Útil al hacer logout para limpiar datos del usuario anterior.
    ///
    /// ## Concurrency
    /// - async: Permite crossing isolation boundaries
    func reset() async

    /// Indica si el tracking está habilitado
    ///
    /// ## Concurrency
    /// - async get: Permite actor isolation
    var isEnabled: Bool { get async }

    /// Habilita o deshabilita el tracking
    ///
    /// ## Privacy
    /// Cuando está deshabilitado, no se envían eventos a ningún provider.
    ///
    /// ## Concurrency
    /// - async: Permite crossing isolation boundaries
    ///
    /// - Parameter enabled: true para habilitar, false para deshabilitar
    func setEnabled(_ enabled: Bool) async
}

// MARK: - Convenience Methods

extension AnalyticsService {
    /// Track un evento sin parámetros adicionales
    ///
    /// ## Concurrency
    /// - async: Llama al método principal async
    ///
    /// - Parameter event: Evento a trackear
    func track(_ event: AnalyticsEvent) async {
        await track(event, parameters: nil)
    }
}
