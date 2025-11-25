//
//  ResponseCache.swift
//  apple-app
//
//  Created on 25-11-25.
//  SPEC-004: Network Layer Enhancement - Response Caching
//

import Foundation

/// Response cacheado con expiración
struct CachedResponse: Sendable {
    let data: Data
    let expiresAt: Date
    let cachedAt: Date

    /// Indica si el cache expiró
    var isExpired: Bool {
        Date() >= expiresAt
    }

    /// Tiempo restante de validez (en segundos)
    var timeRemaining: TimeInterval {
        expiresAt.timeIntervalSinceNow
    }
}

/// Cache thread-safe para responses HTTP
///
/// Usa NSCache (thread-safe nativo) para gestión automática de memoria.
/// Los responses expiran según TTL configurado (default: 5 minutos).
///
/// NSCache es thread-safe, por lo que NO necesita actor.
final class ResponseCache: @unchecked Sendable {

    // MARK: - Storage

    private let cache = NSCache<NSString, CachedResponseWrapper>()
    private let defaultTTL: TimeInterval

    // MARK: - Initialization

    init(defaultTTL: TimeInterval = 300) {
        self.defaultTTL = defaultTTL

        // Configurar límites de caché
        cache.countLimit = 100  // Máximo 100 responses
        cache.totalCostLimit = 10 * 1024 * 1024  // 10 MB
    }

    // MARK: - Public API

    /// Obtiene un response cacheado si existe y no ha expirado
    func get(for url: URL) -> CachedResponse? {
        let key = cacheKey(for: url)

        guard let wrapper = cache.object(forKey: key) else {
            return nil
        }

        let response = wrapper.response

        // Si expiró, remover y retornar nil
        if Date() >= response.expiresAt {
            cache.removeObject(forKey: key)
            return nil
        }

        return response
    }

    /// Guarda un response en caché
    func set(_ data: Data, for url: URL, ttl: TimeInterval? = nil) {
        let expiresIn = ttl ?? defaultTTL

        let response = CachedResponse(
            data: data,
            expiresAt: Date().addingTimeInterval(expiresIn),
            cachedAt: Date()
        )

        let wrapper = CachedResponseWrapper(response: response)
        let key = cacheKey(for: url)
        let cost = data.count

        cache.setObject(wrapper, forKey: key, cost: cost)
    }

    /// Invalida el cache para una URL específica
    func invalidate(for url: URL) {
        let key = cacheKey(for: url)
        cache.removeObject(forKey: key)
    }

    /// Limpia todo el cache
    func clearAll() {
        cache.removeAllObjects()
    }

    // MARK: - Private

    private func cacheKey(for url: URL) -> NSString {
        url.absoluteString as NSString
    }
}

// MARK: - Wrapper para NSCache

/// Wrapper para CachedResponse porque NSCache requiere class
private final class CachedResponseWrapper: @unchecked Sendable {
    let response: CachedResponse

    init(response: CachedResponse) {
        self.response = response
    }
}
