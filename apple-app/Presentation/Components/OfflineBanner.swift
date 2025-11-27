//
//  OfflineBanner.swift
//  apple-app
//
//  Created on 25-11-25.
//  SPEC-013: Offline-First Strategy - Offline Banner Component
//

import SwiftUI

/// Banner que indica al usuario que no hay conexión a internet
///
/// Este componente se muestra automáticamente cuando NetworkState detecta
/// que no hay conectividad. Usa transitions nativas de SwiftUI para
/// animaciones suaves.
///
/// Ejemplo de uso:
/// ```swift
/// struct ContentView: View {
///     @State private var networkState: NetworkState
///
///     var body: some View {
///         ZStack(alignment: .top) {
///             // Contenido principal
///             NavigationStack { }
///
///             // Banner offline
///             if !networkState.isConnected {
///                 OfflineBanner()
///                     .padding(.top, 8)
///             }
///         }
///     }
/// }
/// ```
struct OfflineBanner: View {
    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Icono de wifi sin conexión
            Image(systemName: "wifi.slash")
                .font(.body)
                .foregroundStyle(.white)

            // Mensaje
            Text(String(localized: "offline.banner.message"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(bannerColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    // MARK: - Private Computed Properties

    /// Color del banner según el tema
    private var bannerColor: Color {
        // Naranja para advertencia, visible en ambos temas
        Color.orange
    }
}

// MARK: - Previews

#Preview("Offline Banner - Light") {
    VStack(spacing: 20) {
        OfflineBanner()

        Spacer()
    }
    .padding(.top, 50)
    .preferredColorScheme(.light)
}

#Preview("Offline Banner - Dark") {
    VStack(spacing: 20) {
        OfflineBanner()

        Spacer()
    }
    .padding(.top, 50)
    .preferredColorScheme(.dark)
}

#Preview("Offline Banner in Context") {
    ZStack(alignment: .top) {
        // Simular pantalla principal
        NavigationStack {
            List(0..<20) { item in
                Text("Item \(item)")
            }
            .navigationTitle("Inicio")
        }

        // Banner offline
        OfflineBanner()
            .padding(.top, 8)
    }
}
