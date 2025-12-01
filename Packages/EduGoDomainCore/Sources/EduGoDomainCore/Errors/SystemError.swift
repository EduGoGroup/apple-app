//
//  SystemError.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Errores del sistema y operaciones de bajo nivel
public enum SystemError: Error, Equatable, Sendable {
    /// Error desconocido
    case unknown

    /// Error de Keychain
    case keychainError

    /// Error de persistencia (UserDefaults, archivos, etc.)
    case persistenceError

    /// Memoria insuficiente
    case outOfMemory

    /// Operación cancelada
    case cancelled

    /// Biometría no disponible
    case biometryNotAvailable

    /// Biometría no configurada
    case biometryNotEnrolled

    /// Autenticación biométrica fallida
    case biometryFailed

    /// Error de permisos del sistema
    case permissionDenied(String)

    /// Error del sistema con mensaje específico
    case system(String)

    /// Mensaje amigable para mostrar al usuario
    public var userMessage: String {
        switch self {
        case .unknown:
            return "Ocurrió un error inesperado. Por favor intenta de nuevo."
        case .keychainError:
            return "Error al acceder al almacenamiento seguro."
        case .persistenceError:
            return "Error al guardar los datos. Intenta de nuevo."
        case .outOfMemory:
            return "Memoria insuficiente. Cierra otras aplicaciones."
        case .cancelled:
            return "Operación cancelada."
        case .biometryNotAvailable:
            return "Face ID/Touch ID no está disponible en este dispositivo."
        case .biometryNotEnrolled:
            return "Face ID/Touch ID no está configurado. Configúralo en Ajustes."
        case .biometryFailed:
            return "La autenticación biométrica falló. Intenta de nuevo."
        case .permissionDenied(let permission):
            return "Permiso denegado: \(permission). Ve a Ajustes para habilitarlo."
        case .system(let message):
            return message.isEmpty ? "Error del sistema." : message
        }
    }

    /// Mensaje técnico para logs y debugging
    public var technicalMessage: String {
        switch self {
        case .unknown:
            return "Unknown system error occurred"
        case .keychainError:
            return "Keychain operation failed"
        case .persistenceError:
            return "Persistence operation failed"
        case .outOfMemory:
            return "System out of memory"
        case .cancelled:
            return "Operation was cancelled"
        case .biometryNotAvailable:
            return "Biometry hardware not available"
        case .biometryNotEnrolled:
            return "Biometry not enrolled on device"
        case .biometryFailed:
            return "Biometry authentication failed"
        case .permissionDenied(let permission):
            return "Permission denied: \(permission)"
        case .system(let message):
            return "System error: \(message)"
        }
    }
}
