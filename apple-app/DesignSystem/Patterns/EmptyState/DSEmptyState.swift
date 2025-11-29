//
//  DSEmptyState.swift
//  apple-app
//
//  Created on 29-11-25.
//

import SwiftUI

/// Vista reutilizable para estados vacíos
/// Muestra iconos, títulos, mensajes y acciones opcionales
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct DSEmptyState: View {
    let icon: String
    let title: String
    let message: String?
    let actionTitle: String?
    let action: (() -> Void)?
    let style: EmptyStateStyle

    init(
        icon: String,
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        style: EmptyStateStyle = .standard
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        self.style = style
    }

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            // Icon
            iconView

            // Text content
            VStack(spacing: DSSpacing.small) {
                Text(title)
                    .font(style.titleFont)
                    .foregroundColor(DSColors.textPrimary)
                    .multilineTextAlignment(.center)

                if let message = message {
                    Text(message)
                        .font(style.messageFont)
                        .foregroundColor(DSColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, DSSpacing.xl)

            // Action button
            if let actionTitle = actionTitle, let action = action {
                actionButton(title: actionTitle, action: action)
            }
        }
        .frame(maxWidth: style.maxWidth)
        .padding(DSSpacing.xxl)
    }

    @ViewBuilder
    private var iconView: some View {
        switch style {
        case .standard, .compact:
            Image(systemName: icon)
                .font(.system(size: style.iconSize))
                .foregroundColor(DSColors.textTertiary)
        case .colorful(let color):
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: style.iconSize + 40, height: style.iconSize + 40)

                Image(systemName: icon)
                    .font(.system(size: style.iconSize))
                    .foregroundColor(color)
            }
        case .glass:
            ZStack {
                Circle()
                    .fill(DSColors.surfaceGlass)
                    .frame(width: style.iconSize + 40, height: style.iconSize + 40)
                    .glassAwareShadow(level: .sm)

                Image(systemName: icon)
                    .font(.system(size: style.iconSize))
                    .foregroundColor(DSColors.accent)
            }
        }
    }

    private func actionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DSTypography.button)
                .foregroundColor(.white)
                .padding(.horizontal, DSSpacing.xl)
                .padding(.vertical, DSSpacing.medium)
                .background(DSColors.accent)
                .cornerRadius(DSCornerRadius.medium)
        }
        .buttonStyle(.plain)
        .dsShadow(level: .sm)
    }
}

/// Estilos de Empty State
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
enum EmptyStateStyle {
    case standard
    case compact
    case colorful(Color)
    case glass

    var iconSize: CGFloat {
        switch self {
        case .standard, .colorful, .glass:
            return 60
        case .compact:
            return 40
        }
    }

    var titleFont: Font {
        switch self {
        case .standard, .colorful, .glass:
            return DSTypography.title2
        case .compact:
            return DSTypography.title3
        }
    }

    var messageFont: Font {
        switch self {
        case .standard, .colorful, .glass:
            return DSTypography.body
        case .compact:
            return DSTypography.bodySmall
        }
    }

    var maxWidth: CGFloat {
        switch self {
        case .standard, .colorful, .glass:
            return 400
        case .compact:
            return 300
        }
    }
}

// MARK: - Preset Empty States

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
extension DSEmptyState {
    /// Empty state para listas vacías
    static func emptyList(
        title: String = "No hay elementos",
        message: String? = "Aún no hay elementos para mostrar",
        actionTitle: String? = "Agregar",
        action: (() -> Void)? = nil
    ) -> DSEmptyState {
        DSEmptyState(
            icon: "tray",
            title: title,
            message: message,
            actionTitle: actionTitle,
            action: action,
            style: .standard
        )
    }

    /// Empty state para búsquedas sin resultados
    static func noResults(
        query: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> DSEmptyState {
        let message = query != nil
            ? "No se encontraron resultados para '\(query!)'"
            : "No se encontraron resultados"

        return DSEmptyState(
            icon: "magnifyingglass",
            title: "Sin resultados",
            message: message,
            actionTitle: actionTitle,
            action: action,
            style: .standard
        )
    }

    /// Empty state para errores de red
    static func networkError(
        message: String = "Revisa tu conexión a internet e intenta de nuevo",
        actionTitle: String = "Reintentar",
        action: @escaping () -> Void
    ) -> DSEmptyState {
        DSEmptyState(
            icon: "wifi.slash",
            title: "Sin conexión",
            message: message,
            actionTitle: actionTitle,
            action: action,
            style: .colorful(DSColors.error)
        )
    }

    /// Empty state para permisos denegados
    static func permissionDenied(
        permissionType: String,
        message: String,
        actionTitle: String = "Abrir Configuración",
        action: @escaping () -> Void
    ) -> DSEmptyState {
        DSEmptyState(
            icon: "lock.shield",
            title: "Permiso denegado",
            message: message,
            actionTitle: actionTitle,
            action: action,
            style: .colorful(DSColors.warning)
        )
    }
}

// MARK: - Previews

#Preview("Empty State Styles") {
    ScrollView {
        VStack(spacing: DSSpacing.xxxl) {
            Text("Empty State Styles")
                .font(DSTypography.title)
                .frame(maxWidth: .infinity, alignment: .leading)

            DSEmptyState(
                icon: "tray",
                title: "Standard Style",
                message: "Este es el estilo estándar para empty states",
                actionTitle: "Acción",
                action: {},
                style: .standard
            )

            Divider()

            DSEmptyState(
                icon: "magnifyingglass",
                title: "Compact Style",
                message: "Estilo más compacto",
                style: .compact
            )

            Divider()

            DSEmptyState(
                icon: "heart.fill",
                title: "Colorful Style",
                message: "Con color de acento",
                actionTitle: "Explorar",
                action: {},
                style: .colorful(DSColors.error)
            )

            Divider()

            DSEmptyState(
                icon: "sparkles",
                title: "Glass Style",
                message: "Con efecto Glass",
                actionTitle: "Comenzar",
                action: {},
                style: .glass
            )
        }
        .padding()
    }
    .background(DSColors.backgroundSecondary)
}

#Preview("Preset Empty States") {
    ScrollView {
        VStack(spacing: DSSpacing.xxxl) {
            Text("Preset Empty States")
                .font(DSTypography.title)
                .frame(maxWidth: .infinity, alignment: .leading)

            DSEmptyState.emptyList(
                title: "Sin favoritos",
                message: "Aún no has agregado ningún favorito",
                actionTitle: "Explorar",
                action: {}
            )

            Divider()

            DSEmptyState.noResults(
                query: "iPhone 16 Pro",
                actionTitle: "Borrar búsqueda",
                action: {}
            )

            Divider()

            DSEmptyState.networkError(
                action: {}
            )

            Divider()

            DSEmptyState.permissionDenied(
                permissionType: "Cámara",
                message: "Necesitamos acceso a tu cámara para escanear códigos QR",
                action: {}
            )
        }
        .padding()
    }
    .background(DSColors.backgroundSecondary)
}

#Preview("In Context - Empty List") {
    NavigationStack {
        DSEmptyState.emptyList(
            title: "Sin mensajes",
            message: "Aún no tienes mensajes en tu bandeja de entrada",
            actionTitle: "Nuevo mensaje",
            action: {}
        )
        .navigationTitle("Mensajes")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

#Preview("In Context - No Results") {
    NavigationStack {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DSColors.textSecondary)
                Text("iPhone 16 Pro")
                    .foregroundColor(DSColors.textPrimary)
                Spacer()
            }
            .padding()
            .background(DSColors.backgroundSecondary)

            Divider()

            // Empty state
            DSEmptyState.noResults(
                query: "iPhone 16 Pro",
                actionTitle: "Borrar búsqueda",
                action: {}
            )
            .frame(maxHeight: .infinity)
        }
        .navigationTitle("Búsqueda")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview("In Context - Network Error") {
    NavigationStack {
        DSEmptyState.networkError {
            print("Retry tapped")
        }
        .frame(maxHeight: .infinity)
        .navigationTitle("Productos")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

#Preview("Multiple States") {
    TabView {
        // Empty list
        NavigationStack {
            DSEmptyState.emptyList(
                title: "Sin tareas",
                message: "No tienes tareas pendientes",
                actionTitle: "Nueva tarea",
                action: {}
            )
            .navigationTitle("Tareas")
        }
        .tabItem {
            Label("Tareas", systemImage: "checkmark.circle")
        }

        // No results
        NavigationStack {
            DSEmptyState.noResults(
                query: "Proyecto X",
                actionTitle: "Limpiar",
                action: {}
            )
            .navigationTitle("Búsqueda")
        }
        .tabItem {
            Label("Buscar", systemImage: "magnifyingglass")
        }

        // Network error
        NavigationStack {
            DSEmptyState.networkError {
                print("Retry")
            }
            .navigationTitle("Feed")
        }
        .tabItem {
            Label("Feed", systemImage: "newspaper")
        }
    }
}
