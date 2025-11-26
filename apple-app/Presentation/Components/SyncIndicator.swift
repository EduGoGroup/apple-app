//
//  SyncIndicator.swift
//  apple-app
//
//  Created on 25-11-25.
//  SPEC-013: Offline-First Strategy - Sync Indicator Component
//

import SwiftUI

/// Indicador de sincronización de la cola offline
///
/// Muestra un ProgressView y la cantidad de elementos que se están sincronizando.
/// Aparece cuando NetworkState.isSyncing es true.
///
/// Ejemplo de uso:
/// ```swift
/// struct ContentView: View {
///     @State private var networkState: NetworkState
///
///     var body: some View {
///         ZStack(alignment: .bottomTrailing) {
///             // Contenido principal
///             NavigationStack { }
///
///             // Indicador de sync
///             if networkState.isSyncing {
///                 SyncIndicator(itemCount: networkState.syncingItemsCount)
///                     .padding()
///             }
///         }
///     }
/// }
/// ```
struct SyncIndicator: View {
    // MARK: - Properties

    /// Cantidad de elementos siendo sincronizados
    let itemCount: Int

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            // Progress spinner
            ProgressView()
                .scaleEffect(0.8)
                .tint(.primary)

            // Texto de sincronización
            Text(syncMessage)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial) // iOS 15+, disponible en iOS 18+
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    // MARK: - Private Computed Properties

    /// Mensaje de sincronización con pluralización correcta
    /// SPEC-010: Migrado a Localizable.xcstrings
    private var syncMessage: String {
        if itemCount == 1 {
            return String(localized: "sync.indicator.single")
        } else if itemCount > 1 {
            return String(format: String(localized: "sync.indicator.multiple"), itemCount)
        } else {
            return String(localized: "sync.indicator.default")
        }
    }
}

// MARK: - Previews

#Preview("Sync Indicator - 1 Item") {
    VStack {
        Spacer()

        HStack {
            Spacer()

            SyncIndicator(itemCount: 1)
                .padding()
        }
    }
}

#Preview("Sync Indicator - Multiple Items") {
    VStack {
        Spacer()

        HStack {
            Spacer()

            SyncIndicator(itemCount: 5)
                .padding()
        }
    }
}

#Preview("Sync Indicator - No Count") {
    VStack {
        Spacer()

        HStack {
            Spacer()

            SyncIndicator(itemCount: 0)
                .padding()
        }
    }
}

#Preview("Sync Indicator in Context - Light") {
    ZStack(alignment: .bottomTrailing) {
        // Simular pantalla principal
        NavigationStack {
            List(0..<20) { item in
                Text("Item \(item)")
            }
            .navigationTitle("Inicio")
        }

        // Indicador de sync
        SyncIndicator(itemCount: 3)
            .padding()
    }
    .preferredColorScheme(.light)
}

#Preview("Sync Indicator in Context - Dark") {
    ZStack(alignment: .bottomTrailing) {
        // Simular pantalla principal
        NavigationStack {
            List(0..<20) { item in
                Text("Item \(item)")
            }
            .navigationTitle("Inicio")
        }

        // Indicador de sync
        SyncIndicator(itemCount: 3)
            .padding()
    }
    .preferredColorScheme(.dark)
}
