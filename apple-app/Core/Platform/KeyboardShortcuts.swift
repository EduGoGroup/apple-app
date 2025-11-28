//
//  KeyboardShortcuts.swift
//  apple-app
//
//  Created on 27-11-25.
//  SPEC-006: Keyboard Shortcuts multiplataforma (iOS 26+, macOS 26+, visionOS 26+)
//

import SwiftUI

/// Sistema de atajos de teclado multiplataforma
///
/// Proporciona atajos de teclado consistentes across plataformas:
/// - macOS: Atajos tradicionales de desktop (⌘N, ⌘S, etc.)
/// - iPadOS: Soporte para teclados externos
/// - visionOS: Atajos adaptados para interacción espacial
///
/// - Important: Los atajos se adaptan automáticamente según la plataforma.
enum KeyboardShortcuts {

    // MARK: - Navigation Shortcuts

    /// Atajo para ir a Home (⌘1)
    static var goToHome: KeyEquivalent {
        KeyEquivalent("1")
    }

    static var goToHomeModifiers: EventModifiers {
        .command
    }

    /// Atajo para ir a Settings (⌘,)
    static var goToSettings: KeyEquivalent {
        KeyEquivalent(",")
    }

    static var goToSettingsModifiers: EventModifiers {
        .command
    }

    // MARK: - Action Shortcuts

    /// Atajo para Refresh (⌘R)
    static var refresh: KeyEquivalent {
        KeyEquivalent("r")
    }

    static var refreshModifiers: EventModifiers {
        .command
    }

    /// Atajo para Search (⌘F)
    static var search: KeyEquivalent {
        KeyEquivalent("f")
    }

    static var searchModifiers: EventModifiers {
        .command
    }

    /// Atajo para New Item (⌘N)
    static var newItem: KeyEquivalent {
        KeyEquivalent("n")
    }

    static var newItemModifiers: EventModifiers {
        .command
    }

    // MARK: - View Shortcuts

    /// Atajo para Toggle Sidebar (⌘⌥S)
    static var toggleSidebar: KeyEquivalent {
        KeyEquivalent("s")
    }

    static var toggleSidebarModifiers: EventModifiers {
        [.command, .option]
    }

    /// Atajo para Fullscreen (⌃⌘F)
    static var fullscreen: KeyEquivalent {
        KeyEquivalent("f")
    }

    static var fullscreenModifiers: EventModifiers {
        [.command, .control]
    }

    // MARK: - Window Shortcuts (macOS)

    #if os(macOS)
    /// Atajo para Minimize Window (⌘M)
    static var minimizeWindow: KeyEquivalent {
        KeyEquivalent("m")
    }

    static var minimizeWindowModifiers: EventModifiers {
        .command
    }

    /// Atajo para Close Window (⌘W)
    static var closeWindow: KeyEquivalent {
        KeyEquivalent("w")
    }

    static var closeWindowModifiers: EventModifiers {
        .command
    }
    #endif
}

// MARK: - View Extension for Shortcuts

extension View {

    /// Aplica atajo de teclado para navegar a Home
    func shortcutGoHome(action: @escaping () -> Void) -> some View {
        self.keyboardShortcut(
            KeyboardShortcuts.goToHome,
            modifiers: KeyboardShortcuts.goToHomeModifiers
        )
    }

    /// Aplica atajo de teclado para navegar a Settings
    func shortcutGoSettings(action: @escaping () -> Void) -> some View {
        self.keyboardShortcut(
            KeyboardShortcuts.goToSettings,
            modifiers: KeyboardShortcuts.goToSettingsModifiers
        )
    }

    /// Aplica atajo de teclado para Refresh
    func shortcutRefresh(action: @escaping () -> Void) -> some View {
        self.keyboardShortcut(
            KeyboardShortcuts.refresh,
            modifiers: KeyboardShortcuts.refreshModifiers
        )
    }

    /// Aplica atajo de teclado para Search
    func shortcutSearch(action: @escaping () -> Void) -> some View {
        self.keyboardShortcut(
            KeyboardShortcuts.search,
            modifiers: KeyboardShortcuts.searchModifiers
        )
    }
}

// MARK: - Keyboard Shortcut Hints

/// Helper para mostrar hints de atajos de teclado en la UI
struct KeyboardShortcutHint: View {
    let keys: String
    let description: String

    var body: some View {
        HStack(spacing: DSSpacing.small) {
            Text(description)
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)

            Spacer()

            Text(keys)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, DSSpacing.small)
                .padding(.vertical, DSSpacing.xs)
                .background(DSColors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.small))
                .foregroundColor(DSColors.textSecondary)
        }
    }
}

// MARK: - Platform-specific Shortcuts Guide

/// Guía de atajos disponibles según la plataforma
@MainActor
struct ShortcutsGuide {

    /// Atajos disponibles en macOS
    static var macOSShortcuts: [(String, String)] {
        [
            ("⌘1", "Ir a Inicio"),
            ("⌘,", "Abrir Configuración"),
            ("⌘R", "Actualizar"),
            ("⌘F", "Buscar"),
            ("⌘N", "Nuevo"),
            ("⌘⌥S", "Mostrar/Ocultar Sidebar"),
            ("⌃⌘F", "Pantalla Completa"),
            ("⌘M", "Minimizar Ventana"),
            ("⌘W", "Cerrar Ventana"),
        ]
    }

    /// Atajos disponibles en iPadOS (con teclado externo)
    static var iPadOSShortcuts: [(String, String)] {
        [
            ("⌘1", "Ir a Inicio"),
            ("⌘,", "Abrir Configuración"),
            ("⌘R", "Actualizar"),
            ("⌘F", "Buscar"),
            ("⌘N", "Nuevo"),
        ]
    }

    /// Atajos disponibles en visionOS
    static var visionOSShortcuts: [(String, String)] {
        [
            ("⌘1", "Ir a Inicio"),
            ("⌘,", "Abrir Configuración"),
            ("⌘R", "Actualizar"),
        ]
    }

    /// Obtiene los atajos disponibles para la plataforma actual
    static var currentPlatformShortcuts: [(String, String)] {
        #if os(macOS)
        return macOSShortcuts
        #elseif os(iOS)
        if PlatformCapabilities.isIPad {
            return iPadOSShortcuts
        } else {
            return []
        }
        #elseif os(visionOS)
        return visionOSShortcuts
        #else
        return []
        #endif
    }
}

// MARK: - Shortcuts Help View

/// Vista que muestra la guía de atajos de teclado
struct ShortcutsHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Atajos Disponibles") {
                    ForEach(ShortcutsGuide.currentPlatformShortcuts, id: \.0) { shortcut in
                        KeyboardShortcutHint(
                            keys: shortcut.0,
                            description: shortcut.1
                        )
                    }
                }

                Section {
                    Text("Los atajos de teclado te ayudan a navegar más rápido por la aplicación.")
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)
                }
            }
            .navigationTitle("Atajos de Teclado")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Shortcuts Guide - macOS") {
    ShortcutsHelpView()
        .frame(width: 500, height: 600)
}

#Preview("Shortcut Hint") {
    VStack(spacing: DSSpacing.medium) {
        KeyboardShortcutHint(keys: "⌘1", description: "Ir a Inicio")
        KeyboardShortcutHint(keys: "⌘R", description: "Actualizar")
        KeyboardShortcutHint(keys: "⌘⌥S", description: "Toggle Sidebar")
    }
    .padding()
}
