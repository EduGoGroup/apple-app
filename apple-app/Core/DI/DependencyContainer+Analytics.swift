//
//  DependencyContainer+Analytics.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-011 & SPEC-012: Analytics and Performance Integration
//

import Foundation

/// Extension para configurar Analytics y Performance Monitoring
extension DependencyContainer {
    /// Configura el sistema de analytics
    ///
    /// ## Providers
    /// - Development: ConsoleAnalyticsProvider (debug en consola)
    /// - Production: Agregar FirebaseAnalyticsProvider cuando esté listo
    ///
    /// ## Concurrency
    /// - async: Llama a actor methods (AnalyticsManager.configure)
    ///
    /// ## Uso
    /// Llamar una vez durante app initialization.
    @MainActor
    func setupAnalytics() async {
        let analytics = AnalyticsManager.shared

        // Configurar providers según ambiente
        #if DEBUG
        await analytics.configure(with: [
            ConsoleAnalyticsProvider()  // Solo console en debug
        ])
        #else
        await analytics.configure(with: [
            ConsoleAnalyticsProvider(),
            FirebaseAnalyticsProvider()  // Agregar cuando Firebase esté integrado
        ])
        #endif

        // Establecer propiedades iniciales de la app
        await analytics.setUserProperty(.appVersion, value: "0.1.0")
        await analytics.setUserProperty(.appEnvironment, value: AppEnvironment.displayName)
        await analytics.setUserProperty(.platform, value: "\(PlatformCapabilities.currentDevice)")
    }

    /// Configura el sistema de performance monitoring
    ///
    /// ## Monitors
    /// - DefaultPerformanceMonitor: Traces y métricas generales
    /// - MemoryMonitor: Uso de memoria (polling cada 30s)
    /// - NetworkMetricsTracker: Métricas de red (integrado con APIClient)
    ///
    /// ## Concurrency
    /// - async: Llama a actor methods
    ///
    /// ## Uso
    /// Llamar una vez durante app initialization.
    @MainActor
    func setupPerformanceMonitoring() async {
        // Launch time tracking ya inició en app init

        // Iniciar memory monitoring
        #if DEBUG
        await MemoryMonitor.shared.startMonitoring(interval: 30)
        #else
        // En producción, solo monitorear cada 60s para ahorrar batería
        await MemoryMonitor.shared.startMonitoring(interval: 60)
        #endif

        // Network metrics se integran automáticamente con APIClient
    }

    /// Detiene el performance monitoring
    ///
    /// ## Concurrency
    /// - async: Llama a actor methods
    ///
    /// ## Uso
    /// Llamar al cerrar la app o en tests.
    @MainActor
    func stopPerformanceMonitoring() async {
        await MemoryMonitor.shared.stopMonitoring()
    }
}
