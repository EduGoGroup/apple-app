//
//  DSSplitView.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 1 - Task 1.2: Navigation Patterns
//  SPEC: Adaptación a estándares Apple iOS26/macOS26
//

import SwiftUI

// MARK: - Split View Pattern

/// Split View del Design System
///
/// Implementa el pattern de Split View de 3 columnas estándar de Apple
/// para layouts complejos en iPad y Mac con soporte para Liquid Glass.
///
/// **Características:**
/// - 3 columnas: Sidebar + Content + Detail
/// - Visibilidad configurable por columna
/// - Liquid Glass en iOS 26+ (opcional)
/// - Adaptativo (se colapsa en iPhone)
/// - Soporte para toolbar personalizado
///
/// **Uso:**
/// ```swift
/// DSSplitView(
///     sidebarGlassIntensity: .subtle,
///     contentGlassIntensity: .standard
/// ) {
///     // Sidebar
///     List { ... }
/// } content: {
///     // Content
///     ContentList()
/// } detail: {
///     // Detail
///     DetailView()
/// }
/// ```
@MainActor
struct DSSplitView<Sidebar: View, Content: View, Detail: View>: View {
    let sidebarGlassIntensity: LiquidGlassIntensity
    let contentGlassIntensity: LiquidGlassIntensity
    @ViewBuilder let sidebar: () -> Sidebar
    @ViewBuilder let content: () -> Content
    @ViewBuilder let detail: () -> Detail

    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    /// Crea un Split View de 3 columnas
    ///
    /// - Parameters:
    ///   - sidebarGlassIntensity: Intensidad glass para sidebar (iOS 26+)
    ///   - contentGlassIntensity: Intensidad glass para content (iOS 26+)
    ///   - sidebar: Contenido de la barra lateral
    ///   - content: Contenido de la columna central
    ///   - detail: Contenido de la columna de detalle
    init(
        sidebarGlassIntensity: LiquidGlassIntensity = .subtle,
        contentGlassIntensity: LiquidGlassIntensity = .standard,
        @ViewBuilder sidebar: @escaping () -> Sidebar,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder detail: @escaping () -> Detail
    ) {
        self.sidebarGlassIntensity = sidebarGlassIntensity
        self.contentGlassIntensity = contentGlassIntensity
        self.sidebar = sidebar
        self.content = content
        self.detail = detail
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            sidebar()
                .background(sidebarBackground)
        } content: {
            // Content
            content()
                .background(contentBackground)
        } detail: {
            // Detail
            detail()
        }
    }

    @ViewBuilder
    private var sidebarBackground: some View {
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            Color.clear
                .dsGlassEffect(.liquidGlass(sidebarGlassIntensity))
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var contentBackground: some View {
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            Color.clear
                .dsGlassEffect(.liquidGlass(contentGlassIntensity))
        } else {
            Color.clear
        }
    }
}

// MARK: - Split View de 2 Columnas

/// Split View simplificado de 2 columnas
///
/// Versión simplificada del Split View para layouts que solo necesitan
/// sidebar y detalle (sin columna central).
///
/// **Uso:**
/// ```swift
/// DSTwoColumnSplitView {
///     // Sidebar
///     List { ... }
/// } detail: {
///     // Detail
///     DetailView()
/// }
/// ```
@MainActor
struct DSTwoColumnSplitView<Sidebar: View, Detail: View>: View {
    let sidebarGlassIntensity: LiquidGlassIntensity
    @ViewBuilder let sidebar: () -> Sidebar
    @ViewBuilder let detail: () -> Detail

    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    /// Crea un Split View de 2 columnas
    ///
    /// - Parameters:
    ///   - sidebarGlassIntensity: Intensidad glass para sidebar (iOS 26+)
    ///   - sidebar: Contenido de la barra lateral
    ///   - detail: Contenido de detalle
    init(
        sidebarGlassIntensity: LiquidGlassIntensity = .subtle,
        @ViewBuilder sidebar: @escaping () -> Sidebar,
        @ViewBuilder detail: @escaping () -> Detail
    ) {
        self.sidebarGlassIntensity = sidebarGlassIntensity
        self.sidebar = sidebar
        self.detail = detail
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar()
                .background(sidebarBackground)
        } detail: {
            detail()
        }
    }

    @ViewBuilder
    private var sidebarBackground: some View {
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            Color.clear
                .dsGlassEffect(.liquidGlass(sidebarGlassIntensity))
        } else {
            Color.clear
        }
    }
}

// MARK: - Previews

#Preview("Split View - 3 Columnas") {
    @Previewable @State var selectedCategory: String? = "documents"
    @Previewable @State var selectedItem: String? = "item1"

    let categories = [
        "documents": "Documentos",
        "photos": "Fotos",
        "videos": "Videos"
    ]

    let items = [
        "item1": "Item 1",
        "item2": "Item 2",
        "item3": "Item 3"
    ]

    if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
        DSSplitView(
            sidebarGlassIntensity: .subtle,
            contentGlassIntensity: .standard
        ) {
            // Sidebar
            List(selection: $selectedCategory) {
                Section("Categorías") {
                    ForEach(Array(categories.keys.sorted()), id: \.self) { key in
                        NavigationLink(value: key) {
                            Label(categories[key]!, systemImage: iconForCategory(key))
                        }
                    }
                }
            }
            .navigationTitle("Sidebar")
            .listStyle(.sidebar)
        } content: {
            // Content
            List(selection: $selectedItem) {
                Section(categories[selectedCategory ?? ""] ?? "Items") {
                    ForEach(Array(items.keys.sorted()), id: \.self) { key in
                        NavigationLink(value: key) {
                            Text(items[key]!)
                        }
                    }
                }
            }
            .navigationTitle("Contenido")
        } detail: {
            // Detail
            if let item = selectedItem {
                detailContentPreview(for: item)
            } else {
                ContentUnavailableView(
                    "Selecciona un item",
                    systemImage: "doc.text",
                    description: Text("Elige un item para ver sus detalles")
                )
            }
        }
    } else {
        Text("Split View de 3 columnas requiere iOS 26+")
    }
}

#Preview("Split View - 2 Columnas") {
    @Previewable @State var selectedFolder: String? = "inbox"

    let folders = [
        "inbox": "Entrada",
        "sent": "Enviados",
        "drafts": "Borradores",
        "trash": "Papelera"
    ]

    if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
        DSTwoColumnSplitView(sidebarGlassIntensity: .subtle) {
            // Sidebar
            List(selection: $selectedFolder) {
                Section("Carpetas") {
                    ForEach(Array(folders.keys.sorted()), id: \.self) { key in
                        NavigationLink(value: key) {
                            Label(folders[key]!, systemImage: iconForFolder(key))
                        }
                    }
                }
            }
            .navigationTitle("Mail")
            .listStyle(.sidebar)
        } detail: {
            // Detail
            if let folder = selectedFolder {
                mailDetailPreview(for: folder, name: folders[folder]!)
            } else {
                ContentUnavailableView(
                    "Selecciona una carpeta",
                    systemImage: "envelope",
                    description: Text("Elige una carpeta para ver sus mensajes")
                )
            }
        }
    }
}

#Preview("Split View - iPad Pro") {
    @Previewable @State var selectedSection: String? = "projects"
    @Previewable @State var selectedProject: String? = "project1"

    if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
        DSSplitView(
            sidebarGlassIntensity: .subtle,
            contentGlassIntensity: .standard
        ) {
            // Sidebar
            List(selection: $selectedSection) {
                Section("Espacio de Trabajo") {
                    NavigationLink(value: "projects") {
                        Label("Proyectos", systemImage: "folder.fill")
                    }
                    NavigationLink(value: "tasks") {
                        Label("Tareas", systemImage: "checkmark.circle")
                    }
                    NavigationLink(value: "calendar") {
                        Label("Calendario", systemImage: "calendar")
                    }
                }
            }
            .navigationTitle("Menu")
            .listStyle(.sidebar)
        } content: {
            // Content
            List(selection: $selectedProject) {
                Section("Proyectos Activos") {
                    ForEach(1...10, id: \.self) { num in
                        NavigationLink(value: "project\(num)") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Proyecto \(num)")
                                    .font(DSTypography.bodyBold)
                                Text("\(num * 3) tareas pendientes")
                                    .font(DSTypography.caption)
                                    .foregroundColor(DSColors.textSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Proyectos")
        } detail: {
            // Detail
            if let project = selectedProject {
                projectDetailPreview(for: project)
            } else {
                ContentUnavailableView(
                    "Selecciona un proyecto",
                    systemImage: "folder",
                    description: Text("Elige un proyecto para ver sus detalles")
                )
            }
        }
    }
}

// MARK: - Preview Helpers

private func iconForCategory(_ key: String) -> String {
    switch key {
    case "documents": return "doc.fill"
    case "photos": return "photo.fill"
    case "videos": return "video.fill"
    default: return "folder.fill"
    }
}

private func iconForFolder(_ key: String) -> String {
    switch key {
    case "inbox": return "tray.fill"
    case "sent": return "paperplane.fill"
    case "drafts": return "doc.text.fill"
    case "trash": return "trash.fill"
    default: return "folder.fill"
    }
}

@ViewBuilder
private func detailContentPreview(for item: String) -> some View {
    NavigationStack {
        VStack(spacing: DSSpacing.xl) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 80))
                .foregroundColor(DSColors.accent)

            Text("Detalle de \(item)")
                .font(DSTypography.largeTitle)

            Text("Esta es la vista de detalle para el item seleccionado")
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.05), .purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle(item.capitalized)
    }
}

@ViewBuilder
private func mailDetailPreview(for folder: String, name: String) -> some View {
    NavigationStack {
        List {
            ForEach(1...20, id: \.self) { num in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Remitente \(num)")
                            .font(DSTypography.bodyBold)
                        Spacer()
                        Text("10:30 AM")
                            .font(DSTypography.caption)
                            .foregroundColor(DSColors.textSecondary)
                    }

                    Text("Asunto del mensaje \(num)")
                        .font(DSTypography.body)

                    Text("Vista previa del contenido del mensaje...")
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(name)
    }
}

@ViewBuilder
private func projectDetailPreview(for project: String) -> some View {
    NavigationStack {
        List {
            Section("Información") {
                HStack {
                    Text("Estado")
                    Spacer()
                    Text("En Progreso")
                        .foregroundColor(DSColors.accent)
                }

                HStack {
                    Text("Progreso")
                    Spacer()
                    Text("65%")
                }
            }

            Section("Tareas") {
                ForEach(1...5, id: \.self) { num in
                    HStack {
                        Image(systemName: num % 2 == 0 ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(num % 2 == 0 ? DSColors.success : DSColors.textSecondary)
                        Text("Tarea \(num)")
                        Spacer()
                    }
                }
            }

            Section("Equipo") {
                ForEach(1...3, id: \.self) { num in
                    HStack {
                        Circle()
                            .fill(DSColors.accent.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text("U\(num)")
                                    .font(DSTypography.caption)
                                    .foregroundColor(DSColors.accent)
                            )
                        Text("Usuario \(num)")
                    }
                }
            }
        }
        .navigationTitle(project.capitalized)
    }
}
