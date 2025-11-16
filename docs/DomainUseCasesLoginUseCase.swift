//
//  LoginUseCase.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Protocolo para el caso de uso de login
protocol LoginUseCase: Sendable {
    /// Ejecuta el proceso de login con validaciones
    /// - Parameters:
    ///   - email: Email del usuario
    ///   - password: Contraseña del usuario
    /// - Returns: Result con el User autenticado o AppError
    func execute(email: String, password: String) async -> Result<User, AppError>
}

/// Implementación por defecto del caso de uso de login
final class DefaultLoginUseCase: LoginUseCase {
    private let authRepository: AuthRepository
    private let validator: InputValidator
    
    init(authRepository: AuthRepository, validator: InputValidator = DefaultInputValidator()) {
        self.authRepository = authRepository
        self.validator = validator
    }
    
    func execute(email: String, password: String) async -> Result<User, AppError> {
        // Validación: Email vacío
        guard !email.isEmpty else {
            return .failure(.validation(.emptyEmail))
        }
        
        // Validación: Formato de email
        guard validator.isValidEmail(email) else {
            return .failure(.validation(.invalidEmailFormat))
        }
        
        // Validación: Contraseña vacía
        guard !password.isEmpty else {
            return .failure(.validation(.emptyPassword))
        }
        
        // Validación: Longitud de contraseña
        guard validator.isValidPassword(password) else {
            return .failure(.validation(.passwordTooShort))
        }
        
        // Delegación al repositorio
        return await authRepository.login(email: email, password: password)
    }
}
