//
//  OfflineQueue.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-004: Network Layer Enhancement - Offline Queue
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
actor OfflineQueue {

    // MARK: - Dependencies

    private let networkMonitor: NetworkMonitor
    private var queue: [QueuedRequest] = []
    private let storageKey = "offline_requests_queue"

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
        guard await networkMonitor.isConnected else { return }
        guard !queue.isEmpty else { return }

        // Procesar requests encolados (implementación futura completa)
        // Por ahora solo limpiamos requests antiguos (>24h)
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
