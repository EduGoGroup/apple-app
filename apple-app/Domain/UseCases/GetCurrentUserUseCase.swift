//
//  GetCurrentUserUseCase.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Protocolo para el caso de uso de obtener usuario actual
protocol GetCurrentUserUseCase: Sendable {
    /// Obtiene el usuario actualmente autenticado
    /// - Returns: Result con el User actual o AppError
    func execute() async -> Result<User, AppError>
}

/// Implementación por defecto del caso de uso de obtener usuario actual
final class DefaultGetCurrentUserUseCase: GetCurrentUserUseCase {
    private let authRepository: AuthRepository
    
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    func execute() async -> Result<User, AppError> {
        // Primero verificamos si hay sesión activa
        let hasSession = await authRepository.hasActiveSession()
        
        guard hasSession else {
            return .failure(.business(.sessionExpired))
        }
        
        // Obtenemos el usuario actual
        let result = await authRepository.getCurrentUser()
        
        // Si falla por no autorizado, intentamos refrescar la sesión
        if case .failure(let error) = result,
           case .network(.unauthorized) = error {
            return await authRepository.refreshSession()
        }
        
        return result
    }
}
