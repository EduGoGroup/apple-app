//
//  APIClient.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Protocolo para cliente API
protocol APIClient: Sendable {
    /// Ejecuta una request HTTP
    /// - Parameters:
    ///   - endpoint: Endpoint a consumir
    ///   - method: Método HTTP
    ///   - body: Body opcional para enviar
    /// - Returns: Objeto decodificado del tipo T
    /// - Throws: NetworkError si algo falla
    func execute<T: Decodable>(
        endpoint: Endpoint,
        method: HTTPMethod,
        body: (any Encodable & Sendable)?
    ) async throws -> T
}

/// Implementación por defecto del cliente API usando URLSession
final class DefaultAPIClient: APIClient, @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    init(
        baseURL: URL,
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }
    
    func execute<T: Decodable>(
        endpoint: Endpoint,
        method: HTTPMethod,
        body: (any Encodable & Sendable)? = nil
    ) async throws -> T {
        // Construir URL
        let url = baseURL.appendingPathComponent(endpoint.path)
        
        // Crear request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Agregar token de autenticación si existe (para futuro)
        // Se implementará cuando tengamos KeychainService
        
        // Agregar body si existe
        if let body = body {
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw NetworkError.decodingError
            }
        }
        
        // Ejecutar request
        let (data, response) = try await session.data(for: request)
        
        // Validar respuesta HTTP
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError(0)
        }
        
        // Manejar códigos de estado
        try validateStatusCode(httpResponse.statusCode)
        
        // Decodificar respuesta
        do {
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    // MARK: - Private Helpers
    
    private func validateStatusCode(_ statusCode: Int) throws {
        guard (200...299).contains(statusCode) else {
            switch statusCode {
            case 400:
                throw NetworkError.badRequest("Bad request")
            case 401:
                throw NetworkError.unauthorized
            case 403:
                throw NetworkError.forbidden
            case 404:
                throw NetworkError.notFound
            case 408:
                throw NetworkError.timeout
            default:
                throw NetworkError.serverError(statusCode)
            }
        }
    }
}

// MARK: - Helper para codificar Any Encodable

private struct AnyEncodable: Encodable {
    private let encodable: any Encodable
    
    init(_ encodable: any Encodable) {
        self.encodable = encodable
    }
    
    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
