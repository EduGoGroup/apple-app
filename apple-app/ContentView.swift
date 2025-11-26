//
//  ContentView.swift
//  apple-app
//
//  Created by Jhoan Medina on 15-11-25.
//  Updated on 25-11-25 - SPEC-013: Offline-First UI Integration
//

import SwiftUI

struct ContentView: View {

    // MARK: - Environment

    @EnvironmentObject private var container: DependencyContainer

    // MARK: - State

    @State private var networkState: NetworkState?

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Contenido principal
            mainContent

            // SPEC-013: Banner offline (top)
            if let state = networkState, !state.isConnected {
                OfflineBanner()
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: state.isConnected)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // SPEC-013: Indicador de sincronización (bottom-right)
            if let state = networkState, state.isSyncing {
                SyncIndicator(itemCount: state.syncingItemsCount)
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut, value: state.isSyncing)
            }
        }
        .task {
            // Inicializar NetworkState cuando la view aparece
            await initializeNetworkState()
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)

            Text("Hello, world!")

            // Debug info (solo en DEBUG)
            #if DEBUG
            if let state = networkState {
                debugInfo(state)
            }
            #endif
        }
        .padding()
    }

    // MARK: - Debug Info

    #if DEBUG
    @ViewBuilder
    private func debugInfo(_ state: NetworkState) -> some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.vertical)

            Text("Network State Debug")
                .font(.caption)
                .fontWeight(.bold)

            HStack {
                Text("Conectado:")
                    .font(.caption2)
                Spacer()
                Text(state.isConnected ? "✅ Sí" : "❌ No")
                    .font(.caption2)
                    .foregroundStyle(state.isConnected ? .green : .red)
            }

            HStack {
                Text("Sincronizando:")
                    .font(.caption2)
                Spacer()
                Text(state.isSyncing ? "🔄 Sí" : "✅ No")
                    .font(.caption2)
            }

            if state.syncingItemsCount > 0 {
                HStack {
                    Text("Items pendientes:")
                        .font(.caption2)
                    Spacer()
                    Text("\(state.syncingItemsCount)")
                        .font(.caption2)
                }
            }

            HStack {
                Text("Tipo de conexión:")
                    .font(.caption2)
                Spacer()
                Text(connectionTypeLabel(state.connectionType))
                    .font(.caption2)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private func connectionTypeLabel(_ type: ConnectionType) -> String {
        switch type {
        case .wifi: "📶 WiFi"
        case .cellular: "📱 Cellular"
        case .ethernet: "🔌 Ethernet"
        case .unknown: "❓ Desconocida"
        }
    }
    #endif

    // MARK: - Private Methods

    /// Inicializa el NetworkState con las dependencias del container
    private func initializeNetworkState() async {
        // Obtener dependencias del DI container
        let networkMonitor = container.resolve(NetworkMonitor.self)
        let offlineQueue = container.resolve(OfflineQueue.self)

        // Crear NetworkState en MainActor
        await MainActor.run {
            networkState = NetworkState(
                networkMonitor: networkMonitor,
                offlineQueue: offlineQueue
            )
        }
    }
}

// MARK: - Previews

#Preview("ContentView - Online") {
    let container = DependencyContainer()

    ContentView()
        .environmentObject(container)
}

#Preview("ContentView - Offline") {
    let container = DependencyContainer()

    // Mock network monitor offline
    // Note: En un preview real, necesitaríamos configurar un mock

    ContentView()
        .environmentObject(container)
}
