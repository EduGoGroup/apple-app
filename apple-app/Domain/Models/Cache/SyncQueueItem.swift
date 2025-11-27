//
//  SyncQueueItem.swift
//  apple-app
//
//  Created on 25-11-25.
//  SPEC-005: SwiftData Integration - Sync Queue Item Model
//

import Foundation
import SwiftData

/// Item en cola de sincronización
///
/// Representa una operación que debe sincronizarse con el backend
/// cuando haya conexión disponible.
@Model
final class SyncQueueItem {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID
    var endpoint: String
    var method: String
    var body: Data?
    var createdAt: Date
    var attempts: Int
    var lastAttemptAt: Date?
    var error: String?

    // MARK: - Initialization

    init(
        endpoint: String,
        method: String,
        body: Data? = nil
    ) {
        self.id = UUID()
        self.endpoint = endpoint
        self.method = method
        self.body = body
        self.createdAt = Date()
        self.attempts = 0
    }

    // MARK: - Methods

    /// Marca un intento de sincronización
    func recordAttempt(error: String? = nil) {
        self.attempts += 1
        self.lastAttemptAt = Date()
        self.error = error
    }

    /// Indica si debe descartarse (muy viejo o muchos intentos)
    var shouldDiscard: Bool {
        // Descartar después de 24 horas o 5 intentos fallidos
        let isOld = Date().timeIntervalSince(createdAt) > 86400
        let tooManyAttempts = attempts >= 5
        return isOld || tooManyAttempts
    }
}
