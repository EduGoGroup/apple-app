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
    private let logger = LoggerFactory.network

    // SPEC-004: Interceptors & Network Features
    private let requestInterceptors: [RequestInterceptor]
    private let responseInterceptors: [ResponseInterceptor]
    private let retryPolicy: RetryPolicy
    private let networkMonitor: NetworkMonitor
    private let offlineQueue: OfflineQueue?
    private let responseCache: ResponseCache?

    init(
        baseURL: URL,
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        certificatePinner: CertificatePinner? = nil,  // SPEC-008: SSL Pinning
        requestInterceptors: [RequestInterceptor] = [],
        responseInterceptors: [ResponseInterceptor] = [],
        retryPolicy: RetryPolicy = .default,
        networkMonitor: NetworkMonitor? = nil,
        offlineQueue: OfflineQueue? = nil,  // SPEC-004: Offline support
        responseCache: ResponseCache? = nil  // SPEC-004: Response caching
    ) {
        self.baseURL = baseURL
        self.encoder = encoder
        self.decoder = decoder
        self.requestInterceptors = requestInterceptors
        self.responseInterceptors = responseInterceptors
        self.retryPolicy = retryPolicy
        self.networkMonitor = networkMonitor ?? DefaultNetworkMonitor()
        self.offlineQueue = offlineQueue
        self.responseCache = responseCache

        // SPEC-008: Configurar URLSession con certificate pinning si está disponible
        if certificatePinner != nil {
            // Extraer hashes del pinner (CertificatePinner tiene los hashes)
            // Creamos SecureSessionDelegate con los hashes directamente para evitar actor boundaries
            let pinnedHashes: Set<String> = []  // TODO: Extraer de pinner cuando tengamos API
            let delegate = SecureSessionDelegate(pinnedPublicKeyHashes: pinnedHashes)
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = AppEnvironment.apiTimeout
            self.session = URLSession(
                configuration: configuration,
                delegate: delegate,
                delegateQueue: nil
            )
        } else {
            self.session = session
        }
    }

    @MainActor
    func execute<T: Decodable>(
        endpoint: Endpoint,
        method: HTTPMethod,
        body: (any Encodable & Sendable)? = nil
    ) async throws -> T {
        // Construir URL
        let url = endpoint.url(baseURL: baseURL)

        // SPEC-004: Verificar cache para requests GET (solo si no hay body)
        if method == .get, body == nil, let cache = responseCache {
            if let cachedResponse = cache.get(for: url) {
                logger.debug("Cache hit", metadata: ["url": url.absoluteString])
                return try decoder.decode(T.self, from: cachedResponse.data)
            }
        }

        // Crear request base
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Agregar body si existe
        if let body = body {
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                logger.error("Failed to encode request body", metadata: [
                    "error": error.localizedDescription
                ])
                throw NetworkError.decodingError
            }
        }

        // SPEC-004: Aplicar request interceptors
        for interceptor in requestInterceptors {
            request = try await interceptor.intercept(request)
        }

        // SPEC-004: Ejecutar con retry policy
        return try await executeWithRetry(request: request)
    }

    // MARK: - SPEC-004: Retry Logic

    @MainActor
    private func executeWithRetry<T: Decodable>(request: URLRequest, attempt: Int = 0) async throws -> T {
        do {
            // Ejecutar request
            let (data, response) = try await session.data(for: request)

            // Validar respuesta HTTP
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.serverError(0)
            }

            // SPEC-004: Aplicar response interceptors
            var processedData = data
            for interceptor in responseInterceptors {
                processedData = try await interceptor.intercept(httpResponse, data: processedData)
            }

            // Verificar status code
            let statusCode = httpResponse.statusCode

            // Si es retryable y tenemos intentos restantes, reintentar
            if retryPolicy.shouldRetry(statusCode: statusCode, attempt: attempt) {
                let delay = retryPolicy.backoffStrategy.delay(for: attempt)

                logger.warning("Request failed, retrying", metadata: [
                    "status": statusCode.description,
                    "attempt": attempt.description,
                    "delay": delay.description
                ])

                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeWithRetry(request: request, attempt: attempt + 1)
            }

            // Validar status code final
            guard (200..<300).contains(statusCode) else {
                switch statusCode {
                case 401:
                    throw NetworkError.unauthorized
                case 404:
                    throw NetworkError.notFound
                case 500..<600:
                    throw NetworkError.serverError(statusCode)
                default:
                    throw NetworkError.serverError(statusCode)
                }
            }

            // Decodificar response
            do {
                let decoded = try decoder.decode(T.self, from: processedData)

                // SPEC-004: Cachear response exitoso (solo para GET requests)
                if request.httpMethod == "GET", let cache = responseCache {
                    cache.set(processedData, for: request.url!)
                }

                return decoded
            } catch {
                logger.error("Failed to decode response", metadata: [
                    "error": error.localizedDescription
                ])
                throw NetworkError.decodingError
            }

        } catch let error as NetworkError {
            // SPEC-004: Encolar request si no hay conexión (para retry posterior)
            if error == .noConnection, let queue = offlineQueue {
                let queuedRequest = QueuedRequest(
                    url: request.url!,
                    method: request.httpMethod ?? "GET",
                    headers: request.allHTTPHeaderFields ?? [:],
                    body: request.httpBody
                )

                Task {
                    await queue.enqueue(queuedRequest)
                }

                logger.info("Request enqueued for offline retry", metadata: [
                    "url": request.url!.absoluteString
                ])
            }

            throw error
        } catch {
            throw NetworkError.serverError(0)
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
