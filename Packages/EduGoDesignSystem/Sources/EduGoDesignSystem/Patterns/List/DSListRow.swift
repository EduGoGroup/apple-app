//
//  DSListRow.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 3 - Task 3.1: List Patterns
//  SPEC: Adaptación a estándares Apple iOS 18+/macOS 15+
//

import SwiftUI

/// List row con swipe actions
///
/// **Características:**
/// - Swipe actions (leading/trailing)
/// - Custom content con ViewBuilder
/// - Full swipe support configurable
/// - Button roles (destructive, cancel)
///
/// **Uso:**
/// ```swift
/// DSListRow(
///     swipeActions: [
///         DSSwipeAction(title: "Eliminar", icon: "trash", tint: .red, role: .destructive) {
///             print("Delete")
///         }
///     ]
/// ) {
///     Text("Item content")
/// }
/// ```
@MainActor
public struct DSListRow<Content: View>: View {
    @ViewBuilder public let content: () -> Content
    public let leadingSwipeActions: [DSSwipeAction]?
    public let trailingSwipeActions: [DSSwipeAction]?
    public let allowsFullSwipe: Bool

    /// Crea un List Row
    ///
    /// - Parameters:
    ///   - leadingSwipeActions: Acciones al swipe desde la izquierda (opcional)
    ///   - trailingSwipeActions: Acciones al swipe desde la derecha (opcional)
    ///   - allowsFullSwipe: Permitir full swipe (default: false)
    ///   - content: Contenido del row
    public init(
        leadingSwipeActions: [DSSwipeAction]? = nil,
        trailingSwipeActions: [DSSwipeAction]? = nil,
        allowsFullSwipe: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.leadingSwipeActions = leadingSwipeActions
        self.trailingSwipeActions = trailingSwipeActions
        self.allowsFullSwipe = allowsFullSwipe
        self.content = content
    }

    /// Compatibilidad con versión anterior (solo trailing actions)
    public init(
        swipeActions: [DSSwipeAction]? = nil,
        allowsFullSwipe: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.leadingSwipeActions = nil
        self.trailingSwipeActions = swipeActions
        self.allowsFullSwipe = allowsFullSwipe
        self.content = content
    }

    public var body: some View {
        content()
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                if let actions = leadingSwipeActions {
                    ForEach(actions) { action in
                        Button(role: action.role) {
                            action.action()
                        } label: {
                            Label(action.title, systemImage: action.icon)
                        }
                        .tint(action.tint)
                    }
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: allowsFullSwipe) {
                if let actions = trailingSwipeActions {
                    ForEach(actions) { action in
                        Button(role: action.role) {
                            action.action()
                        } label: {
                            Label(action.title, systemImage: action.icon)
                        }
                        .tint(action.tint)
                    }
                }
            }
    }
}

// MARK: - Swipe Action

/// Swipe action para List Row
public struct DSSwipeAction: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let icon: String
    public let tint: Color
    public let role: ButtonRole?
    public let action: @Sendable () -> Void

    /// Crea una swipe action
    ///
    /// - Parameters:
    ///   - title: Título del botón
    ///   - icon: Icono SF Symbol
    ///   - tint: Color del botón
    ///   - role: Rol del botón (destructive, cancel)
    ///   - action: Acción al presionar
    public init(
        title: String,
        icon: String,
        tint: Color = DSColors.accent,
        role: ButtonRole? = nil,
        action: @escaping @Sendable () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.role = role
        self.action = action
    }

    /// Swipe action para eliminar
    public static func delete(action: @escaping @Sendable () -> Void) -> DSSwipeAction {
        DSSwipeAction(
            title: "Eliminar",
            icon: "trash",
            tint: DSColors.error,
            role: .destructive,
            action: action
        )
    }

    /// Swipe action para editar
    public static func edit(action: @escaping @Sendable () -> Void) -> DSSwipeAction {
        DSSwipeAction(
            title: "Editar",
            icon: "pencil",
            tint: DSColors.accent,
            action: action
        )
    }

    /// Swipe action para compartir
    public static func share(action: @escaping @Sendable () -> Void) -> DSSwipeAction {
        DSSwipeAction(
            title: "Compartir",
            icon: "square.and.arrow.up",
            tint: .blue,
            action: action
        )
    }

    /// Swipe action para archivar
    public static func archive(action: @escaping @Sendable () -> Void) -> DSSwipeAction {
        DSSwipeAction(
            title: "Archivar",
            icon: "archivebox",
            tint: .orange,
            action: action
        )
    }
}

// MARK: - Previews

#Preview("DSListRow con Swipe Actions") {
    struct Item: Identifiable {
        let id = UUID()
        let name: String
    }

    let items = [
        Item(name: "Item con Delete"),
        Item(name: "Item con Edit y Share"),
        Item(name: "Item con múltiples acciones")
    ]

    return List {
        DSListRow(
            trailingSwipeActions: [.delete { print("Delete") }]
        ) {
            Text(items[0].name)
                .padding()
        }

        DSListRow(
            trailingSwipeActions: [
                .edit { print("Edit") },
                .share { print("Share") }
            ]
        ) {
            Text(items[1].name)
                .padding()
        }

        DSListRow(
            trailingSwipeActions: [
                .delete { print("Delete") },
                .archive { print("Archive") },
                .share { print("Share") }
            ]
        ) {
            Text(items[2].name)
                .padding()
        }
    }
}

#Preview("DSListRow Leading y Trailing") {
    struct Item: Identifiable {
        let id = UUID()
        let name: String
    }

    let items = [
        Item(name: "Email 1"),
        Item(name: "Email 2"),
        Item(name: "Email 3")
    ]

    return List {
        ForEach(items) { item in
            DSListRow(
                leadingSwipeActions: [
                    DSSwipeAction(
                        title: "Marcar",
                        icon: "checkmark.circle",
                        tint: .green
                    ) {
                        print("Mark as read")
                    }
                ],
                trailingSwipeActions: [
                    .delete { print("Delete") },
                    .archive { print("Archive") }
                ]
            ) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(DSColors.accent)
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(DSTypography.subheadline)
                        Text("Descripción del email")
                            .font(DSTypography.caption)
                            .foregroundColor(DSColors.textSecondary)
                    }
                }
                .padding()
            }
        }
    }
}

#Preview("DSListRow Full Swipe") {
    struct Item: Identifiable {
        let id = UUID()
        let name: String
    }

    let items = [
        Item(name: "Swipe completo para eliminar"),
        Item(name: "Otro item con full swipe")
    ]

    return List {
        ForEach(items) { item in
            DSListRow(
                trailingSwipeActions: [.delete { print("Delete \(item.name)") }],
                allowsFullSwipe: true
            ) {
                Text(item.name)
                    .padding()
            }
        }
    }
}

#Preview("DSListRow Completo") {
    struct Task: Identifiable {
        let id = UUID()
        let title: String
        let isCompleted: Bool
    }

    @Previewable @State var tasks = [
        Task(title: "Completar Sprint 2", isCompleted: true),
        Task(title: "Implementar List Patterns", isCompleted: false),
        Task(title: "Crear Dashboard", isCompleted: false)
    ]

    return NavigationStack {
        List {
            ForEach(tasks) { task in
                DSListRow(
                    leadingSwipeActions: [
                        DSSwipeAction(
                            title: task.isCompleted ? "Pendiente" : "Completar",
                            icon: task.isCompleted ? "circle" : "checkmark.circle",
                            tint: task.isCompleted ? .orange : .green
                        ) {
                            print("Toggle complete")
                        }
                    ],
                    trailingSwipeActions: [
                        .edit { print("Edit \(task.title)") },
                        .delete { print("Delete \(task.title)") }
                    ]
                ) {
                    HStack {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isCompleted ? .green : DSColors.textSecondary)

                        Text(task.title)
                            .font(DSTypography.body)
                            .strikethrough(task.isCompleted)
                            .foregroundColor(task.isCompleted ? DSColors.textSecondary : DSColors.textPrimary)

                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Tareas")
    }
}
