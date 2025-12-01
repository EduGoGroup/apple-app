//
//  FeatureFlagsResponseDTO.swift
//  EduGoDataLayer
//
//  Created on 28-11-25.
//  SPEC-009: Feature Flags System
//
//  DTO para la respuesta completa del backend de feature flags
//

import Foundation
import EduGoDomainCore

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
public struct FeatureFlagsResponseDTO: Codable, Sendable {
    public let success: Bool
    public let data: FeatureFlagsDataDTO
    public let timestamp: Date

    public init(success: Bool, data: FeatureFlagsDataDTO, timestamp: Date) {
        self.success = success
        self.data = data
        self.timestamp = timestamp
    }

    /// Convierte todos los flags a un diccionario de dominio
    ///
    /// - Returns: Diccionario con flags válidos y sus valores
    public func toDomainDictionary() -> [FeatureFlag: Bool] {
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
public struct FeatureFlagsDataDTO: Codable, Sendable {
    public let flags: [FeatureFlagDTO]
    public let syncMetadata: SyncMetadataDTO

    enum CodingKeys: String, CodingKey {
        case flags
        case syncMetadata = "sync_metadata"
    }

    public init(flags: [FeatureFlagDTO], syncMetadata: SyncMetadataDTO) {
        self.flags = flags
        self.syncMetadata = syncMetadata
    }
}

/// Metadata de sincronización
public struct SyncMetadataDTO: Codable, Sendable {
    /// Timestamp del servidor
    public let serverTimestamp: Date

    /// TTL de cache en segundos
    public let cacheTTLSeconds: Int

    /// Total de flags disponibles
    public let totalFlags: Int

    enum CodingKeys: String, CodingKey {
        case serverTimestamp = "server_timestamp"
        case cacheTTLSeconds = "cache_ttl_seconds"
        case totalFlags = "total_flags"
    }

    public init(serverTimestamp: Date, cacheTTLSeconds: Int, totalFlags: Int) {
        self.serverTimestamp = serverTimestamp
        self.cacheTTLSeconds = cacheTTLSeconds
        self.totalFlags = totalFlags
    }
}
