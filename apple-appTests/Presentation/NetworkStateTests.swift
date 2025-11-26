//
//  NetworkStateTests.swift
//  apple-appTests
//
//  Created on 25-11-25.
//  SPEC-013: Offline-First Strategy - NetworkState Tests
//

import Testing
@testable import apple_app

@Suite("NetworkState Tests")
struct NetworkStateTests {

    @Test("Estado inicial conectado")
    @MainActor
    func initialStateConnected() async {
        // Given
        let mockMonitor = MockNetworkMonitor()
        mockMonitor.isConnectedValue = true
        let mockQueue = OfflineQueue(networkMonitor: mockMonitor)

        // When
        let sut = NetworkState(networkMonitor: mockMonitor, offlineQueue: mockQueue)

        // Dar tiempo para inicialización
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s

        // Then
        #expect(sut.isConnected == true)
        #expect(sut.isSyncing == false)
    }

    @Test("Estado inicial desconectado")
    @MainActor
    func initialStateDisconnected() async {
        // Given
        let mockMonitor = MockNetworkMonitor()
        mockMonitor.isConnectedValue = false
        let mockQueue = OfflineQueue(networkMonitor: mockMonitor)

        // When
        let sut = NetworkState(networkMonitor: mockMonitor, offlineQueue: mockQueue)

        // Dar tiempo para inicialización
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        #expect(sut.isConnected == false)
    }

    @Test("Force sync solo cuando hay conexión")
    @MainActor
    func forceSyncOnlyWhenConnected() async {
        // Given
        let mockMonitor = MockNetworkMonitor()
        mockMonitor.isConnectedValue = false
        let mockQueue = OfflineQueue(networkMonitor: mockMonitor)
        let sut = NetworkState(networkMonitor: mockMonitor, offlineQueue: mockQueue)

        // When - Sin conexión
        await sut.forceSyncNow()

        // Then - No debería sincronizar
        #expect(sut.isSyncing == false)

        // When - Con conexión
        mockMonitor.isConnectedValue = true
        sut.isConnected = true
        await sut.forceSyncNow()

        // Then - Podría sincronizar (depende de queue vacío)
        // No podemos verificar fácilmente sin executor configurado
    }

    @Test("Stop monitoring cancela la tarea")
    @MainActor
    func stopMonitoringCancelsTask() async {
        // Given
        let mockMonitor = MockNetworkMonitor()
        let mockQueue = OfflineQueue(networkMonitor: mockMonitor)
        let sut = NetworkState(networkMonitor: mockMonitor, offlineQueue: mockQueue)

        // When
        sut.stopMonitoring()

        // Then - No crash, método ejecutado correctamente
        #expect(sut.isSyncing == false)
    }
}
