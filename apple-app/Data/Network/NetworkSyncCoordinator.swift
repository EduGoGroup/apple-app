//
//  NetworkSyncCoordinator.swift
//  apple-app
//
//  Created on 25-11-25.
//  SPEC-004: Network Layer Enhancement - Auto-sync Coordinator
//

import Foundation

/// Coordinador que sincroniza automáticamente cuando se recupera la conexión
///
/// Este actor monitorea los cambios de conectividad y automáticamente
/// procesa la cola offline cuando se detecta que hay conexión nuevamente.
///
/// ## Uso
/// ```swift
/// let coordinator = NetworkSyncCoordinator(
///     networkMonitor: networkMonitor,
///     offlineQueue: offlineQueue
/// )
/// coordinator.startMonitoring()
/// ```
actor NetworkSyncCoordinator {
    // MARK: - Dependencies

    private let networkMonitor: NetworkMonitor
    private let offlineQueue: OfflineQueue

    // MARK: - State

    private var monitoringTask: Task<Void, Never>?
    private var isMonitoring = false

    // MARK: - Initialization

    init(networkMonitor: NetworkMonitor, offlineQueue: OfflineQueue) {
        self.networkMonitor = networkMonitor
        self.offlineQueue = offlineQueue
    }

    // MARK: - Public API

    /// Inicia el monitoreo de cambios de red
    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true

        monitoringTask = Task { [networkMonitor, offlineQueue] in
            // Observar cambios de conectividad
            let stream = await MainActor.run {
                networkMonitor.connectionStream()
            }

            for await isConnected in stream {
                if isConnected {
                    // Conexión recuperada, procesar cola offline
                    await offlineQueue.processQueue()
                }
            }
        }
    }

    /// Detiene el monitoreo
    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        isMonitoring = false
    }

    /// Fuerza una sincronización inmediata
    func syncNow() async {
        guard await networkMonitor.isConnected else {
            return
        }

        await offlineQueue.processQueue()
    }
}
