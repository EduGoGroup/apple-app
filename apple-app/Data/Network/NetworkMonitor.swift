//
//  NetworkMonitor.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-004: Network Layer Enhancement - Network Monitor
//

import Foundation
import Network

/// Tipo de conexión de red
enum ConnectionType: Sendable {
    case wifi
    case cellular
    case ethernet
    case unknown
}

/// Monitor de conectividad de red
protocol NetworkMonitor: Sendable {
    var isConnected: Bool { get async }
    var connectionType: ConnectionType { get async }

    /// Stream de cambios de conectividad
    /// - Returns: AsyncStream que emite true cuando hay conexión, false cuando no
    func connectionStream() -> AsyncStream<Bool>
}

/// Implementación usando Network framework de Apple
///
/// ## Swift 6 Concurrency
/// Convertido a actor porque:
/// 1. NWPathMonitor no es Sendable y mantiene estado mutable
/// 2. Múltiples threads pueden consultar el estado de red simultáneamente
/// 3. Actor garantiza acceso thread-safe al monitor y su estado
///
/// FASE 1 - Refactoring: Eliminado @unchecked Sendable, convertido a actor
actor DefaultNetworkMonitor: NetworkMonitor {

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.edugo.network.monitor")
    private var currentPath: NWPath?

    nonisolated var isConnected: Bool {
        get async {
            await withCheckedContinuation { continuation in
                queue.async {
                    let path = self.monitor.currentPath
                    continuation.resume(returning: path.status == .satisfied)
                }
            }
        }
    }

    nonisolated var connectionType: ConnectionType {
        get async {
            await withCheckedContinuation { continuation in
                queue.async {
                    let path = self.monitor.currentPath
                    let type = self.connectionType(from: path)
                    continuation.resume(returning: type)
                }
            }
        }
    }

    init() {
        // Configurar path update handler para cachear el estado
        monitor.pathUpdateHandler = { [weak self] path in
            Task { [weak self] in
                await self?.updatePath(path)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Private Helpers

    private func updatePath(_ path: NWPath) {
        currentPath = path
    }

    private nonisolated func connectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }

    // MARK: - Observable

    /// Stream de cambios de conectividad
    nonisolated func connectionStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            // Handler Sendable para emitir cambios
            let handler: @Sendable (NWPath) -> Void = { path in
                let isConnected = path.status == .satisfied
                continuation.yield(isConnected)
            }

            // Configurar el handler en el queue del monitor
            queue.async {
                self.monitor.pathUpdateHandler = handler

                // Emitir valor inicial
                let currentPath = self.monitor.currentPath
                continuation.yield(currentPath.status == .satisfied)
            }

            continuation.onTermination = { @Sendable [queue, monitor = self.monitor] _ in
                // Limpiar el handler
                queue.async {
                    monitor.pathUpdateHandler = nil
                }
            }
        }
    }
}

// MARK: - Testing

#if DEBUG
/// Mock de NetworkMonitor para testing
///
/// ## Swift 6 Concurrency
/// Convertido a actor para proteger estado mutable sin usar locks.
/// FASE 1 - Refactoring: Eliminado @unchecked Sendable, convertido a actor
actor MockNetworkMonitor: NetworkMonitor {
    var isConnectedValue = true
    var connectionTypeValue: ConnectionType = .wifi

    nonisolated var isConnected: Bool {
        get async {
            await getIsConnected()
        }
    }

    nonisolated var connectionType: ConnectionType {
        get async {
            await getConnectionType()
        }
    }

    func getIsConnected() -> Bool {
        isConnectedValue
    }

    func getConnectionType() -> ConnectionType {
        connectionTypeValue
    }

    nonisolated func connectionStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            Task {
                let value = await getIsConnected()
                continuation.yield(value)
                continuation.finish()
            }
        }
    }

    // Helpers para configurar el mock en tests
    func setConnected(_ connected: Bool) {
        isConnectedValue = connected
    }

    func setConnectionType(_ type: ConnectionType) {
        connectionTypeValue = type
    }

    func reset() {
        isConnectedValue = true
        connectionTypeValue = .wifi
    }
}
#endif
