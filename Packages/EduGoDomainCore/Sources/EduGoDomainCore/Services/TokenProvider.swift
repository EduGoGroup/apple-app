//
//  TokenProvider.swift
//  EduGoDomainCore
//
//  Created on 30-11-25.
//  Sprint 3: Protocol for token provision to break circular dependency
//

import Foundation

// MARK: - Token Provider Protocol

/// Protocolo de dominio para obtener tokens de autenticación
///
/// Este protocolo permite que la capa de datos (DataLayer) obtenga tokens
/// sin depender directamente de la implementación de seguridad (SecurityKit).
/// Rompe la dependencia circular: DataLayer ↔ SecurityKit
///
/// ## Implementación
/// - `TokenRefreshCoordinator` en EduGoSecurityKit implementa este protocolo
/// - `AuthInterceptor` en EduGoDataLayer consume este protocolo
///
/// ## Swift 6 Concurrency
/// El protocolo es `Sendable` y usa `async throws` para compatibilidad
/// con sistemas de autenticación que requieren refresh asíncrono.
public protocol TokenProvider: Sendable {
    /// Obtiene un token válido para autenticación
    /// - Returns: TokenInfo con el token actual (puede refrescarse automáticamente)
    /// - Throws: Error si no hay token disponible o el refresh falla
    func getValidToken() async throws -> TokenInfo
}
