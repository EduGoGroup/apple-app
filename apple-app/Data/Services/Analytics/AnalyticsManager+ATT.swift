//
//  AnalyticsManager+ATT.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-011: Analytics & Telemetry - App Tracking Transparency
//

import Foundation
import AppTrackingTransparency

/// Extension de AnalyticsManager para App Tracking Transparency
///
/// ## Responsabilidad
/// - Solicitar permiso de tracking al usuario (ATT)
/// - Cumplir con requisitos de App Store
/// - Gestionar estado de autorización
///
/// ## Concurrency (CRÍTICO)
/// - **@MainActor:** ATTrackingManager requiere main thread ⚠️
/// - **Extension de actor:** Método @MainActor dentro de actor ✅
///
/// ## Por qué @MainActor
///
/// ATTrackingManager.requestTrackingAuthorization() tiene requisitos:
/// 1. Debe llamarse desde main thread
/// 2. Muestra UI (alert de permiso)
/// 3. No es Sendable (API legacy)
///
/// ## Flujo de crossing isolation
/// ```swift
/// // Desde ViewModel (@MainActor)
/// let status = await analytics.requestTrackingAuthorization()
/// // ✅ MainActor → actor (async)
/// // ✅ Dentro del actor, @MainActor method se ejecuta en main
/// ```
///
/// ## App Store Requirement
/// - Mostrar purpose string en Info.plist
/// - Solicitar antes de cualquier tracking
/// - Respetar respuesta del usuario
extension AnalyticsManager {
    /// Solicita autorización de tracking al usuario
    ///
    /// ## Concurrency
    /// - **@MainActor:** ATTrackingManager requiere main thread
    /// - **async:** Permite crossing desde actor a MainActor
    ///
    /// ## UI
    /// Muestra alert nativo del sistema con el mensaje configurado
    /// en Info.plist (NSUserTrackingUsageDescription).
    ///
    /// ## Privacy
    /// - Solo llamar si el tracking es necesario
    /// - Respetar la respuesta del usuario
    /// - No llamar múltiples veces innecesariamente
    ///
    /// ## Uso
    /// ```swift
    /// let status = await AnalyticsManager.shared.requestTrackingAuthorization()
    /// if status == .authorized {
    ///     await analytics.setEnabled(true)
    /// } else {
    ///     await analytics.setEnabled(false)
    /// }
    /// ```
    ///
    /// - Returns: Estado de autorización de tracking
    @MainActor
    func requestTrackingAuthorization() async -> ATTrackingManager.AuthorizationStatus {
        // Log antes de solicitar
        await logger.info("Requesting App Tracking Transparency authorization")

        // Solicitar autorización (muestra UI nativa)
        let status = await ATTrackingManager.requestTrackingAuthorization()

        // Log del resultado
        await logger.info("ATT authorization result: \(status.rawValue)")

        return status
    }

    /// Obtiene el estado actual de autorización sin solicitar permiso
    ///
    /// ## Concurrency
    /// - Synchronous: Propiedad estática sin side effects
    /// - nonisolated: No requiere actor isolation
    ///
    /// ## Uso
    /// Para verificar el estado sin mostrar el alert al usuario.
    ///
    /// - Returns: Estado actual de autorización
    nonisolated func trackingAuthorizationStatus() -> ATTrackingManager.AuthorizationStatus {
        ATTrackingManager.trackingAuthorizationStatus
    }
}
