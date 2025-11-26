//
//  ConflictResolution.swift
//  apple-app
//
//  Created on 25-11-25.
//  SPEC-013: Offline-First Strategy - Conflict Resolution
//

import Foundation

// MARK: - Conflict Resolution Strategy

/// Estrategia para resolver conflictos entre datos locales y del servidor
///
/// Cuando un usuario edita datos offline y el servidor también los modifica,
/// necesitamos una estrategia para resolver el conflicto.
enum ConflictResolutionStrategy: Sendable {
    /// El servidor siempre gana (default seguro)
    case serverWins

    /// El cliente siempre gana (usar con cuidado)
    case clientWins

    /// Gana el dato con timestamp más reciente
    case newerWins

    /// Requiere intervención manual del usuario
    case manual
}

// MARK: - Sync Conflict

/// Representa un conflicto entre datos locales y del servidor
///
/// Contiene ambas versiones de los datos para que el resolver
/// pueda tomar una decisión informada.
struct SyncConflict: Sendable {
    /// Datos locales (del cliente)
    let localData: Data

    /// Datos del servidor
    let serverData: Data

    /// Timestamp del request original
    let timestamp: Date

    /// Endpoint donde ocurrió el conflicto
    let endpoint: String

    /// Metadata adicional (opcional)
    let metadata: [String: String]
}

// MARK: - Conflict Resolver Protocol

/// Protocol para resolver conflictos de sincronización
///
/// Implementaciones pueden tener diferentes estrategias según el contexto.
protocol ConflictResolver: Sendable {
    /// Resuelve un conflicto usando la estrategia especificada
    /// - Parameters:
    ///   - conflict: El conflicto a resolver
    ///   - strategy: Estrategia de resolución
    /// - Returns: Los datos resueltos que se deben usar
    func resolve(
        _ conflict: SyncConflict,
        strategy: ConflictResolutionStrategy
    ) async -> Data
}

// MARK: - Simple Implementation (Struct)

/// Implementación simple del conflict resolver (sin actor)
///
/// Swift 6: Struct simple que implementa resolución sin aislamiento.
/// Seguro para usar desde cualquier contexto, incluyendo actors.
struct SimpleConflictResolver: ConflictResolver {

    func resolve(
        _ conflict: SyncConflict,
        strategy: ConflictResolutionStrategy
    ) async -> Data {
        switch strategy {
        case .serverWins:
            return conflict.serverData

        case .clientWins:
            return conflict.localData

        case .newerWins:
            // Por ahora: server wins (más seguro)
            // TODO: Comparar timestamps cuando backend los provea
            return conflict.serverData

        case .manual:
            // Por ahora: server wins
            // TODO: Implementar UI para resolución manual
            return conflict.serverData
        }
    }
}

// MARK: - Actor Implementation

/// Implementación avanzada del conflict resolver con actor
///
/// Usa actor para thread-safety en resolución asíncrona compleja.
/// Por ahora implementa estrategias simples, se puede extender
/// para casos más complejos que requieran estado mutable.
///
/// Swift 6: Actor sin @MainActor para permitir uso desde otros actors
actor DefaultConflictResolver: ConflictResolver {

    // MARK: - Public Methods

    func resolve(
        _ conflict: SyncConflict,
        strategy: ConflictResolutionStrategy
    ) async -> Data {
        switch strategy {
        case .serverWins:
            return resolveServerWins(conflict)

        case .clientWins:
            return resolveClientWins(conflict)

        case .newerWins:
            return resolveNewerWins(conflict)

        case .manual:
            // Por ahora, manual defaults a server wins
            // TODO: Implementar UI para resolución manual
            return resolveServerWins(conflict)
        }
    }

    // MARK: - Private Resolution Methods

    /// Resolución: El servidor siempre gana
    private func resolveServerWins(_ conflict: SyncConflict) -> Data {
        conflict.serverData
    }

    /// Resolución: El cliente siempre gana
    private func resolveClientWins(_ conflict: SyncConflict) -> Data {
        conflict.localData
    }

    /// Resolución: Gana el dato más reciente
    ///
    /// Por ahora, asume que server data es más reciente (default seguro).
    /// TODO: Comparar timestamps reales cuando el backend los provea.
    private func resolveNewerWins(_ conflict: SyncConflict) -> Data {
        // Por ahora: server wins (más seguro)
        // En el futuro: comparar timestamps de metadata
        conflict.serverData
    }
}
