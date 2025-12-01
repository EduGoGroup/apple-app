//
//  BusinessError.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Errores de lógica de negocio
public enum BusinessError: Error, Equatable, Sendable {
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
    /// SPEC-010: Migrado a Localizable.xcstrings
    public var userMessage: String {
        switch self {
        case .userAlreadyExists:
            return String(localized: "error.business.userAlreadyExists")
        case .userNotFound:
            return String(localized: "error.business.userNotFound")
        case .invalidCredentials:
            return String(localized: "error.business.invalidCredentials")
        case .sessionExpired:
            return String(localized: "error.business.sessionExpired")
        case .accountDisabled:
            return String(localized: "error.business.accountDisabled")
        case .emailNotVerified:
            return String(localized: "error.business.emailNotVerified")
        case .operationNotAllowed:
            return String(localized: "error.business.operationNotAllowed")
        case .tooManyAttempts:
            return String(localized: "error.business.tooManyAttempts")
        case .resourceUnavailable:
            return String(localized: "error.business.resourceUnavailable")
        case .custom(let message):
            return message
        }
    }

    /// Mensaje técnico para logs y debugging
    public var technicalMessage: String {
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
