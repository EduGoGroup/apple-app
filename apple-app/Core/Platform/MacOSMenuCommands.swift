//
//  MacOSMenuCommands.swift
//  apple-app
//
//  Created on 27-11-25.
//  SPEC-006: macOS Menu Bar commands para iOS 26+/macOS 26+
//

#if os(macOS)
import SwiftUI

/// Comandos de menu bar para macOS
///
/// Proporciona comandos personalizados en la barra de menú de macOS:
/// - File menu: New, Open, Save, Close
/// - Edit menu: Undo, Redo, Cut, Copy, Paste
/// - View menu: Sidebar, Fullscreen, Zoom
/// - Navigate menu: Back, Forward, Go To
/// - Window menu: Minimize, Zoom, Bring All to Front
///
/// - Important: Usa .commands(content:) en la raíz de la app para agregar estos comandos.
struct MacOSMenuCommands: Commands {

    @FocusedBinding(\.selectedRoute) private var selectedRoute: Route?

    var body: some Commands {
        // File Menu
        CommandGroup(replacing: .newItem) {
            Button("New Window") {
                // TODO: Implementar nueva ventana
            }
            .keyboardShortcut("n", modifiers: [.command])

            Divider()
        }

        // View Menu
        CommandGroup(after: .sidebar) {
            Button("Toggle Sidebar") {
                MacOSWindowControls.toggleSidebar()
            }
            .keyboardShortcut("s", modifiers: [.command, .option])

            Divider()

            Button("Enter Full Screen") {
                MacOSWindowControls.toggleFullscreen()
            }
            .keyboardShortcut("f", modifiers: [.command, .control])
        }

        // Navigate Menu (custom)
        CommandMenu("Navigate") {
            Button("Home") {
                // TODO: Navegar a Home
            }
            .keyboardShortcut("1", modifiers: [.command])
            .disabled(selectedRoute == .home)

            Button("Settings") {
                // TODO: Navegar a Settings
            }
            .keyboardShortcut(",", modifiers: [.command])
            .disabled(selectedRoute == .settings)

            Divider()

            Button("Refresh") {
                // TODO: Refrescar vista actual
            }
            .keyboardShortcut("r", modifiers: [.command])
        }

        // Window Menu
        CommandGroup(replacing: .windowArrangement) {
            Button("Minimize") {
                MacOSWindowControls.minimizeWindow()
            }
            .keyboardShortcut("m", modifiers: [.command])

            Button("Zoom") {
                MacOSWindowControls.zoomWindow()
            }

            Divider()

            Button("Bring All to Front") {
                NSApp.activate(ignoringOtherApps: true)
            }
        }

        // Help Menu
        CommandGroup(replacing: .help) {
            Button("EduGo Help") {
                // TODO: Abrir documentación
                if let url = URL(string: "https://edugo.com/help") {
                    NSWorkspace.shared.open(url)
                }
            }
            .keyboardShortcut("?", modifiers: [.command])

            Divider()

            Button("Report an Issue") {
                // TODO: Abrir formulario de issues
                if let url = URL(string: "https://edugo.com/support") {
                    NSWorkspace.shared.open(url)
                }
            }

            Button("About EduGo") {
                // TODO: Mostrar ventana About
                NSApp.orderFrontStandardAboutPanel(nil)
            }
        }
    }
}

// MARK: - Focused Values

/// FocusedValues extension para comunicación entre vistas y comandos
extension FocusedValues {

    /// Ruta actualmente seleccionada en la navegación
    var selectedRoute: Binding<Route>? {
        get { self[SelectedRouteKey.self] }
        set { self[SelectedRouteKey.self] = newValue }
    }
}

private struct SelectedRouteKey: FocusedValueKey {
    typealias Value = Binding<Route>
}

// MARK: - macOS Window Controls
// Nota: MacOSWindowControls está definido en MacOSToolbarConfiguration.swift

// MARK: - App Integration Example

/*
 Para usar estos comandos en la app principal:

 @main
 struct EduGoApp: App {
     var body: some Scene {
         WindowGroup {
             ContentView()
         }
         .commands {
             MacOSMenuCommands()
         }
     }
 }
 */

#endif // os(macOS)
