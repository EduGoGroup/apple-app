//
//  ValidationError.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Errores de validación de datos de entrada
enum ValidationError: Error, Equatable, Sendable {
    /// Email vacío
    case emptyEmail
    
    /// Formato de email inválido
    case invalidEmailFormat
    
    /// Contraseña vacía
    case emptyPassword
    
    /// Contraseña demasiado corta
    case passwordTooShort
    
    /// Las contraseñas no coinciden
    case passwordMismatch
    
    /// Nombre vacío
    case emptyName
    
    /// Nombre demasiado corto
    case nameTooShort
    
    /// Campo requerido vacío con nombre del campo
    case requiredField(String)
    
    /// Formato inválido con mensaje específico
    case invalidFormat(String)
    
    /// Mensaje amigable para mostrar al usuario
    var userMessage: String {
        switch self {
        case .emptyEmail:
            return "El email es requerido."
        case .invalidEmailFormat:
            return "El formato del email es inválido."
        case .emptyPassword:
            return "La contraseña es requerida."
        case .passwordTooShort:
            return "La contraseña debe tener al menos 6 caracteres."
        case .passwordMismatch:
            return "Las contraseñas no coinciden."
        case .emptyName:
            return "El nombre es requerido."
        case .nameTooShort:
            return "El nombre debe tener al menos 2 caracteres."
        case .requiredField(let field):
            return "El campo '\(field)' es requerido."
        case .invalidFormat(let message):
            return message
        }
    }
    
    /// Mensaje técnico para logs y debugging
    var technicalMessage: String {
        switch self {
        case .emptyEmail:
            return "Validation failed: Email field is empty"
        case .invalidEmailFormat:
            return "Validation failed: Email format is invalid"
        case .emptyPassword:
            return "Validation failed: Password field is empty"
        case .passwordTooShort:
            return "Validation failed: Password length < 6 characters"
        case .passwordMismatch:
            return "Validation failed: Passwords do not match"
        case .emptyName:
            return "Validation failed: Name field is empty"
        case .nameTooShort:
            return "Validation failed: Name length < 2 characters"
        case .requiredField(let field):
            return "Validation failed: Required field '\(field)' is empty"
        case .invalidFormat(let message):
            return "Validation failed: \(message)"
        }
    }
}
