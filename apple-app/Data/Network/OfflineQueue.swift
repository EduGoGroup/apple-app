//
//  OfflineQueue.swift
//  apple-app
//
//  Created on 24-01-25.
//  Updated on 25-11-25 - SPEC-004: Process queue implementation
//  Updated on 25-11-25 - SPEC-013: Conflict resolution integration
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

/// Cola para requests offline con persistencia y conflict resolution
///
/// Este actor maneja requests que fallaron por falta de conectividad.
/// Cuando se recupera la conexión, procesa automáticamente la cola.
///
/// ## Swift 6 Concurrency
/// No usa Logger porque es un actor y Logger es @MainActor.
/// El logging se hace en el APIClient que usa esta cola.
///
/// ## SPEC-013: Conflict Resolution
/// Usa snapshot pattern para evitar race conditions durante procesamiento.
/// Integra ConflictResolver para manejar conflictos HTTP 409.
actor OfflineQueue {

    // MARK: - Dependencies

    private let networkMonitor: NetworkMonitor
    private let conflictResolver: ConflictResolver
    private let localDataSource: LocalDataSource?

    private var queue: [QueuedRequest] = []
    private let storageKey = "offline_requests_queue"

    // Callback para ejecutar requests (se configura desde APIClient)
    // El APIClient se encargará del logging y ejecución real
    var executeRequest: ((QueuedRequest) async throws -> Void)?

    // MARK: - Initialization

    init(
        networkMonitor: NetworkMonitor,
        conflictResolver: ConflictResolver,
        localDataSource: LocalDataSource? = nil
    ) {
        self.networkMonitor = networkMonitor
        self.conflictResolver = conflictResolver
        self.localDataSource = localDataSource
        Task { await loadQueue() }
    }

    /// Legacy init for backward compatibility (sin conflict resolver)
    /// Swift 6: Actors no soportan convenience init, duplicar código
    init(networkMonitor: NetworkMonitor) {
        self.networkMonitor = networkMonitor
        // Crear resolver simple inline para evitar problemas de aislamiento
        self.conflictResolver = SimpleConflictResolver()
        self.localDataSource = nil
        Task { await loadQueue() }
    }

    // MARK: - Configuration

    /// Configura el callback para ejecutar requests
    func configure(executor: @escaping (QueuedRequest) async throws -> Void) {
        self.executeRequest = executor
    }

    // MARK: - Public API

    /// Encola un request para ejecución posterior
    func enqueue(_ request: QueuedRequest) async {
        queue.append(request)
        await saveQueue()
    }

    /// Procesa la cola cuando hay conectividad
    ///
    /// ## SPEC-013: Mejoras
    /// - Usa snapshot pattern para evitar race conditions
    /// - Integra conflict resolution para HTTP 409
    /// - Procesa items individualmente con manejo robusto de errores
    func processQueue() async {
        guard await networkMonitor.isConnected else {
            return
        }

        // ✅ SPEC-013: Snapshot inmutable para evitar race conditions
        let snapshot = queue

        guard !snapshot.isEmpty else {
            return
        }

        guard let executor = executeRequest else {
            return
        }

        var successfulRequests: [UUID] = []

        // Procesar cada request del snapshot
        for request in snapshot {
            let wasSuccessful = await processItem(request, executor: executor)
            if wasSuccessful {
                successfulRequests.append(request.id)
            }
        }

        // Remover requests exitosos
        queue.removeAll { successfulRequests.contains($0.id) }

        // Limpiar requests muy antiguos (>24h) que ya no tienen sentido
        let yesterday = Date().addingTimeInterval(-86400)
        queue.removeAll { $0.timestamp < yesterday }

        await saveQueue()
    }

    /// Procesa un item individual de la cola
    /// - Parameters:
    ///   - request: Request a procesar
    ///   - executor: Función que ejecuta el request
    /// - Returns: true si fue exitoso, false si falló
    private func processItem(
        _ request: QueuedRequest,
        executor: @escaping (QueuedRequest) async throws -> Void
    ) async -> Bool {
        do {
            try await executor(request)
            return true

        } catch let error as NetworkError where error.isConflict {
            // ✅ SPEC-013: Manejar conflicto HTTP 409
            await handleConflict(for: request, error: error)
            return false

        } catch {
            // Otros errores: mantener en cola para reintentar
            return false
        }
    }

    /// Maneja un conflicto de sincronización (HTTP 409)
    /// - Parameters:
    ///   - request: Request que causó el conflicto
    ///   - error: Error del servidor con datos actuales
    private func handleConflict(
        for request: QueuedRequest,
        error: NetworkError
    ) async {
        // Por ahora: estrategia simple (server wins)
        // TODO: Implementar UI para resolución manual cuando sea necesario

        // Crear conflicto (struct simple, no requiere aislamiento)
        let conflict = SyncConflict(
            localData: request.body ?? Data(),
            serverData: Data(), // TODO: Extraer del error cuando esté disponible
            timestamp: request.timestamp,
            endpoint: request.url.absoluteString,
            metadata: [:]
        )

        // Resolver conflicto
        let _ = await conflictResolver.resolve(
            conflict,
            strategy: .serverWins
        )

        // Por ahora: remover de cola (server wins)
        // En el futuro: podríamos actualizar el request con datos resueltos
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

    /// Cantidad de requests pendientes (alias de count)
    func pendingCount() async -> Int {
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
