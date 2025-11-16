//
//  KeychainError.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Errores específicos del servicio de Keychain
enum KeychainError: Error, Equatable {
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
    var localizedDescription: String {
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
