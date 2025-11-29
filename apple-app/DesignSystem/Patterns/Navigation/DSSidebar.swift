//
//  DSSidebar.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 1 - Task 1.2: Navigation Patterns
//  SPEC: Adaptación a estándares Apple iOS26/macOS26
//

import SwiftUI

// MARK: - Sidebar Item

/// Item de sidebar del Design System
///
/// Representa un elemento individual en la barra lateral.
///
/// **Uso:**
/// ```swift
/// let homeItem = DSSidebarItem(
///     id: "home",
///     title: "Inicio",
///     icon: "house",
///     badge: 5
/// )
/// ```
struct DSSidebarItem: Identifiable, Sendable, Hashable {
    let id: String
    let title: String
    let icon: String
    let badge: Int?
    let isDestructive: Bool

    /// Crea un item de sidebar
    ///
    /// - Parameters:
    ///   - id: Identificador único del item
    ///   - title: Título del item
    ///   - icon: Nombre del SF Symbol
    ///   - badge: Número de badge (opcional)
    ///   - isDestructive: Si el item es destructivo (color rojo)
    init(
        id: String,
        title: String,
        icon: String,
        badge: Int? = nil,
        isDestructive: Bool = false
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.badge = badge
        self.isDestructive = isDestructive
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DSSidebarItem, rhs: DSSidebarItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sidebar Section

/// Sección de sidebar del Design System
///
/// Agrupa items relacionados en una sección con título opcional.
///
/// **Uso:**
/// ```swift
/// let mainSection = DSSidebarSection(
///     id: "main",
///     title: "Principal",
///     items: [homeItem, searchItem]
/// )
/// ```
struct DSSidebarSection: Identifiable, Sendable {
    let id: String
    let title: String?
    let items: [DSSidebarItem]

    /// Crea una sección de sidebar
    ///
    /// - Parameters:
    ///   - id: Identificador único de la sección
    ///   - title: Título de la sección (opcional)
    ///   - items: Array de items en la sección
    init(
        id: String,
        title: String? = nil,
        items: [DSSidebarItem]
    ) {
        self.id = id
        self.title = title
        self.items = items
    }
}

// MARK: - Sidebar Pattern

/// Sidebar del Design System
///
/// Implementa el pattern de Sidebar estándar de Apple para iPad y Mac
/// con soporte para Liquid Glass en iOS 18+ / macOS 15+.
///
/// **Características:**
/// - NavigationSplitView con sidebar
/// - Secciones agrupadas
/// - Badges opcionales
/// - Liquid Glass en iOS 18+ (opcional)
/// - Adaptativo (se colapsa en iPhone)
///
/// **Uso:**
/// ```swift
/// @State private var selectedItem: String? = "home"
///
/// DSSidebar(
///     selection: $selectedItem,
///     sections: sections
/// ) { itemId in
///     detailView(for: itemId)
/// }
/// ```
@MainActor
struct DSSidebar<Content: View>: View {
    @Binding var selection: String?
    let sections: [DSSidebarSection]
    let glassIntensity: LiquidGlassIntensity
    @ViewBuilder let content: (String?) -> Content

    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    /// Crea un Sidebar
    ///
    /// - Parameters:
    ///   - selection: Binding al ID del item seleccionado
    ///   - sections: Array de secciones del sidebar
    ///   - glassIntensity: Intensidad del efecto glass (iOS 18+)
    ///   - content: Closure que devuelve el contenido para cada item ID
    init(
        selection: Binding<String?>,
        sections: [DSSidebarSection],
        glassIntensity: LiquidGlassIntensity = .subtle,
        @ViewBuilder content: @escaping (String?) -> Content
    ) {
        self._selection = selection
        self.sections = sections
        self.glassIntensity = glassIntensity
        self.content = content
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarView
        } detail: {
            content(selection)
        }
    }

    @ViewBuilder
    private var sidebarView: some View {
        List(selection: $selection) {
            ForEach(sections) { section in
                Section {
                    ForEach(section.items) { item in
                        sidebarRow(for: item)
                    }
                } header: {
                    if let title = section.title {
                        Text(title)
                            .font(DSTypography.caption)
                            .foregroundColor(DSColors.textSecondary)
                            .textCase(.uppercase)
                    }
                }
            }
        }
        .navigationTitle("Menu")
        .listStyle(.sidebar)
        .background(sidebarBackground)
    }

    @ViewBuilder
    private var sidebarBackground: some View {
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            Color.clear
                .dsGlassEffect(.liquidGlass(glassIntensity))
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private func sidebarRow(for item: DSSidebarItem) -> some View {
        NavigationLink(value: item.id) {
            Label {
                HStack {
                    Text(item.title)
                        .foregroundColor(item.isDestructive ? DSColors.error : DSColors.textPrimary)

                    if let badge = item.badge, badge > 0 {
                        Spacer()
                        badgeView(count: badge)
                    }
                }
            } icon: {
                Image(systemName: item.icon)
                    .foregroundColor(item.isDestructive ? DSColors.error : DSColors.accent)
            }
        }
    }

    @ViewBuilder
    private func badgeView(count: Int) -> some View {
        Text("\(min(count, 99))")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(DSColors.accent)
            )
            .frame(minWidth: 20, minHeight: 16)
    }
}

// MARK: - Previews

#Preview("Sidebar - iPad") {
    @Previewable @State var selectedItem: String? = "home"

    let sections = [
        DSSidebarSection(
            id: "main",
            title: "Principal",
            items: [
                DSSidebarItem(id: "home", title: "Inicio", icon: "house"),
                DSSidebarItem(id: "search", title: "Buscar", icon: "magnifyingglass"),
                DSSidebarItem(id: "favorites", title: "Favoritos", icon: "heart", badge: 5)
            ]
        ),
        DSSidebarSection(
            id: "library",
            title: "Biblioteca",
            items: [
                DSSidebarItem(id: "all", title: "Todos", icon: "folder"),
                DSSidebarItem(id: "recent", title: "Recientes", icon: "clock", badge: 3),
                DSSidebarItem(id: "shared", title: "Compartidos", icon: "person.2")
            ]
        ),
        DSSidebarSection(
            id: "settings",
            items: [
                DSSidebarItem(id: "settings", title: "Ajustes", icon: "gearshape"),
                DSSidebarItem(id: "logout", title: "Cerrar Sesión", icon: "rectangle.portrait.and.arrow.right", isDestructive: true)
            ]
        )
    ]

    if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
        DSSidebar(
            selection: $selectedItem,
            sections: sections,
            glassIntensity: .subtle
        ) { itemId in
            detailViewPreview(for: itemId)
        }
    } else {
        DSSidebar(
            selection: $selectedItem,
            sections: sections
        ) { itemId in
            detailViewPreview(for: itemId)
        }
    }
}

#Preview("Sidebar - macOS") {
    @Previewable @State var selectedItem: String? = "projects"

    let sections = [
        DSSidebarSection(
            id: "workspace",
            title: "Espacio de Trabajo",
            items: [
                DSSidebarItem(id: "projects", title: "Proyectos", icon: "folder.fill", badge: 12),
                DSSidebarItem(id: "tasks", title: "Tareas", icon: "checkmark.circle", badge: 8),
                DSSidebarItem(id: "calendar", title: "Calendario", icon: "calendar")
            ]
        ),
        DSSidebarSection(
            id: "collections",
            title: "Colecciones",
            items: [
                DSSidebarItem(id: "starred", title: "Destacados", icon: "star.fill", badge: 3),
                DSSidebarItem(id: "archive", title: "Archivo", icon: "archivebox"),
                DSSidebarItem(id: "trash", title: "Papelera", icon: "trash", isDestructive: true)
            ]
        )
    ]

    if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
        DSSidebar(
            selection: $selectedItem,
            sections: sections,
            glassIntensity: .standard
        ) { itemId in
            detailViewPreview(for: itemId)
        }
    }
}

// MARK: - Preview Helpers

@MainActor
@ViewBuilder
private func detailViewPreview(for itemId: String?) -> some View {
    if let itemId = itemId {
        NavigationStack {
            VStack(spacing: DSSpacing.xl) {
                Image(systemName: iconForItemPreview(itemId))
                    .font(.system(size: 80))
                    .foregroundColor(DSColors.accent)

                Text(titleForItemPreview(itemId))
                    .font(DSTypography.largeTitle)

                Text("Item ID: \(itemId)")
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.05), .purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle(titleForItemPreview(itemId))
        }
    } else {
        ContentUnavailableView(
            "Selecciona un item",
            systemImage: "sidebar.left",
            description: Text("Elige un item del sidebar para ver su contenido")
        )
    }
}

@MainActor
private func iconForItemPreview(_ id: String) -> String {
    switch id {
    case "home": return "house.fill"
    case "search": return "magnifyingglass"
    case "favorites": return "heart.fill"
    case "all": return "folder.fill"
    case "recent": return "clock.fill"
    case "shared": return "person.2.fill"
    case "settings": return "gearshape.fill"
    case "projects": return "folder.fill"
    case "tasks": return "checkmark.circle.fill"
    case "calendar": return "calendar"
    case "starred": return "star.fill"
    case "archive": return "archivebox.fill"
    case "trash": return "trash.fill"
    default: return "doc.fill"
    }
}

@MainActor
private func titleForItemPreview(_ id: String) -> String {
    switch id {
    case "home": return "Inicio"
    case "search": return "Buscar"
    case "favorites": return "Favoritos"
    case "all": return "Todos"
    case "recent": return "Recientes"
    case "shared": return "Compartidos"
    case "settings": return "Ajustes"
    case "projects": return "Proyectos"
    case "tasks": return "Tareas"
    case "calendar": return "Calendario"
    case "starred": return "Destacados"
    case "archive": return "Archivo"
    case "trash": return "Papelera"
    default: return "Detalle"
    }
}
