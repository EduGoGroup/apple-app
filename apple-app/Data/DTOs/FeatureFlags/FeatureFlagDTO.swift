//
//  FeatureFlagDTO.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-009: Feature Flags System
//
//  Data Transfer Object para feature flags desde el backend
//

import Foundation

/// DTO para un feature flag individual desde el backend
///
/// Mapea la respuesta del endpoint `GET /api/v1/feature-flags`
struct FeatureFlagDTO: Codable, Sendable {
    /// Identificador único del flag (ej: "biometric_login")
    let key: String

    /// Si el flag está habilitado para este usuario
    let enabled: Bool

    /// Metadata adicional del flag
    let metadata: FeatureFlagMetadataDTO

    /// Mapea este DTO a la entidad de dominio
    ///
    /// - Returns: FeatureFlag de dominio, o nil si el key no es válido
    func toDomain() -> FeatureFlag? {
        return FeatureFlag(rawValue: key)
    }
}

/// Metadata de un feature flag
struct FeatureFlagMetadataDTO: Codable, Sendable {
    /// Si requiere reiniciar la app para aplicar cambios
    let requiresRestart: Bool

    /// Si es una feature experimental
    let isExperimental: Bool

    /// Prioridad del flag (para ordenamiento)
    let priority: Int

    enum CodingKeys: String, CodingKey {
        case requiresRestart = "requires_restart"
        case isExperimental = "is_experimental"
        case priority
    }
}
