//
//  LoggingInterceptor.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-004: Network Layer Enhancement - Logging Interceptor
//

import Foundation

/// Interceptor que loggea requests y responses HTTP
final class LoggingInterceptor: RequestInterceptor, ResponseInterceptor, @unchecked Sendable {

    private let logger = LoggerFactory.network

    // MARK: - RequestInterceptor

    @MainActor
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

    @MainActor
    func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data {
        guard let url = response.url else { return data }

        let statusCode = response.statusCode
        let logLevel: String

        switch statusCode {
        case 200..<300:
            logLevel = "info"
            logger.info("HTTP Response", metadata: [
                "url": url.path,
                "status": statusCode.description,
                "size": data.count.description
            ])
        case 400..<500:
            logLevel = "warning"
            logger.warning("HTTP Response - Client Error", metadata: [
                "url": url.path,
                "status": statusCode.description
            ])
        case 500..<600:
            logLevel = "error"
            logger.error("HTTP Response - Server Error", metadata: [
                "url": url.path,
                "status": statusCode.description
            ])
        default:
            logLevel = "debug"
            logger.debug("HTTP Response", metadata: [
                "url": url.path,
                "status": statusCode.description
            ])
        }

        return data
    }
}
