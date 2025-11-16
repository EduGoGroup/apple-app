//
//  BusinessError.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Errores de lógica de negocio
enum BusinessError: Error, Equatable, Sendable {
    /// Usuario ya existe
    case userAlreadyExists
    
    /// Usuario no encontrado
    case userNotFound
    
    /// Credenciales inválidas
    case invalidCredentials
    
    /// Sesión expirada
    case sessionExpired
    
    /// Cuenta deshabilitada
    case accountDisabled
    
    /// Email no verificado
    case emailNotVerified
    
    /// Operación no permitida
    case operationNotAllowed
    
    /// Límite de intentos excedido
    case tooManyAttempts
    
    /// Recurso no disponible
    case resourceUnavailable
    
    /// Error de negocio personalizado con mensaje
    case custom(String)
    
    /// Mensaje amigable para mostrar al usuario
    var userMessage: String {
        switch self {
        case .userAlreadyExists:
            return "Este usuario ya está registrado."
        case .userNotFound:
            return "Usuario no encontrado."
        case .invalidCredentials:
            return "Email o contraseña incorrectos."
        case .sessionExpired:
            return "Tu sesión ha expirado. Por favor inicia sesión nuevamente."
        case .accountDisabled:
            return "Tu cuenta ha sido deshabilitada. Contacta soporte."
        case .emailNotVerified:
            return "Por favor verifica tu email antes de continuar."
        case .operationNotAllowed:
            return "Esta operación no está permitida."
        case .tooManyAttempts:
            return "Demasiados intentos. Por favor espera un momento."
        case .resourceUnavailable:
            return "El recurso no está disponible en este momento."
        case .custom(let message):
            return message
        }
    }
    
    /// Mensaje técnico para logs y debugging
    var technicalMessage: String {
        switch self {
        case .userAlreadyExists:
            return "Business rule violation: User already exists"
        case .userNotFound:
            return "Business rule violation: User not found"
        case .invalidCredentials:
            return "Business rule violation: Invalid credentials provided"
        case .sessionExpired:
            return "Business rule violation: Session expired"
        case .accountDisabled:
            return "Business rule violation: Account is disabled"
        case .emailNotVerified:
            return "Business rule violation: Email not verified"
        case .operationNotAllowed:
            return "Business rule violation: Operation not allowed"
        case .tooManyAttempts:
            return "Business rule violation: Too many attempts"
        case .resourceUnavailable:
            return "Business rule violation: Resource unavailable"
        case .custom(let message):
            return "Business rule violation: \(message)"
        }
    }
}
