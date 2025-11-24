//
//  RequestInterceptor.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-004: Network Layer Enhancement - Interceptor Pattern
//

import Foundation

/// Protocol para interceptar y modificar requests HTTP antes de ser enviados
protocol RequestInterceptor: Sendable {
    /// Intercepta y modifica un URLRequest
    /// - Parameter request: Request original
    /// - Returns: Request modificado
    /// - Throws: Error si la intercepción falla
    func intercept(_ request: URLRequest) async throws -> URLRequest
}

/// Protocol para interceptar y procesar responses HTTP
protocol ResponseInterceptor: Sendable {
    /// Intercepta y procesa una respuesta HTTP
    /// - Parameters:
    ///   - response: HTTPURLResponse recibida
    ///   - data: Data de la respuesta
    /// - Returns: Data procesada
    /// - Throws: Error si el procesamiento falla
    func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data
}
