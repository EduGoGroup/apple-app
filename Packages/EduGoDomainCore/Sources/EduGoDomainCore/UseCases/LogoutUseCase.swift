//
//  LogoutUseCase.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Protocolo para el caso de uso de logout
///
/// Aislado a MainActor porque depende de AuthRepository que es @MainActor
/// y es usado por ViewModels que también son @MainActor.
@MainActor
public protocol LogoutUseCase: Sendable {
    /// Ejecuta el proceso de cierre de sesión
    /// - Returns: Result con Void en éxito o AppError
    func execute() async -> Result<Void, AppError>
}

/// Implementación por defecto del caso de uso de logout
@MainActor
public final class DefaultLogoutUseCase: LogoutUseCase {
    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    public func execute() async -> Result<Void, AppError> {
        // Delegación directa al repositorio
        // No requiere validaciones adicionales
        await authRepository.logout()
    }
}
