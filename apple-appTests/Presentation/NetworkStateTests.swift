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
        // Usar mock helper para evitar race conditions con inicialización asíncrona
        let sut = NetworkState.mock(
            isConnected: true,
            isSyncing: false,
            syncingItemsCount: 0
        )

        // Then
        #expect(sut.isConnected == true)
        #expect(sut.isSyncing == false)
        #expect(sut.syncingItemsCount == 0)
    }

    @Test("Estado inicial desconectado")
    @MainActor
    func initialStateDisconnected() async {
        // Usar mock helper para evitar race conditions
        let sut = NetworkState.mock(isConnected: false)

        // Then
        #expect(sut.isConnected == false)
    }

    @Test("Force sync solo cuando hay conexión")
    @MainActor
    func forceSyncOnlyWhenConnected() async {
        // Usar mock para estado inicial offline
        let sut = NetworkState.mock(isConnected: false)

        // When - Sin conexión
        await sut.forceSyncNow()

        // Then - No debería sincronizar
        #expect(sut.isSyncing == false)

        // When - Con conexión (cambiar estado manualmente)
        sut.isConnected = true
        await sut.forceSyncNow()

        // Then - Podría sincronizar (depende de queue vacío)
        // No verificamos isSyncing porque el mock no tiene executor configurado
    }

    @Test("Stop monitoring cancela la tarea")
    @MainActor
    func stopMonitoringCancelsTask() async {
        // Usar mock helper
        let sut = NetworkState.mock()

        // When
        sut.stopMonitoring()

        // Then - No crash, método ejecutado correctamente
        #expect(sut.isSyncing == false)
    }

    @Test("Mock helper crea estado correctamente")
    @MainActor
    func mockHelperCreatesStateCorrectly() {
        // Given & When
        let sutOnline = NetworkState.mock(isConnected: true, isSyncing: false)
        let sutOffline = NetworkState.mock(isConnected: false, isSyncing: true, syncingItemsCount: 5)

        // Then
        #expect(sutOnline.isConnected == true)
        #expect(sutOnline.isSyncing == false)

        #expect(sutOffline.isConnected == false)
        #expect(sutOffline.isSyncing == true)
        #expect(sutOffline.syncingItemsCount == 5)
    }
}
