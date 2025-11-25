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
final class DefaultNetworkMonitor: NetworkMonitor, @unchecked Sendable {

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.edugo.network.monitor")

    var isConnected: Bool {
        get async {
            await withCheckedContinuation { continuation in
                queue.async {
                    let path = self.monitor.currentPath
                    continuation.resume(returning: path.status == .satisfied)
                }
            }
        }
    }

    var connectionType: ConnectionType {
        get async {
            await withCheckedContinuation { continuation in
                queue.async {
                    let path = self.monitor.currentPath

                    if path.usesInterfaceType(.wifi) {
                        continuation.resume(returning: .wifi)
                    } else if path.usesInterfaceType(.cellular) {
                        continuation.resume(returning: .cellular)
                    } else if path.usesInterfaceType(.wiredEthernet) {
                        continuation.resume(returning: .ethernet)
                    } else {
                        continuation.resume(returning: .unknown)
                    }
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

    // MARK: - Observable

    /// Stream de cambios de conectividad
    func connectionStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            monitor.pathUpdateHandler = { path in
                let isConnected = path.status == .satisfied
                continuation.yield(isConnected)
            }

            continuation.onTermination = { @Sendable _ in
                // Cleanup si es necesario
            }
        }
    }
}

// MARK: - Testing

#if DEBUG
final class MockNetworkMonitor: NetworkMonitor, @unchecked Sendable {
    var isConnectedValue = true
    var connectionTypeValue: ConnectionType = .wifi

    var isConnected: Bool {
        get async { isConnectedValue }
    }

    var connectionType: ConnectionType {
        get async { connectionTypeValue }
    }

    func connectionStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            // Mock: Solo emite el valor actual
            continuation.yield(isConnectedValue)
            continuation.finish()
        }
    }
}
#endif
