//
//  LogoutUseCase.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Protocolo para el caso de uso de logout
/// Con Swift 6.2 Default MainActor Isolation, Sendable es implícito
protocol LogoutUseCase {
    /// Ejecuta el proceso de cierre de sesión
    /// - Returns: Result con Void en éxito o AppError
    func execute() async -> Result<Void, AppError>
}

/// Implementación por defecto del caso de uso de logout
final class DefaultLogoutUseCase: LogoutUseCase {
    private let authRepository: AuthRepository
    
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    func execute() async -> Result<Void, AppError> {
        // Delegación directa al repositorio
        // No requiere validaciones adicionales
        return await authRepository.logout()
    }
}
