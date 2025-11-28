//
//  MacOSToolbarConfiguration.swift
//  apple-app
//
//  Created on 27-11-25.
//  SPEC-006: macOS Toolbar configuration para iOS 26+/macOS 26+
//

#if os(macOS)
import SwiftUI

/// Configuración de toolbar nativa para macOS
///
/// Proporciona toolbar items estandarizados para la aplicación macOS:
/// - Navigation controls (sidebar toggle, back/forward)
/// - Actions (refresh, search, new item)
/// - Window controls (fullscreen, zoom)
///
/// - Important: Solo disponible en macOS. Usa #if os(macOS) para código condicional.
@MainActor
struct MacOSToolbarConfiguration {

    // MARK: - Toolbar Customization

    /// ID del toolbar personalizado
    static let toolbarID = "com.edugo.app.main-toolbar"

    /// Estilos de toolbar disponibles
    enum ToolbarStyle {
        case automatic
        case expanded
        case unified
        case unifiedCompact

        // TODO: Habilitar cuando NSToolbar.Style esté disponible en SDK
        // @available(macOS 26.0, *)
        // var nsToolbarStyle: NSToolbar.Style {
        //     switch self {
        //     case .automatic:
        //         return .automatic
        //     case .expanded:
        //         return .expanded
        //     case .unified:
        //         return .unified
        //     case .unifiedCompact:
        //         return .unifiedCompact
        //     }
        // }
    }

    // MARK: - Toolbar Items

    /// Item IDs para los elementos del toolbar
    enum ItemID: String {
        case sidebar = "sidebar-toggle"
        case refresh = "refresh"
        case search = "search"
        case newItem = "new-item"
        case share = "share"
        case settings = "settings"

        var identifier: NSToolbarItem.Identifier {
            NSToolbarItem.Identifier(rawValue)
        }
    }
}

// MARK: - Toolbar Content Builder

/// Extensión para construir toolbar content usando ToolbarContentBuilder
extension MacOSToolbarConfiguration {

    /// Crea toolbar content para la vista principal
    @ToolbarContentBuilder
    static func mainToolbarContent(
        onSidebarToggle: @escaping () -> Void,
        onRefresh: @escaping () -> Void,
        onSearch: @escaping () -> Void
    ) -> some ToolbarContent {
        // Navigation group (izquierda)
        ToolbarItemGroup(placement: .navigation) {
            Button {
                onSidebarToggle()
            } label: {
                Label("Toggle Sidebar", systemImage: "sidebar.left")
            }
            .help("Mostrar/ocultar sidebar (⌘⌥S)")
        }

        // Principal group (centro)
        ToolbarItemGroup(placement: .principal) {
            Spacer()
        }

        // Actions group (derecha)
        ToolbarItemGroup(placement: .automatic) {
            Button {
                onRefresh()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .help("Actualizar contenido (⌘R)")

            Button {
                onSearch()
            } label: {
                Label("Search", systemImage: "magnifyingglass")
            }
            .help("Buscar (⌘F)")
        }
    }

    /// Crea toolbar content para la vista de configuración
    @ToolbarContentBuilder
    static func settingsToolbarContent(
        onDone: @escaping () -> Void
    ) -> some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
                onDone()
            }
            .keyboardShortcut(.defaultAction)
        }
    }
}

// MARK: - Window Controls

/// Utilidades para controlar ventanas en macOS
@MainActor
struct MacOSWindowControls {

    /// Alterna el sidebar de la ventana principal
    static func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(
            #selector(NSSplitViewController.toggleSidebar(_:)),
            with: nil
        )
    }

    /// Activa modo fullscreen
    static func toggleFullscreen() {
        NSApp.keyWindow?.toggleFullScreen(nil)
    }

    /// Minimiza la ventana actual
    static func minimizeWindow() {
        NSApp.keyWindow?.miniaturize(nil)
    }

    /// Cierra la ventana actual
    static func closeWindow() {
        NSApp.keyWindow?.performClose(nil)
    }

    /// Zoom de la ventana (expande al tamaño óptimo)
    static func zoomWindow() {
        NSApp.keyWindow?.zoom(nil)
    }
}

// MARK: - NSToolbar Extensions

/// Extensión para NSToolbar con configuraciones modernas
extension NSToolbar {

    // TODO: Habilitar cuando NSToolbar.Style esté disponible en SDK
    // /// Configura un toolbar con estilo moderno de macOS 26+
    // @available(macOS 26.0, *)
    // static func modernToolbar(identifier: String) -> NSToolbar {
    //     let toolbar = NSToolbar(identifier: identifier)
    //     toolbar.displayMode = .iconOnly
    //     toolbar.style = .unified
    //     toolbar.allowsUserCustomization = true
    //     toolbar.autosavesConfiguration = true
    //     return toolbar
    // }

    /// Configura un toolbar con estilo para macOS 15+
    @available(macOS 15.0, *)
    static func standardToolbar(identifier: String) -> NSToolbar {
        let toolbar = NSToolbar(identifier: identifier)
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = true
        toolbar.autosavesConfiguration = true
        return toolbar
    }
}

// MARK: - Toolbar Preview

#Preview("macOS Toolbar") {
    NavigationStack {
        VStack {
            Text("Main Content")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            MacOSToolbarConfiguration.mainToolbarContent(
                onSidebarToggle: { print("Toggle sidebar") },
                onRefresh: { print("Refresh") },
                onSearch: { print("Search") }
            )
        }
    }
    .frame(width: 800, height: 600)
}

#endif // os(macOS)
