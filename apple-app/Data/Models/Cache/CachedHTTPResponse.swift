//
//  CachedHTTPResponse.swift
//  apple-app
//
//  Created on 25-11-25.
//  SPEC-005: SwiftData Integration - Cached HTTP Response Model
//

import Foundation
import SwiftData

/// Response HTTP cacheado localmente con SwiftData
///
/// Permite persistir responses del backend para uso offline.
/// Se invalida automáticamente al expirar.
///
/// Nota: Renombrado de CachedResponse a CachedHTTPResponse para evitar
/// conflicto con CachedResponse en ResponseCache.swift
@Model
final class CachedHTTPResponse {
    // MARK: - Properties

    @Attribute(.unique) var endpoint: String
    var data: Data
    var expiresAt: Date
    var lastFetched: Date

    // MARK: - Computed Properties

    var isExpired: Bool {
        Date() >= expiresAt
    }

    // MARK: - Initialization

    init(
        endpoint: String,
        data: Data,
        expiresIn: TimeInterval = 300
    ) {
        self.endpoint = endpoint
        self.data = data
        self.expiresAt = Date().addingTimeInterval(expiresIn)
        self.lastFetched = Date()
    }
}
