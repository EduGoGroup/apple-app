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
    var userMessage: String {
        switch self {
        case .noConnection:
            return "No hay conexión a internet. Verifica tu red."
        case .timeout:
            return "La operación tardó demasiado. Intenta de nuevo."
        case .serverError(let code):
            return "Error del servidor (\(code)). Intenta más tarde."
        case .unauthorized:
            return "Tu sesión ha expirado. Por favor inicia sesión nuevamente."
        case .forbidden:
            return "No tienes permisos para realizar esta acción."
        case .notFound:
            return "El recurso solicitado no fue encontrado."
        case .badRequest(let message):
            return message.isEmpty ? "Petición inválida." : message
        case .decodingError:
            return "Error al procesar la respuesta del servidor."
        case .unknown:
            return "Ocurrió un error de red. Intenta de nuevo."
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
