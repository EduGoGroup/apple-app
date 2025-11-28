//
//  CachedFeatureFlag.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-009: Feature Flags System
//
//  Modelo de cache para feature flags usando SwiftData
//  NOTA: Este archivo está en Data Layer, NO en Domain Layer (Clean Architecture)
//

import Foundation
import SwiftData

/// Modelo de cache para un feature flag
///
/// Almacena el valor de un feature flag en cache local usando SwiftData.
///
/// ## Arquitectura
/// - Ubicación: Data Layer (Data/Models/Cache/)
/// - Persistencia: SwiftData
/// - Uso: Solo por FeatureFlagRepository
///
/// ## TTL y Expiración
/// El cache tiene un tiempo de vida (TTL) configurable.
/// Valores expirados deben revalidarse con el backend.
///
/// - Note: Cumple Clean Architecture - @Model en Data Layer
@Model
final class CachedFeatureFlag {
    /// Key del feature flag (ej: "biometric_login")
    @Attribute(.unique) var key: String

    /// Valor del flag (habilitado/deshabilitado)
    var enabled: Bool

    /// Fecha de última sincronización con backend
    var lastSyncDate: Date

    /// TTL en segundos (tiempo de vida del cache)
    var ttlSeconds: Int

    /// Fecha de creación del cache
    var createdAt: Date

    // MARK: - Initialization

    init(key: String, enabled: Bool, lastSyncDate: Date, ttlSeconds: Int) {
        self.key = key
        self.enabled = enabled
        self.lastSyncDate = lastSyncDate
        self.ttlSeconds = ttlSeconds
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    /// Verifica si el cache está expirado
    var isExpired: Bool {
        let expirationDate = lastSyncDate.addingTimeInterval(TimeInterval(ttlSeconds))
        return Date() > expirationDate
    }

    /// Convierte a FeatureFlag de dominio
    ///
    /// - Returns: FeatureFlag o nil si el key no es válido
    var toDomain: FeatureFlag? {
        return FeatureFlag(rawValue: key)
    }
}
