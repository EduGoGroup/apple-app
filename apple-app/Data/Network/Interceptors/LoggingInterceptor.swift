//
//  LoggingInterceptor.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-004: Network Layer Enhancement - Logging Interceptor
//

import Foundation

/// Interceptor que loggea requests y responses HTTP
///
/// ## Swift 6 Concurrency
/// FASE 3 - Refactoring: Eliminado @unchecked Sendable, marcado como @MainActor.
/// Debe ser @MainActor porque:
/// 1. Los interceptores se ejecutan en el contexto de APIClient (@MainActor)
/// 2. Simplifica el modelo de concurrencia del network layer
/// 3. Logger es thread-safe, pero mantener @MainActor es más consistente
@MainActor
final class LoggingInterceptor: RequestInterceptor, ResponseInterceptor {

    private let logger = LoggerFactory.network

    // MARK: - RequestInterceptor

    func intercept(_ request: URLRequest) async throws -> URLRequest {
        guard let url = request.url else { return request }

        logger.info("HTTP Request", metadata: [
            "method": request.httpMethod ?? "GET",
            "url": url.absoluteString,
            "path": url.path
        ])

        return request
    }

    // MARK: - ResponseInterceptor

    func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data {
        guard let url = response.url else { return data }

        let statusCode = response.statusCode

        switch statusCode {
        case 200..<300:
            logger.info("HTTP Response", metadata: [
                "url": url.path,
                "status": statusCode.description,
                "size": data.count.description
            ])
        case 400..<500:
            logger.warning("HTTP Response - Client Error", metadata: [
                "url": url.path,
                "status": statusCode.description
            ])
        case 500..<600:
            logger.error("HTTP Response - Server Error", metadata: [
                "url": url.path,
                "status": statusCode.description
            ])
        default:
            logger.debug("HTTP Response", metadata: [
                "url": url.path,
                "status": statusCode.description
            ])
        }

        return data
    }
}
