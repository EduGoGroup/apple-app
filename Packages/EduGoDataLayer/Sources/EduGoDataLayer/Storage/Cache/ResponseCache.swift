//
//  ResponseCache.swift
//  EduGoDataLayer
//
//  Created on 25-11-25.
//  SPEC-004: Network Layer Enhancement - Response Caching
//

import Foundation

/// Response cacheado con expiración
public struct CachedResponse: Sendable {
    public let data: Data
    public let expiresAt: Date
    public let cachedAt: Date

    public init(data: Data, expiresAt: Date, cachedAt: Date) {
        self.data = data
        self.expiresAt = expiresAt
        self.cachedAt = cachedAt
    }

    /// Indica si el cache expiró
    public nonisolated var isExpired: Bool {
        Date() >= expiresAt
    }

    /// Tiempo restante de validez (en segundos)
    public nonisolated var timeRemaining: TimeInterval {
        expiresAt.timeIntervalSinceNow
    }
}

/// Cache thread-safe para responses HTTP
///
/// ## Swift 6 Concurrency
/// FASE 2 - Refactoring: Eliminado @unchecked Sendable y NSCache wrapper.
/// Marcado como @MainActor porque:
/// 1. Solo se usa desde APIClient (que es @MainActor)
/// 2. No requiere actor separation (no hay contención)
/// 3. Dictionary simple más eficiente que NSCache
@MainActor
public final class ResponseCache {
    // MARK: - Storage

    private var storage: [String: CachedResponse] = [:]
    private let defaultTTL: TimeInterval
    private let maxEntries: Int
    private let maxTotalSize: Int

    // MARK: - Initialization

    public init(
        defaultTTL: TimeInterval = 300,
        maxEntries: Int = 100,
        maxTotalSize: Int = 10 * 1024 * 1024 // 10 MB
    ) {
        self.defaultTTL = defaultTTL
        self.maxEntries = maxEntries
        self.maxTotalSize = maxTotalSize
    }

    // MARK: - Public API

    /// Obtiene un response cacheado si existe y no ha expirado
    public func get(for url: URL) -> CachedResponse? {
        let key = url.absoluteString

        guard let response = storage[key] else {
            return nil
        }

        // Si expiró, remover y retornar nil
        if response.isExpired {
            storage.removeValue(forKey: key)
            return nil
        }

        return response
    }

    /// Guarda un response en caché
    public func set(_ data: Data, for url: URL, ttl: TimeInterval? = nil) {
        let expiresIn = ttl ?? defaultTTL

        let response = CachedResponse(
            data: data,
            expiresAt: Date().addingTimeInterval(expiresIn),
            cachedAt: Date()
        )

        let key = url.absoluteString

        // Verificar límites antes de agregar
        if storage.count >= maxEntries {
            evictOldest()
        }

        storage[key] = response

        // Verificar tamaño total
        if currentTotalSize > maxTotalSize {
            evictUntilSize(maxTotalSize)
        }
    }

    /// Invalida el cache para una URL específica
    public func invalidate(for url: URL) {
        let key = url.absoluteString
        storage.removeValue(forKey: key)
    }

    /// Limpia todo el cache
    public func clearAll() {
        storage.removeAll()
    }

    /// Limpia entries expirados
    public func clearExpired() {
        storage = storage.filter { !$0.value.isExpired }
    }

    // MARK: - Private Helpers

    /// Tamaño total del cache en bytes
    private var currentTotalSize: Int {
        storage.values.reduce(0) { $0 + $1.data.count }
    }

    /// Elimina el entry más antiguo
    private func evictOldest() {
        guard let oldest = storage.min(by: { $0.value.cachedAt < $1.value.cachedAt }) else {
            return
        }
        storage.removeValue(forKey: oldest.key)
    }

    /// Elimina entries hasta alcanzar el tamaño objetivo
    private func evictUntilSize(_ targetSize: Int) {
        while currentTotalSize > targetSize && !storage.isEmpty {
            evictOldest()
        }
    }
}
