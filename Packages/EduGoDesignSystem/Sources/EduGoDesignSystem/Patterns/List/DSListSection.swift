//
//  DSListSection.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 3 - Task 3.1: List Patterns
//  SPEC: Adaptación a estándares Apple iOS 18+/macOS 15+
//

import SwiftUI

/// List section con header y footer
///
/// **Características:**
/// - Header con título
/// - Footer con descripción
/// - Glass header opcional
/// - ViewBuilder para flexibilidad
///
/// **Uso:**
/// ```swift
/// DSListSection(
///     title: "Sección 1",
///     footer: "Descripción de la sección"
/// ) {
///     // List items
/// }
/// ```
@MainActor
public struct DSListSection<Content: View>: View {
    public let title: String?
    public let footer: String?
    public let useGlassHeader: Bool
    public let glassIntensity: LiquidGlassIntensity
    @ViewBuilder public let content: () -> Content

    /// Crea una sección de lista
    ///
    /// - Parameters:
    ///   - title: Título de la sección (opcional)
    ///   - footer: Pie de la sección (opcional)
    ///   - useGlassHeader: Usar glass header (iOS 18+)
    ///   - glassIntensity: Intensidad del glass effect
    ///   - content: Contenido de la sección
    public init(
        title: String? = nil,
        footer: String? = nil,
        useGlassHeader: Bool = false,
        glassIntensity: LiquidGlassIntensity = .subtle,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.useGlassHeader = useGlassHeader
        self.glassIntensity = glassIntensity
        self.content = content
    }

    public var body: some View {
        Section {
            content()
        } header: {
            if let title = title {
                if useGlassHeader {
                    glassHeader(title)
                } else {
                    Text(title)
                        .font(DSTypography.subheadline)
                        .foregroundColor(DSColors.textPrimary)
                        .textCase(nil)
                }
            }
        } footer: {
            if let footer = footer {
                Text(footer)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func glassHeader(_ title: String) -> some View {
        if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
            Text(title)
                .font(DSTypography.title3)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .dsGlassEffect(.liquidGlass(glassIntensity))
        } else {
            Text(title)
                .font(DSTypography.title3)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DSColors.backgroundSecondary)
        }
    }
}

// MARK: - Previews

#Preview("DSListSection Basic") {
    List {
        DSListSection(title: "Sección 1") {
            Text("Item 1").padding()
            Text("Item 2").padding()
            Text("Item 3").padding()
        }

        DSListSection(title: "Sección 2", footer: "Esta es una descripción de la sección") {
            Text("Item A").padding()
            Text("Item B").padding()
        }
    }
}

#Preview("DSListSection con Glass Header") {
    if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
        return NavigationStack {
            List {
                DSListSection(
                    title: "Proyectos Recientes",
                    useGlassHeader: true,
                    glassIntensity: .standard
                ) {
                    ForEach(0..<3) { index in
                        VStack(alignment: .leading) {
                            Text("Proyecto \(index + 1)")
                                .font(DSTypography.subheadline)
                            Text("Descripción del proyecto")
                                .font(DSTypography.caption)
                                .foregroundColor(DSColors.textSecondary)
                        }
                        .padding()
                    }
                }

                DSListSection(
                    title: "Archivados",
                    footer: "Proyectos completados o archivados",
                    useGlassHeader: true,
                    glassIntensity: .subtle
                ) {
                    ForEach(0..<2) { index in
                        Text("Proyecto Archivado \(index + 1)")
                            .padding()
                            .foregroundColor(DSColors.textSecondary)
                    }
                }
            }
            .navigationTitle("Proyectos")
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    } else {
        return Text("Glass requiere iOS 18+")
    }
}

#Preview("DSListSection Múltiples") {
    NavigationStack {
        List {
            DSListSection(
                title: "Favoritos",
                footer: "Tus items favoritos"
            ) {
                ForEach(0..<3) { index in
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Favorito \(index + 1)")
                    }
                    .padding()
                }
            }

            DSListSection(
                title: "Recientes",
                footer: "Últimos items visitados"
            ) {
                ForEach(0..<5) { index in
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(DSColors.textSecondary)
                        Text("Reciente \(index + 1)")
                    }
                    .padding()
                }
            }

            DSListSection(
                title: "Todos",
                footer: "Todos los items disponibles"
            ) {
                ForEach(0..<10) { index in
                    Text("Item \(index + 1)")
                        .padding()
                }
            }
        }
        .navigationTitle("Items")
    }
}

#Preview("DSListSection Sin Header/Footer") {
    List {
        DSListSection {
            Text("Item 1").padding()
            Text("Item 2").padding()
            Text("Item 3").padding()
        }
    }
}

#Preview("DSListSection con Swipe Actions") {
    List {
        DSListSection(
            title: "Tareas Pendientes",
            footer: "Desliza para más opciones"
        ) {
            ForEach(0..<3) { index in
                DSListRow(
                    trailingSwipeActions: [
                        .edit { print("Edit task \(index)") },
                        .delete { print("Delete task \(index)") }
                    ]
                ) {
                    HStack {
                        Image(systemName: "circle")
                            .foregroundColor(DSColors.textSecondary)
                        Text("Tarea \(index + 1)")
                    }
                    .padding()
                }
            }
        }

        DSListSection(
            title: "Tareas Completadas",
            footer: "\(2) tareas completadas"
        ) {
            ForEach(0..<2) { index in
                DSListRow(
                    trailingSwipeActions: [.delete { print("Delete") }]
                ) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Tarea Completada \(index + 1)")
                            .strikethrough()
                            .foregroundColor(DSColors.textSecondary)
                    }
                    .padding()
                }
            }
        }
    }
}
