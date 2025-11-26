//
//  NetworkState.swift
//  apple-app
//
//  Created on 25-11-25.
//  SPEC-013: Offline-First Strategy - Network State Management
//

import Foundation
import Observation

/// Estado global de conectividad y sincronización
///
/// Gestiona el estado de la red y la sincronización offline de manera centralizada.
/// Usa @Observable para actualizaciones reactivas en SwiftUI.
///
/// Ejemplo de uso:
/// ```swift
/// struct ContentView: View {
///     @State private var networkState = NetworkState(...)
///
///     var body: some View {
///         VStack {
///             if !networkState.isConnected {
///                 OfflineBanner()
///             }
///         }
///     }
/// }
/// ```
@MainActor
@Observable
final class NetworkState {

    // MARK: - Properties

    /// Indica si hay conexión a internet
    var isConnected: Bool = true

    /// Indica si se está sincronizando la cola offline
    var isSyncing: Bool = false

    /// Número de elementos pendientes de sincronizar
    var syncingItemsCount: Int = 0

    /// Tipo de conexión actual (wifi, cellular, etc.)
    var connectionType: ConnectionType = .unknown

    // MARK: - Dependencies

    private let networkMonitor: NetworkMonitor
    private let offlineQueue: OfflineQueue

    // MARK: - Private Properties

    private var monitoringTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Inicializa el estado de red
    /// - Parameters:
    ///   - networkMonitor: Monitor de conectividad
    ///   - offlineQueue: Cola de requests offline
    init(networkMonitor: NetworkMonitor, offlineQueue: OfflineQueue) {
        self.networkMonitor = networkMonitor
        self.offlineQueue = offlineQueue

        // Iniciar monitoreo automáticamente
        startMonitoring()
    }

    // MARK: - Public Methods

    /// Fuerza una sincronización manual de la cola offline
    func forceSyncNow() async {
        guard isConnected else {
            return
        }

        await syncOfflineQueue()
    }

    /// Detiene el monitoreo de red
    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    // MARK: - Private Methods

    /// Inicia el monitoreo de cambios de conectividad
    private func startMonitoring() {
        // Cancelar monitoreo previo si existe
        stopMonitoring()

        // Crear nueva tarea de monitoreo
        monitoringTask = Task { @MainActor in
            // Obtener estado inicial
            await updateInitialState()

            // Monitorear cambios
            for await connected in networkMonitor.connectionStream() {
                await handleConnectionChange(connected)
            }
        }
    }

    /// Actualiza el estado inicial de conectividad
    private func updateInitialState() async {
        async let connected = networkMonitor.isConnected
        async let type = networkMonitor.connectionType
        async let count = offlineQueue.pendingCount()

        isConnected = await connected
        connectionType = await type
        syncingItemsCount = await count
    }

    /// Maneja cambios en la conectividad
    /// - Parameter connected: true si hay conexión, false si no
    private func handleConnectionChange(_ connected: Bool) async {
        // Actualizar estado de conexión
        isConnected = connected
        connectionType = await networkMonitor.connectionType

        // Si recuperamos conexión, sincronizar cola offline
        if connected {
            await syncOfflineQueue()
        }
    }

    /// Sincroniza la cola de requests offline
    private func syncOfflineQueue() async {
        // Evitar sincronizaciones concurrentes
        guard !isSyncing else {
            return
        }

        // Marcar como sincronizando
        isSyncing = true
        syncingItemsCount = await offlineQueue.pendingCount()

        // Procesar cola
        await offlineQueue.processQueue()

        // Actualizar contadores
        syncingItemsCount = await offlineQueue.pendingCount()
        isSyncing = false
    }
}

// MARK: - Testing Support

#if DEBUG
extension NetworkState {
    /// Crea un NetworkState para testing con mocks
    static func mock(
        isConnected: Bool = true,
        isSyncing: Bool = false,
        syncingItemsCount: Int = 0
    ) -> NetworkState {
        let mockMonitor = MockNetworkMonitor()
        mockMonitor.isConnectedValue = isConnected

        // OfflineQueue con mock monitor
        let mockQueue = OfflineQueue(networkMonitor: mockMonitor)

        let state = NetworkState(
            networkMonitor: mockMonitor,
            offlineQueue: mockQueue
        )

        state.isConnected = isConnected
        state.isSyncing = isSyncing
        state.syncingItemsCount = syncingItemsCount

        return state
    }
}
#endif
