//
//  DSList.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 3 - Task 3.1: List Patterns
//  SPEC: Adaptación a estándares Apple iOS 18+/macOS 15+
//

import SwiftUI

/// List modernizado con Glass header
///
/// **Características:**
/// - Glass header sections (opcional)
/// - List style: plain
/// - Soporte para Empty State
/// - ViewBuilder para flexibilidad
///
/// **Uso:**
/// ```swift
/// DSList(
///     data: items,
///     headerTitle: "Mis Items"
/// ) { item in
///     DSListRow {
///         Text(item.name)
///     }
/// }
/// ```
@MainActor
public struct DSList<Data: RandomAccessCollection, RowContent: View>: View where Data.Element: Identifiable {
    public let data: Data
    @ViewBuilder public let rowContent: (Data.Element) -> RowContent
    public let headerTitle: String?
    public let glassIntensity: LiquidGlassIntensity
    public let emptyState: AnyView?

    /// Crea un List con glass header
    ///
    /// - Parameters:
    ///   - data: Colección de datos
    ///   - headerTitle: Título del header (opcional)
    ///   - glassIntensity: Intensidad del glass effect
    ///   - emptyState: Vista cuando no hay datos (opcional)
    ///   - rowContent: Contenido de cada row
    public init(
        data: Data,
        headerTitle: String? = nil,
        glassIntensity: LiquidGlassIntensity = .subtle,
        emptyState: (() -> AnyView)? = nil,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) {
        self.data = data
        self.headerTitle = headerTitle
        self.glassIntensity = glassIntensity
        self.emptyState = emptyState?()
        self.rowContent = rowContent
    }

    public var body: some View {
        if data.isEmpty, let empty = emptyState {
            empty
        } else {
            List {
                if let title = headerTitle {
                    Section {
                        ForEach(data) { item in
                            rowContent(item)
                        }
                    } header: {
                        glassHeader(title)
                    }
                } else {
                    ForEach(data) { item in
                        rowContent(item)
                    }
                }
            }
            .listStyle(.plain)
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

// MARK: - Empty State

/// Default empty state view
@MainActor
public struct DSListEmptyState: View {
    public let icon: String
    public let title: String
    public let message: String
    public let action: (() -> Void)?
    public let actionTitle: String?

    public init(
        icon: String = "tray",
        title: String = "No hay elementos",
        message: String = "No se encontraron elementos para mostrar",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: DSSpacing.large) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(DSColors.textSecondary)

            Text(title)
                .font(DSTypography.title2)
                .foregroundColor(DSColors.textPrimary)

            Text(message)
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
                .multilineTextAlignment(.center)

            if let title = actionTitle, let action = action {
                DSButton(title: title, style: .primary, action: action)
            }
        }
        .padding()
    }
}

// MARK: - Previews

#Preview("DSList Basic") {
    struct Item: Identifiable {
        let id = UUID()
        let name: String
    }

    let items = [
        Item(name: "Item 1"),
        Item(name: "Item 2"),
        Item(name: "Item 3")
    ]

    return DSList(
        data: items,
        headerTitle: "Mis Items"
    ) { item in
        Text(item.name)
            .padding()
    }
}

#Preview("DSList con Glass Header") {
    struct Item: Identifiable {
        let id = UUID()
        let name: String
        let subtitle: String
    }

    let items = [
        Item(name: "Proyecto 1", subtitle: "Descripción del proyecto"),
        Item(name: "Proyecto 2", subtitle: "Descripción del proyecto"),
        Item(name: "Proyecto 3", subtitle: "Descripción del proyecto")
    ]

    if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
        return NavigationStack {
            DSList(
                data: items,
                headerTitle: "Proyectos Recientes",
                glassIntensity: .standard
            ) { item in
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(item.name)
                        .font(DSTypography.subheadline)
                    Text(item.subtitle)
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)
                }
                .padding()
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

#Preview("DSList Empty State") {
    struct Item: Identifiable {
        let id = UUID()
        let name: String
    }

    let items: [Item] = []

    return DSList(
        data: items,
        headerTitle: "Mis Items",
        emptyState: {
            AnyView(
                DSListEmptyState(
                    icon: "tray",
                    title: "No hay items",
                    message: "Agrega tu primer item para comenzar",
                    actionTitle: "Agregar Item"
                ) {
                    print("Add item tapped")
                }
            )
        }
    ) { item in
        Text(item.name)
    }
}

#Preview("DSList Sin Header") {
    struct Item: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
    }

    let items = [
        Item(name: "Configuración", icon: "gear"),
        Item(name: "Notificaciones", icon: "bell"),
        Item(name: "Privacidad", icon: "lock")
    ]

    return NavigationStack {
        DSList(data: items) { item in
            HStack {
                Image(systemName: item.icon)
                    .foregroundColor(DSColors.accent)
                Text(item.name)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(DSColors.textSecondary)
            }
            .padding()
        }
        .navigationTitle("Ajustes")
    }
}
