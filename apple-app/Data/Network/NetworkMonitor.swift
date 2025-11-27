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
/// FASE 3 - Fix Copilot: Eliminado dead code (currentPath, updatePath) y corregido handler overwrites
actor DefaultNetworkMonitor: NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.edugo.network.monitor")

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
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Private Helpers

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
    ///
    /// FASE 3 - Fix Copilot: Corregido para usar polling en vez de sobreescribir pathUpdateHandler.
    /// Esto permite múltiples observers sin perder listeners previos.
    nonisolated func connectionStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let task = Task {
                // Emitir valor inicial
                let initial = await self.isConnected
                continuation.yield(initial)

                // Polling cada segundo para detectar cambios
                var lastValue = initial
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1))
                    let current = await self.isConnected
                    if current != lastValue {
                        continuation.yield(current)
                        lastValue = current
                    }
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
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
