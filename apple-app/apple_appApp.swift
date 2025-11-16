//
//  apple_appApp.swift
//  apple-app
//
//  Created by Jhoan Medina on 15-11-25.
//

import SwiftUI

@main
struct apple_appApp: App {
    var body: some Scene {
        WindowGroup {
            AdaptiveNavigationView(
                authRepository: AuthRepositoryImpl(
                    apiClient: DefaultAPIClient(baseURL: AppConfig.baseURL)
                ),
                preferencesRepository: PreferencesRepositoryImpl()
            )
        }
        .commands {
            appCommands
        }
        #if os(macOS)
        .defaultSize(width: 1000, height: 700)
        #endif
    }

    // MARK: - Commands (Menu Bar)

    @CommandsBuilder
    private var appCommands: some Commands {
        // Comandos personalizados
        CommandMenu("Navegación") {
            Button("Inicio") {
                // TODO: Implementar navegación desde menú
            }
            .keyboardShortcut("h", modifiers: [.command])

            Button("Configuración") {
                // TODO: Implementar navegación desde menú
            }
            .keyboardShortcut(",", modifiers: [.command])

            Divider()

            Button("Cerrar Sesión") {
                // TODO: Implementar logout desde menú
            }
            .keyboardShortcut("q", modifiers: [.command, .shift])
        }
    }
}
