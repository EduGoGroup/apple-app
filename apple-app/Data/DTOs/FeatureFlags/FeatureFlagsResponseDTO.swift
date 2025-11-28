//
//  FeatureFlagsResponseDTO.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-009: Feature Flags System
//
//  DTO para la respuesta completa del backend de feature flags
//

import Foundation

/// Respuesta completa del backend para feature flags
///
/// Mapea la respuesta de `GET /api/v1/feature-flags`
///
/// Ejemplo JSON:
/// ```json
/// {
///   "success": true,
///   "data": {
///     "flags": [...],
///     "sync_metadata": {...}
///   },
///   "timestamp": "2025-11-28T10:30:00Z"
/// }
/// ```
struct FeatureFlagsResponseDTO: Codable, Sendable {
    let success: Bool
    let data: FeatureFlagsDataDTO
    let timestamp: Date

    /// Convierte todos los flags a un diccionario de dominio
    ///
    /// - Returns: Diccionario con flags válidos y sus valores
    func toDomainDictionary() -> [FeatureFlag: Bool] {
        var result: [FeatureFlag: Bool] = [:]

        for flagDTO in data.flags {
            if let flag = flagDTO.toDomain() {
                result[flag] = flagDTO.enabled
            }
        }

        return result
    }
}

/// Datos de la respuesta de feature flags
struct FeatureFlagsDataDTO: Codable, Sendable {
    let flags: [FeatureFlagDTO]
    let syncMetadata: SyncMetadataDTO

    enum CodingKeys: String, CodingKey {
        case flags
        case syncMetadata = "sync_metadata"
    }
}

/// Metadata de sincronización
struct SyncMetadataDTO: Codable, Sendable {
    /// Timestamp del servidor
    let serverTimestamp: Date

    /// TTL de cache en segundos
    let cacheTTLSeconds: Int

    /// Total de flags disponibles
    let totalFlags: Int

    enum CodingKeys: String, CodingKey {
        case serverTimestamp = "server_timestamp"
        case cacheTTLSeconds = "cache_ttl_seconds"
        case totalFlags = "total_flags"
    }
}
