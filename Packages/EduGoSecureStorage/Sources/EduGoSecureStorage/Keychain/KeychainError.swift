//
//  KeychainError.swift
//  EduGoSecureStorage
//
//  Created on 16-11-25.
//

import Foundation

/// Errores específicos del servicio de Keychain
public enum KeychainError: Error, Equatable, Sendable {
    /// No se pudo guardar el item en el Keychain
    case unableToSave

    /// No se pudo recuperar el item del Keychain
    case unableToRetrieve

    /// No se pudo eliminar el item del Keychain
    case unableToDelete

    /// El item no fue encontrado en el Keychain
    case itemNotFound

    /// Los datos recuperados no son válidos
    case invalidData

    /// Mensaje descriptivo del error
    public var localizedDescription: String {
        switch self {
        case .unableToSave:
            return "No se pudo guardar el token de forma segura"
        case .unableToRetrieve:
            return "No se pudo recuperar el token del almacenamiento seguro"
        case .unableToDelete:
            return "No se pudo eliminar el token del almacenamiento seguro"
        case .itemNotFound:
            return "El token solicitado no existe"
        case .invalidData:
            return "Los datos recuperados no son válidos"
        }
    }
}
