//
//  AnalyticsManager.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-011: Analytics & Telemetry
//

import Foundation

/// Manager centralizado de analytics con soporte para múltiples providers
///
/// ## Responsabilidad
/// - Coordinar múltiples providers de analytics
/// - Distribuir eventos a todos los providers activos
/// - Gestionar habilitación/deshabilitación global
/// - Responder a preferencias de privacy del usuario
///
/// ## Concurrency (CRÍTICO)
/// - **actor:** Serializa acceso a estado mutable ✅
/// - **Estado mutable:** `providers[]`, `_isEnabled`
/// - **Thread-safety:** Garantizado por actor isolation
///
/// ## Por qué actor (según 03-REGLAS-DESARROLLO-IA.md)
///
/// ### Contextos de uso:
/// ```swift
/// // Desde ViewModel (@MainActor)
/// await AnalyticsManager.shared.track(.screenViewed)
///
/// // Desde Repository (actor)
/// await AnalyticsManager.shared.track(.apiCalled)
///
/// // Desde background task
/// Task.detached {
///     await AnalyticsManager.shared.track(.backgroundSync)
/// }
/// ```
///
/// ### Flujo de crossing isolation:
/// - MainActor → actor: async call ✅
/// - actor → actor: async call ✅
/// - detached → actor: async call ✅
///
/// ### Estado mutable compartido:
/// - `providers: [AnalyticsProvider]` - Modificado por configure()
/// - `_isEnabled: Bool` - Modificado por setEnabled()
/// - Sin actor = data race ❌
/// - Con actor = serialización automática ✅
///
/// ## Pattern: Strategy + Composite
/// Usa múltiples providers simultáneamente para:
/// - Development: ConsoleAnalyticsProvider
/// - Production: FirebaseAnalyticsProvider
/// - Opted-out: NoOpAnalyticsProvider
actor AnalyticsManager: AnalyticsService {
    // MARK: - State (actor-isolated)

    /// Providers activos
    ///
    /// ## Concurrency
    /// - actor-isolated: Solo accesible dentro del actor
    /// - Modificado por: configure()
    private var providers: [AnalyticsProvider] = []

    /// Flag de habilitación global
    ///
    /// ## Concurrency
    /// - actor-isolated: Solo accesible dentro del actor
    /// - Modificado por: setEnabled()
    private var _isEnabled: Bool = true

    /// Logger para el manager
    ///
    /// ## Concurrency
    /// - os.Logger es Sendable ✅
    /// - Inmutable (let) garantiza thread-safety
    ///
    /// ## Visibility
    /// - internal: Accesible desde extensiones en mismo módulo
    let logger: Logger

    // MARK: - Singleton

    /// Instancia compartida del manager
    ///
    /// ## Concurrency
    /// - Singleton de actor es thread-safe ✅
    /// - Acceso serializado automáticamente
    static let shared = AnalyticsManager()

    // MARK: - Initialization

    /// Inicializa el manager
    ///
    /// ## Concurrency
    /// - Actor init: Puede llamarse desde cualquier contexto
    /// - Logger inmutable: Sendable, thread-safe
    ///
    /// - Parameter logger: Logger a usar (default: analytics logger)
    init(logger: Logger? = nil) {
        self.logger = logger ?? OSLogger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.edugo.apple-app",
            category: .analytics
        )
    }

    // MARK: - Configuration

    /// Configura el manager con providers
    ///
    /// ## Concurrency
    /// - actor method: Serializa configuración
    /// - async: Permite crossing isolation
    ///
    /// ## Uso
    /// Llamar una vez durante app initialization:
    /// ```swift
    /// await AnalyticsManager.shared.configure(with: [
    ///     ConsoleAnalyticsProvider(),
    ///     FirebaseAnalyticsProvider()
    /// ])
    /// ```
    ///
    /// - Parameter providers: Array de providers a usar
    func configure(with providers: [AnalyticsProvider]) async {
        self.providers = providers

        await logger.info("Configuring analytics with \(providers.count) provider(s)")

        // Inicializar cada provider
        for provider in providers {
            await provider.initialize()
            let available = provider.isAvailable
            await logger.info("Provider '\(provider.name)' initialized (available: \(available))")
        }
    }

    // MARK: - AnalyticsService Implementation

    /// Indica si el tracking está habilitado
    ///
    /// ## Concurrency
    /// - actor-isolated: Acceso al estado _isEnabled
    var isEnabled: Bool {
        get async { _isEnabled }
    }

    /// Habilita o deshabilita el tracking
    ///
    /// ## Concurrency
    /// - actor method: Serializa modificación de _isEnabled
    ///
    /// ## Privacy
    /// Cuando se deshabilita:
    /// - No se envían eventos a ningún provider
    /// - Eventos se descartan silenciosamente
    /// - Respeta opt-out del usuario
    ///
    /// - Parameter enabled: true para habilitar, false para deshabilitar
    func setEnabled(_ enabled: Bool) async {
        let changed = _isEnabled != enabled
        _isEnabled = enabled

        if changed {
            await logger.info("Analytics \(enabled ? "enabled" : "disabled")")
        }
    }

    /// Trackea un evento
    ///
    /// ## Concurrency
    /// - actor method: Serializa acceso a providers y _isEnabled
    /// - async: Permite crossing isolation desde cualquier contexto
    ///
    /// ## Flow
    /// 1. Verifica si tracking está habilitado
    /// 2. Distribuye evento a todos los providers disponibles
    /// 3. Log de éxito/error
    ///
    /// - Parameters:
    ///   - event: Evento a trackear
    ///   - parameters: Parámetros adicionales (opcional)
    func track(_ event: AnalyticsEvent, parameters: [String: String]?) async {
        // Early return si tracking deshabilitado
        guard _isEnabled else {
            return
        }

        // Log del evento
        if let params = parameters {
            await logger.debug("Tracking event: \(event.rawValue)", metadata: [
                "category": "\(event.category.rawValue)",
                "parameter_keys": "\(Array(params.keys))"
            ])
        } else {
            await logger.debug("Tracking event: \(event.rawValue)", metadata: [
                "category": "\(event.category.rawValue)"
            ])
        }

        // Distribuir a todos los providers
        for provider in providers {
            guard provider.isAvailable else { continue }
            await provider.logEvent(event.rawValue, parameters: parameters)
        }
    }

    /// Establece una propiedad de usuario
    ///
    /// ## Concurrency
    /// - actor method: Serializa acceso a providers
    ///
    /// - Parameters:
    ///   - property: Propiedad a establecer
    ///   - value: Valor (nil para remover)
    func setUserProperty(_ property: AnalyticsUserProperty, value: String?) async {
        guard _isEnabled else { return }

        if value != nil {
            await logger.debug("Setting user property: \(property.rawValue) = [REDACTED]")
        } else {
            await logger.debug("Removing user property: \(property.rawValue)")
        }

        // Distribuir a todos los providers
        for provider in providers {
            guard provider.isAvailable else { continue }
            await provider.setUserProperty(property.rawValue, value: value)
        }
    }

    /// Establece el ID del usuario
    ///
    /// ## Concurrency
    /// - actor method: Serializa acceso a providers
    ///
    /// - Parameter userId: ID del usuario (nil para remover)
    func setUserId(_ userId: String?) async {
        guard _isEnabled else { return }

        if userId != nil {
            await logger.info("Setting user ID")
        } else {
            await logger.info("Clearing user ID")
        }

        // Distribuir a todos los providers
        for provider in providers {
            guard provider.isAvailable else { continue }
            await provider.setUserId(userId)
        }
    }

    /// Resetea todos los datos de analytics
    ///
    /// ## Concurrency
    /// - actor method: Serializa acceso a providers
    ///
    /// ## Uso
    /// Llamar al hacer logout para limpiar datos del usuario anterior.
    func reset() async {
        await logger.info("Resetting analytics data")

        // Distribuir a todos los providers
        for provider in providers {
            guard provider.isAvailable else { continue }
            await provider.reset()
        }
    }
}
