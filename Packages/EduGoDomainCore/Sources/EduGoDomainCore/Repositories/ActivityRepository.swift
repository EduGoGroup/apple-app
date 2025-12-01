//
//  ActivityRepository.swift
//  apple-app
//
//  Created on 30-11-25.
//  Fase 3: Protocolo para obtener actividad reciente del usuario
//

import Foundation

/// Protocolo para obtener actividad reciente del usuario
///
/// - Important: Las implementaciones deben ser @MainActor para garantizar
///   thread-safety con SwiftUI
@MainActor
protocol ActivityRepository: Sendable {
    /// Obtiene las actividades recientes del usuario
    /// - Parameter limit: Número máximo de actividades a retornar
    /// - Returns: Lista de actividades ordenadas por fecha (más reciente primero) o error
    func getRecentActivity(limit: Int) async -> Result<[Activity], AppError>
}
