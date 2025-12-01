//
//  StatsRepository.swift
//  apple-app
//
//  Created on 30-11-25.
//  Fase 3: Protocolo para obtener estadísticas del usuario
//

import Foundation

/// Protocolo para obtener estadísticas del usuario
@MainActor
public protocol StatsRepository: Sendable {
    /// Obtiene las estadísticas actuales del usuario
    /// - Returns: Estadísticas del usuario o error
    func getUserStats() async -> Result<UserStats, AppError>
}
