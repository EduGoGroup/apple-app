//
//  AppError.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Error principal de la aplicación que encapsula todos los tipos de errores
public enum AppError: Error, Equatable, Sendable {
    /// Error de red
    case network(NetworkError)

    /// Error de validación
    case validation(ValidationError)

    /// Error de lógica de negocio
    case business(BusinessError)

    /// Error del sistema
    case system(SystemError)

    /// Mensaje amigable para mostrar al usuario
    public var userMessage: String {
        switch self {
        case .network(let error):
            return error.userMessage
        case .validation(let error):
            return error.userMessage
        case .business(let error):
            return error.userMessage
        case .system(let error):
            return error.userMessage
        }
    }

    /// Mensaje técnico para logs y debugging
    public var technicalMessage: String {
        switch self {
        case .network(let error):
            return "Network: \(error.technicalMessage)"
        case .validation(let error):
            return "Validation: \(error.technicalMessage)"
        case .business(let error):
            return "Business: \(error.technicalMessage)"
        case .system(let error):
            return "System: \(error.technicalMessage)"
        }
    }

    /// Indica si el error es recuperable (el usuario puede reintentar)
    public var isRecoverable: Bool {
        switch self {
        case .network(.timeout), .network(.noConnection), .network(.serverError):
            return true
        case .validation:
            return true
        case .business(.tooManyAttempts):
            return false
        case .business(.accountDisabled):
            return false
        case .system(.cancelled):
            return true
        case .system(.outOfMemory):
            return false
        default:
            return true
        }
    }

    /// Indica si se debe mostrar al usuario (algunos errores internos no deben mostrarse)
    public var shouldDisplayToUser: Bool {
        switch self {
        case .system(.cancelled):
            return false
        default:
            return true
        }
    }
}

// MARK: - LocalizedError Conformance
extension AppError: LocalizedError {
    public var errorDescription: String? {
        userMessage
    }

    public var failureReason: String? {
        technicalMessage
    }
}
