//
//  NetworkError.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Errores relacionados con operaciones de red
enum NetworkError: Error, Equatable, Sendable {
    /// No hay conexión a internet
    case noConnection

    /// Tiempo de espera agotado
    case timeout

    /// Error del servidor con código HTTP
    case serverError(Int)

    /// No autorizado (401)
    case unauthorized

    /// Prohibido (403)
    case forbidden

    /// No encontrado (404)
    case notFound

    /// Petición incorrecta con mensaje específico
    case badRequest(String)

    /// Error de decodificación de respuesta
    case decodingError

    /// Error desconocido de red
    case unknown

    /// Mensaje amigable para mostrar al usuario
    /// SPEC-010: Migrado a Localizable.xcstrings
    var userMessage: String {
        switch self {
        case .noConnection:
            return String(localized: "error.network.noConnection")
        case .timeout:
            return String(localized: "error.network.timeout")
        case .serverError(let code):
            return String(localized: "error.network.serverError", defaultValue: "Error del servidor (\(code)). Intenta más tarde.")
        case .unauthorized:
            return String(localized: "error.network.unauthorized")
        case .forbidden:
            return String(localized: "error.network.forbidden")
        case .notFound:
            return String(localized: "error.network.notFound")
        case .badRequest(let message):
            return message.isEmpty ? String(localized: "error.network.badRequest") : message
        case .decodingError:
            return String(localized: "error.network.decodingError")
        case .unknown:
            return String(localized: "error.network.unknown")
        }
    }

    /// Mensaje técnico para logs y debugging
    var technicalMessage: String {
        switch self {
        case .noConnection:
            return "Network connection unavailable"
        case .timeout:
            return "Request timeout exceeded"
        case .serverError(let code):
            return "Server returned error code: \(code)"
        case .unauthorized:
            return "HTTP 401: Unauthorized"
        case .forbidden:
            return "HTTP 403: Forbidden"
        case .notFound:
            return "HTTP 404: Not Found"
        case .badRequest(let message):
            return "HTTP 400: Bad Request - \(message)"
        case .decodingError:
            return "Failed to decode response data"
        case .unknown:
            return "Unknown network error occurred"
        }
    }

    /// Indica si el error es un conflicto de sincronización (HTTP 409)
    /// - SPEC-013: Usado por OfflineQueue para conflict resolution
    var isConflict: Bool {
        if case .serverError(409) = self {
            return true
        }
        return false
    }
}
