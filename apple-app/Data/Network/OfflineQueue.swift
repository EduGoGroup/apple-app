//
//  OfflineQueue.swift
//  apple-app
//
//  Created on 24-01-25.
//  Updated on 25-11-25 - SPEC-004: Process queue implementation
//

import Foundation

/// Request encolado para ejecución offline
struct QueuedRequest: Codable, Sendable {
    let id: UUID
    let url: URL
    let method: String
    let headers: [String: String]
    let body: Data?
    let timestamp: Date

    init(url: URL, method: String, headers: [String: String] = [:], body: Data? = nil) {
        self.id = UUID()
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.timestamp = Date()
    }
}

/// Cola para requests offline con persistencia
///
/// Este actor maneja requests que fallaron por falta de conectividad.
/// Cuando se recupera la conexión, procesa automáticamente la cola.
///
/// ## Swift 6 Concurrency
/// No usa Logger porque es un actor y Logger es @MainActor.
/// El logging se hace en el APIClient que usa esta cola.
actor OfflineQueue {

    // MARK: - Dependencies

    private let networkMonitor: NetworkMonitor
    private var queue: [QueuedRequest] = []
    private let storageKey = "offline_requests_queue"

    // Callback para ejecutar requests (se configura desde APIClient)
    // El APIClient se encargará del logging y ejecución real
    var executeRequest: ((QueuedRequest) async throws -> Void)?

    // MARK: - Initialization

    init(networkMonitor: NetworkMonitor) {
        self.networkMonitor = networkMonitor
        Task { await loadQueue() }
    }

    // MARK: - Public API

    /// Encola un request para ejecución posterior
    func enqueue(_ request: QueuedRequest) async {
        queue.append(request)
        await saveQueue()
    }

    /// Procesa la cola cuando hay conectividad
    func processQueue() async {
        guard await networkMonitor.isConnected else {
            return
        }

        guard !queue.isEmpty else {
            return
        }

        guard let executor = executeRequest else {
            return
        }

        var successfulRequests: [UUID] = []

        // Procesar cada request
        for request in queue {
            do {
                try await executor(request)
                successfulRequests.append(request.id)
            } catch {
                // Mantener en cola para reintentar después
                // Solo se remueven requests exitosos
            }
        }

        // Remover requests exitosos
        queue.removeAll { successfulRequests.contains($0.id) }

        // Limpiar requests muy antiguos (>24h) que ya no tienen sentido
        let yesterday = Date().addingTimeInterval(-86400)
        queue.removeAll { $0.timestamp < yesterday }

        await saveQueue()
    }

    /// Limpia la cola completa
    func clear() async {
        queue.removeAll()
        await saveQueue()
    }

    /// Cantidad de requests encolados
    func count() async -> Int {
        queue.count
    }

    /// Obtiene todos los requests encolados (para debugging)
    func allRequests() async -> [QueuedRequest] {
        queue
    }

    // MARK: - Persistence

    private func saveQueue() async {
        guard let encoded = try? JSONEncoder().encode(queue) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }

    private func loadQueue() async {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([QueuedRequest].self, from: data) else {
            return
        }
        queue = decoded
    }
}
