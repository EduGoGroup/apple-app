//
//  FeatureFlagDTO.swift
//  EduGoDataLayer
//
//  Created on 28-11-25.
//  SPEC-009: Feature Flags System
//
//  Data Transfer Object para feature flags desde el backend
//

import Foundation
import EduGoDomainCore

/// DTO para un feature flag individual desde el backend
///
/// Mapea la respuesta del endpoint `GET /api/v1/feature-flags`
public struct FeatureFlagDTO: Codable, Sendable {
    /// Identificador único del flag (ej: "biometric_login")
    public let key: String

    /// Si el flag está habilitado para este usuario
    public let enabled: Bool

    /// Metadata adicional del flag
    public let metadata: FeatureFlagMetadataDTO

    public init(key: String, enabled: Bool, metadata: FeatureFlagMetadataDTO) {
        self.key = key
        self.enabled = enabled
        self.metadata = metadata
    }

    /// Mapea este DTO a la entidad de dominio
    ///
    /// - Returns: FeatureFlag de dominio, o nil si el key no es válido
    public func toDomain() -> FeatureFlag? {
        return FeatureFlag(rawValue: key)
    }
}

/// Metadata de un feature flag
public struct FeatureFlagMetadataDTO: Codable, Sendable {
    /// Si requiere reiniciar la app para aplicar cambios
    public let requiresRestart: Bool

    /// Si es una feature experimental
    public let isExperimental: Bool

    /// Prioridad del flag (para ordenamiento)
    public let priority: Int

    enum CodingKeys: String, CodingKey {
        case requiresRestart = "requires_restart"
        case isExperimental = "is_experimental"
        case priority
    }

    public init(requiresRestart: Bool, isExperimental: Bool, priority: Int) {
        self.requiresRestart = requiresRestart
        self.isExperimental = isExperimental
        self.priority = priority
    }
}
