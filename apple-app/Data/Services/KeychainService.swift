//
//  KeychainService.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation
import Security

/// Protocolo para gestión segura de tokens en Keychain
protocol KeychainService: Sendable {
    /// Guarda un token de forma segura en el Keychain
    /// - Parameters:
    ///   - token: El token a guardar
    ///   - key: La clave identificadora del token
    /// - Throws: KeychainError si la operación falla
    func saveToken(_ token: String, for key: String) async throws

    /// Recupera un token del Keychain
    /// - Parameter key: La clave identificadora del token
    /// - Returns: El token si existe, nil si no se encuentra
    /// - Throws: KeychainError si la operación falla
    func getToken(for key: String) async throws -> String?

    /// Elimina un token del Keychain
    /// - Parameter key: La clave identificadora del token
    /// - Throws: KeychainError si la operación falla
    func deleteToken(for key: String) async throws
}

/// Implementación por defecto del servicio de Keychain
final class DefaultKeychainService: KeychainService {
    /// Instancia compartida del servicio
    static let shared = DefaultKeychainService()

    private let logger = LoggerFactory.data

    private init() {}

    func saveToken(_ token: String, for key: String) async throws {
        await logger.debug("Saving token to Keychain", metadata: ["key": key])

        guard let data = token.data(using: .utf8) else {
            await logger.error("Failed to convert token to data", metadata: ["key": key])
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Eliminar item existente si lo hay
        SecItemDelete(query as CFDictionary)

        // Agregar nuevo item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            await logger.error("Failed to save token to Keychain", metadata: [
                "key": key,
                "status": "\(status)"
            ])
            throw KeychainError.unableToSave
        }

        await logger.info("Token saved to Keychain successfully", metadata: ["key": key])
    }

    func getToken(for key: String) async throws -> String? {
        await logger.debug("Retrieving token from Keychain", metadata: ["key": key])

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        // Si no se encuentra, retornar nil (no es error)
        if status == errSecItemNotFound {
            await logger.debug("Token not found in Keychain", metadata: ["key": key])
            return nil
        }

        guard status == errSecSuccess else {
            await logger.error("Failed to retrieve token from Keychain", metadata: [
                "key": key,
                "status": "\(status)"
            ])
            throw KeychainError.unableToRetrieve
        }

        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            await logger.error("Invalid token data in Keychain", metadata: ["key": key])
            throw KeychainError.invalidData
        }

        await logger.info("Token retrieved from Keychain successfully", metadata: ["key": key])
        return token
    }

    func deleteToken(for key: String) async throws {
        await logger.debug("Deleting token from Keychain", metadata: ["key": key])

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        // Éxito si se eliminó o si no existía
        guard status == errSecSuccess || status == errSecItemNotFound else {
            await logger.error("Failed to delete token from Keychain", metadata: [
                "key": key,
                "status": "\(status)"
            ])
            throw KeychainError.unableToDelete
        }

        if status == errSecItemNotFound {
            await logger.debug("Token was not in Keychain", metadata: ["key": key])
        } else {
            await logger.info("Token deleted from Keychain successfully", metadata: ["key": key])
        }
    }
}
