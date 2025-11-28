//
//  IPadSettingsView.swift
//  apple-app
//
//  Created on 27-11-25.
//  SPEC-006: iPad-optimized settings con iOS 26+ primero
//

import SwiftUI

/// SettingsView optimizado para iPad
///
/// Características iPad-specific:
/// - Layout de dos paneles (categorías + detalle)
/// - Mejor aprovechamiento del espacio horizontal
/// - Efectos visuales modernos (iOS 26+)
/// - Controles optimizados para gestos táctiles
///
/// - Important: Implementado siguiendo REGLA 2.1 de 03-REGLAS-DESARROLLO-IA.md
@MainActor
struct IPadSettingsView: View {
    let updateThemeUseCase: UpdateThemeUseCase
    let preferencesRepository: PreferencesRepository

    @State private var viewModel: SettingsViewModel
    @State private var selectedCategory: SettingsCategory = .appearance

    init(
        updateThemeUseCase: UpdateThemeUseCase,
        preferencesRepository: PreferencesRepository
    ) {
        self.updateThemeUseCase = updateThemeUseCase
        self.preferencesRepository = preferencesRepository

        // ViewModel inicializado con nonisolated init (REGLA 2.1)
        self._viewModel = State(
            initialValue: SettingsViewModel(
                updateThemeUseCase: updateThemeUseCase,
                preferencesRepository: preferencesRepository
            )
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            // Panel izquierdo: Categorías
            categoriesPanel
                .frame(width: 280)

            Divider()

            // Panel derecho: Detalle de configuración
            detailPanel
                .frame(maxWidth: .infinity)
        }
        .background(DSColors.backgroundPrimary)
        .navigationTitle("Configuración")
        .task {
            await viewModel.loadPreferences()
        }
    }

    // MARK: - Categories Panel

    private var categoriesPanel: some View {
        List {
            ForEach(SettingsCategory.allCases) { category in
                Button {
                    selectedCategory = category
                } label: {
                    HStack {
                        Label(category.title, systemImage: category.icon)
                            .font(DSTypography.body)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    selectedCategory == category
                        ? DSColors.accent.opacity(0.1)
                        : Color.clear
                )
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Detail Panel

    private var detailPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                // Header de categoría
                categoryHeader

                Divider()

                // Contenido según categoría seleccionada
                switch selectedCategory {
                case .appearance:
                    appearanceSettings
                case .notifications:
                    notificationsSettings
                case .privacy:
                    privacySettings
                case .about:
                    aboutSettings
                }
            }
            .padding(DSSpacing.xl)
        }
    }

    // MARK: - Category Header

    private var categoryHeader: some View {
        HStack(spacing: DSSpacing.medium) {
            Image(systemName: selectedCategory.icon)
                .font(.system(size: 32))
                .foregroundColor(DSColors.accent)

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(selectedCategory.title)
                    .font(DSTypography.title)
                    .foregroundColor(DSColors.textPrimary)

                Text(selectedCategory.description)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Appearance Settings

    private var appearanceSettings: some View {
        VStack(alignment: .leading, spacing: DSSpacing.large) {
            SettingsSection(title: "Tema") {
                VStack(spacing: DSSpacing.medium) {
                    ThemeOptionCard(
                        theme: .light,
                        isSelected: viewModel.currentTheme == .light
                    ) {
                        Task {
                            await viewModel.updateTheme(.light)
                        }
                    }

                    ThemeOptionCard(
                        theme: .dark,
                        isSelected: viewModel.currentTheme == .dark
                    ) {
                        Task {
                            await viewModel.updateTheme(.dark)
                        }
                    }

                    ThemeOptionCard(
                        theme: .system,
                        isSelected: viewModel.currentTheme == .system
                    ) {
                        Task {
                            await viewModel.updateTheme(.system)
                        }
                    }
                }
            }

            SettingsSection(title: "Efectos Visuales") {
                VStack(alignment: .leading, spacing: DSSpacing.small) {
                    Toggle("Reducir transparencia", isOn: .constant(false))
                        .font(DSTypography.body)

                    Text("Desactiva los efectos de vidrio para mejor rendimiento")
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)
                }
                .padding(DSSpacing.medium)
                .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.medium))
            }
        }
    }

    // MARK: - Notifications Settings

    private var notificationsSettings: some View {
        VStack(alignment: .leading, spacing: DSSpacing.large) {
            SettingsSection(title: "Notificaciones Push") {
                VStack(alignment: .leading, spacing: DSSpacing.medium) {
                    NotificationToggle(
                        title: "Nuevos cursos",
                        description: "Recibe alertas de cursos nuevos",
                        isOn: .constant(true)
                    )

                    NotificationToggle(
                        title: "Mensajes",
                        description: "Notificaciones de mensajes del foro",
                        isOn: .constant(true)
                    )

                    NotificationToggle(
                        title: "Actualizaciones",
                        description: "Noticias sobre actualizaciones de la app",
                        isOn: .constant(false)
                    )
                }
            }
        }
    }

    // MARK: - Privacy Settings

    private var privacySettings: some View {
        VStack(alignment: .leading, spacing: DSSpacing.large) {
            SettingsSection(title: "Privacidad de Datos") {
                VStack(alignment: .leading, spacing: DSSpacing.medium) {
                    PrivacyRow(
                        icon: "lock.fill",
                        title: "Autenticación Biométrica",
                        description: "Face ID / Touch ID",
                        status: "Activada"
                    )

                    Divider()

                    PrivacyRow(
                        icon: "eye.slash.fill",
                        title: "Modo Privado",
                        description: "No guardar historial",
                        status: "Desactivado"
                    )
                }
                .padding(DSSpacing.medium)
                .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.medium))
            }
        }
    }

    // MARK: - About Settings

    private var aboutSettings: some View {
        VStack(alignment: .leading, spacing: DSSpacing.large) {
            SettingsSection(title: "Información de la App") {
                VStack(alignment: .leading, spacing: DSSpacing.small) {
                    AboutRow(label: "Versión", value: "0.1.0")
                    AboutRow(label: "Build", value: "1")
                    AboutRow(label: "Platform", value: String(describing: PlatformCapabilities.currentDevice))
                    AboutRow(label: "iOS Version", value: "26.0+")
                }
                .padding(DSSpacing.medium)
                .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.medium))
            }

            SettingsSection(title: "Soporte") {
                VStack(spacing: DSSpacing.small) {
                    DSButton(title: "Política de Privacidad", style: .secondary) {
                        // TODO: Abrir política de privacidad
                    }

                    DSButton(title: "Términos de Servicio", style: .secondary) {
                        // TODO: Abrir términos
                    }

                    DSButton(title: "Contactar Soporte", style: .secondary) {
                        // TODO: Abrir soporte
                    }
                }
            }
        }
    }
}

// MARK: - Settings Category

enum SettingsCategory: String, CaseIterable, Identifiable {
    case appearance
    case notifications
    case privacy
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance: return "Apariencia"
        case .notifications: return "Notificaciones"
        case .privacy: return "Privacidad"
        case .about: return "Acerca de"
        }
    }

    var icon: String {
        switch self {
        case .appearance: return "paintbrush.fill"
        case .notifications: return "bell.fill"
        case .privacy: return "lock.shield.fill"
        case .about: return "info.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .appearance: return "Personaliza el aspecto de la aplicación"
        case .notifications: return "Gestiona tus notificaciones"
        case .privacy: return "Configura tu privacidad y seguridad"
        case .about: return "Información de la aplicación"
        }
    }
}

// MARK: - Supporting Views

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            Text(title)
                .font(DSTypography.bodyBold)
                .foregroundColor(DSColors.textPrimary)

            content
        }
    }
}

private struct ThemeOptionCard: View {
    let theme: Theme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.medium) {
                Image(systemName: theme.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? DSColors.accent : DSColors.textSecondary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(theme.displayName)
                        .font(DSTypography.body)
                        .foregroundColor(DSColors.textPrimary)

                    Text(theme.description)
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(DSColors.accent)
                }
            }
            .padding(DSSpacing.medium)
        }
        .buttonStyle(.plain)
        .dsGlassEffect(
            isSelected ? .tinted(DSColors.accent.opacity(0.1)) : .regular,
            shape: .roundedRectangle(cornerRadius: DSCornerRadius.medium)
        )
    }
}

private struct NotificationToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(title)
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textPrimary)

                Text(description)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(DSSpacing.medium)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.medium))
    }
}

private struct PrivacyRow: View {
    let icon: String
    let title: String
    let description: String
    let status: String

    var body: some View {
        HStack(spacing: DSSpacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(DSColors.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(title)
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textPrimary)

                Text(description)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)
            }

            Spacer()

            Text(status)
                .font(DSTypography.caption)
                .foregroundColor(DSColors.accent)
        }
    }
}

private struct AboutRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)

            Spacer()

            Text(value)
                .font(DSTypography.body)
                .foregroundColor(DSColors.textPrimary)
        }
        .padding(.vertical, DSSpacing.xs)
    }
}

// MARK: - Theme Extension

extension Theme {
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "sparkles"
        }
    }

    var description: String {
        switch self {
        case .light: return "Modo claro siempre activado"
        case .dark: return "Modo oscuro siempre activado"
        case .system: return "Sigue la configuración del sistema"
        }
    }
}

// MARK: - Previews

#Preview("iPad Settings", traits: .fixedLayout(width: 1366, height: 1024)) {
    NavigationStack {
        IPadSettingsView(
            updateThemeUseCase: PreviewMocks.updateThemeUseCase,
            preferencesRepository: PreviewMocks.preferencesRepository
        )
    }
}

// MARK: - Preview Mocks

private enum PreviewMocks {
    @MainActor
    static var updateThemeUseCase: UpdateThemeUseCase {
        MockUpdateThemeUseCase()
    }

    @MainActor
    static var preferencesRepository: PreferencesRepository {
        MockPreferencesRepository()
    }
}

@MainActor
private final class MockUpdateThemeUseCase: UpdateThemeUseCase {
    func execute(_ theme: Theme) async {
        // Mock
    }
}

@MainActor
private final class MockPreferencesRepository: PreferencesRepository {
    func getPreferences() async -> UserPreferences {
        UserPreferences(theme: .system, language: "es", biometricsEnabled: false)
    }

    func savePreferences(_ preferences: UserPreferences) async {
        // Mock
    }

    func updateTheme(_ theme: Theme) async {
        // Mock
    }

    func updateLanguage(_ language: Language) async {
        // Mock
    }

    func updateBiometricsEnabled(_ enabled: Bool) async {
        // Mock
    }

    func observeTheme() -> AsyncStream<Theme> {
        AsyncStream { continuation in
            continuation.yield(.system)
            continuation.finish()
        }
    }

    func observePreferences() -> AsyncStream<UserPreferences> {
        AsyncStream { continuation in
            continuation.yield(UserPreferences(theme: .system, language: "es", biometricsEnabled: false))
            continuation.finish()
        }
    }
}
