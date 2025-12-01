//
//  DSTabBar.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 1 - Task 1.2: Navigation Patterns
//  SPEC: Adaptación a estándares Apple iOS26/macOS26
//

import SwiftUI

// MARK: - Tab Bar Item

/// Item de tab bar del Design System
///
/// Representa un elemento individual en la barra de pestañas.
///
/// **Uso:**
/// ```swift
/// let homeTab = DSTabBarItem(
///     id: "home",
///     title: "Inicio",
///     icon: "house",
///     selectedIcon: "house.fill"
/// )
/// ```
public struct DSTabBarItem: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let icon: String
    public let selectedIcon: String?
    public let badge: Int?

    /// Crea un item de tab bar
    ///
    /// - Parameters:
    ///   - id: Identificador único del tab
    ///   - title: Título mostrado debajo del icono
    ///   - icon: Nombre del SF Symbol para estado normal
    ///   - selectedIcon: Nombre del SF Symbol para estado seleccionado (opcional)
    ///   - badge: Número de badge (opcional)
    public init(
        id: String,
        title: String,
        icon: String,
        selectedIcon: String? = nil,
        badge: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.badge = badge
    }

    /// Icono a mostrar según el estado de selección
    ///
    /// - Parameter isSelected: Si el tab está seleccionado
    /// - Returns: Nombre del SF Symbol apropiado
    public func iconName(isSelected: Bool) -> String {
        if isSelected, let selectedIcon = selectedIcon {
            return selectedIcon
        }
        return icon
    }
}

// MARK: - Tab Bar Pattern

/// Tab Bar del Design System
///
/// Implementa el pattern de Tab Bar estándar de Apple con soporte
/// para Liquid Glass en iOS 18+.
///
/// **Características:**
/// - Hasta 5 tabs recomendado (HIG)
/// - Badges opcionales
/// - Iconos con estado selected/normal
/// - Liquid Glass en iOS 18+ (opcional)
///
/// **Uso:**
/// ```swift
/// @State private var selectedTab = "home"
///
/// DSTabBar(
///     selection: $selectedTab,
///     items: [
///         DSTabBarItem(id: "home", title: "Inicio", icon: "house", selectedIcon: "house.fill"),
///         DSTabBarItem(id: "search", title: "Buscar", icon: "magnifyingglass"),
///         DSTabBarItem(id: "profile", title: "Perfil", icon: "person", selectedIcon: "person.fill", badge: 3)
///     ]
/// ) {
///     // Content for each tab
///     HomeView().tag("home")
///     SearchView().tag("search")
///     ProfileView().tag("profile")
/// }
/// ```
public struct DSTabBar<Content: View>: View {
    @Binding public var selection: String
    public let items: [DSTabBarItem]
    public let useGlass: Bool
    @ViewBuilder public let content: () -> Content

    /// Crea un Tab Bar
    ///
    /// - Parameters:
    ///   - selection: Binding al ID del tab seleccionado
    ///   - items: Array de items del tab bar
    ///   - useGlass: Si debe usar Liquid Glass en iOS 18+ (default: true)
    ///   - content: Contenido de cada tab (debe usar .tag() con IDs)
    public init(
        selection: Binding<String>,
        items: [DSTabBarItem],
        useGlass: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._selection = selection
        self.items = items
        self.useGlass = useGlass
        self.content = content
    }

    public var body: some View {
        TabView(selection: $selection) {
            content()
        }
        .tabViewStyle(.automatic)
    }
}

// MARK: - Custom Tab Bar (para mayor control)

/// Tab Bar personalizado con Liquid Glass
///
/// Alternativa al TabView nativo cuando se necesita mayor control
/// sobre el diseño y animaciones.
///
/// **Uso:**
/// ```swift
/// @State private var selectedTab = "home"
///
/// DSCustomTabBar(
///     selection: $selectedTab,
///     items: tabItems
/// ) { selectedId in
///     switch selectedId {
///     case "home": HomeView()
///     case "search": SearchView()
///     case "profile": ProfileView()
///     default: EmptyView()
///     }
/// }
/// ```
@MainActor
public struct DSCustomTabBar<Content: View>: View {
    @Binding public var selection: String
    public let items: [DSTabBarItem]
    public let glassIntensity: LiquidGlassIntensity
    @ViewBuilder public let content: (String) -> Content

    /// Crea un Tab Bar personalizado
    ///
    /// - Parameters:
    ///   - selection: Binding al ID del tab seleccionado
    ///   - items: Array de items del tab bar
    ///   - glassIntensity: Intensidad del efecto glass (iOS 18+)
    ///   - content: Closure que devuelve el contenido para cada tab ID
    public init(
        selection: Binding<String>,
        items: [DSTabBarItem],
        glassIntensity: LiquidGlassIntensity = .standard,
        @ViewBuilder content: @escaping (String) -> Content
    ) {
        self._selection = selection
        self.items = items
        self.glassIntensity = glassIntensity
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Content area
            content(selection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            tabBarView
        }
    }

    @ViewBuilder
    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                tabButton(for: item)
            }
        }
        .padding(.horizontal, DSSpacing.medium)
        .padding(.vertical, DSSpacing.small)
        .background(tabBarBackground)
    }

    @ViewBuilder
    private var tabBarBackground: some View {
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            Rectangle()
                .fill(.clear)
                .dsGlassEffect(.liquidGlass(glassIntensity))
                .ignoresSafeArea(edges: .bottom)
        } else {
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    @ViewBuilder
    private func tabButton(for item: DSTabBarItem) -> some View {
        let isSelected = selection == item.id

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selection = item.id
            }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: item.iconName(isSelected: isSelected))
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? DSColors.accent : DSColors.textSecondary)

                    if let badge = item.badge, badge > 0 {
                        badgeView(count: badge)
                            .offset(x: 8, y: -8)
                    }
                }

                Text(item.title)
                    .font(DSTypography.caption2)
                    .foregroundColor(isSelected ? DSColors.accent : DSColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func badgeView(count: Int) -> some View {
        Text("\(min(count, 99))")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(DSColors.error)
            )
            .frame(minWidth: 18, minHeight: 18)
    }
}

// MARK: - Previews

#Preview("Tab Bar Estándar") {
    @Previewable @State var selectedTab = "home"

    let items = [
        DSTabBarItem(id: "home", title: "Inicio", icon: "house", selectedIcon: "house.fill"),
        DSTabBarItem(id: "search", title: "Buscar", icon: "magnifyingglass"),
        DSTabBarItem(id: "favorites", title: "Favoritos", icon: "heart", selectedIcon: "heart.fill", badge: 5),
        DSTabBarItem(id: "profile", title: "Perfil", icon: "person", selectedIcon: "person.fill", badge: 1)
    ]

    DSTabBar(selection: $selectedTab, items: items) {
        NavigationStack {
            VStack {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DSColors.accent)
                Text("Vista de Inicio")
                    .font(DSTypography.title)
            }
            .navigationTitle("Inicio")
        }
        .tag("home")

        NavigationStack {
            VStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(DSColors.accent)
                Text("Vista de Búsqueda")
                    .font(DSTypography.title)
            }
            .navigationTitle("Buscar")
        }
        .tag("search")

        NavigationStack {
            VStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DSColors.accent)
                Text("Vista de Favoritos")
                    .font(DSTypography.title)
            }
            .navigationTitle("Favoritos")
        }
        .tag("favorites")

        NavigationStack {
            VStack {
                Image(systemName: "person.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DSColors.accent)
                Text("Vista de Perfil")
                    .font(DSTypography.title)
            }
            .navigationTitle("Perfil")
        }
        .tag("profile")
    }
}

#Preview("Custom Tab Bar con Glass") {
    @Previewable @State var selectedTab = "home"

    let items = [
        DSTabBarItem(id: "home", title: "Inicio", icon: "house", selectedIcon: "house.fill"),
        DSTabBarItem(id: "search", title: "Buscar", icon: "magnifyingglass"),
        DSTabBarItem(id: "notifications", title: "Notif.", icon: "bell", selectedIcon: "bell.fill", badge: 12),
        DSTabBarItem(id: "profile", title: "Perfil", icon: "person", selectedIcon: "person.fill")
    ]

    if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
        DSCustomTabBar(
            selection: $selectedTab,
            items: items,
            glassIntensity: .standard
        ) { tabId in
            NavigationStack {
                VStack(spacing: DSSpacing.xl) {
                    Image(systemName: iconForTab(tabId))
                        .font(.system(size: 80))
                        .foregroundColor(DSColors.accent)

                    Text("Tab: \(tabId)")
                        .font(DSTypography.largeTitle)

                    Text("Custom Tab Bar con Liquid Glass")
                        .font(DSTypography.body)
                        .foregroundColor(DSColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .navigationTitle(titleForTab(tabId))
            }
        }
    } else {
        Text("Custom Tab Bar requiere iOS 18+")
    }
}

// MARK: - Preview Helpers

@MainActor
private func iconForTab(_ id: String) -> String {
    switch id {
    case "home": return "house.fill"
    case "search": return "magnifyingglass"
    case "notifications": return "bell.fill"
    case "profile": return "person.fill"
    default: return "questionmark"
    }
}

@MainActor
private func titleForTab(_ id: String) -> String {
    switch id {
    case "home": return "Inicio"
    case "search": return "Buscar"
    case "notifications": return "Notificaciones"
    case "profile": return "Perfil"
    default: return "Tab"
    }
}
