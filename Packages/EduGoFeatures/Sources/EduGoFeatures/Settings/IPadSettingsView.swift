//
//  IPadSettingsView.swift
//  EduGoFeatures
//
//  Created on 27-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//  SPEC-006: iPad-optimized settings
//

import SwiftUI
import EduGoDomainCore
import EduGoDesignSystem

/// SettingsView optimizado para iPad
///
/// Características iPad-specific:
/// - Layout de dos paneles (categorías + detalle)
/// - Mejor aprovechamiento del espacio horizontal
/// - Efectos visuales modernos
/// - Controles optimizados para gestos táctiles
@MainActor
public struct IPadSettingsView: View {
    public let updateThemeUseCase: UpdateThemeUseCase
    public let preferencesRepository: PreferencesRepository

    @State private var viewModel: SettingsViewModel
    @State private var selectedCategory: SettingsCategory = .appearance

    public init(
        updateThemeUseCase: UpdateThemeUseCase,
        preferencesRepository: PreferencesRepository
    ) {
        self.updateThemeUseCase = updateThemeUseCase
        self.preferencesRepository = preferencesRepository

        self._viewModel = State(
            initialValue: SettingsViewModel(
                updateThemeUseCase: updateThemeUseCase,
                preferencesRepository: preferencesRepository
            )
        )
    }

    public var body: some View {
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
            IPadSettingsSection(title: "Tema") {
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

            IPadSettingsSection(title: "Efectos Visuales") {
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
            IPadSettingsSection(title: "Notificaciones Push") {
                VStack(alignment: .leading, spacing: DSSpacing.medium) {
                    IPadNotificationToggle(
                        title: "Nuevos cursos",
                        description: "Recibe alertas de cursos nuevos",
                        isOn: .constant(true)
                    )

                    IPadNotificationToggle(
                        title: "Mensajes",
                        description: "Notificaciones de mensajes del foro",
                        isOn: .constant(true)
                    )

                    IPadNotificationToggle(
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
            IPadSettingsSection(title: "Privacidad de Datos") {
                VStack(alignment: .leading, spacing: DSSpacing.medium) {
                    IPadPrivacyRow(
                        icon: "lock.fill",
                        title: "Autenticación Biométrica",
                        description: "Face ID / Touch ID",
                        status: "Activada"
                    )

                    Divider()

                    IPadPrivacyRow(
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
            IPadSettingsSection(title: "Información de la App") {
                VStack(alignment: .leading, spacing: DSSpacing.small) {
                    IPadAboutRow(label: "Versión", value: "0.1.0")
                    IPadAboutRow(label: "Build", value: "1")
                    IPadAboutRow(label: "Platform", value: String(describing: PlatformCapabilities.currentDevice))
                    IPadAboutRow(label: "iOS Version", value: "18.0+")
                }
                .padding(DSSpacing.medium)
                .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.medium))
            }

            IPadSettingsSection(title: "Soporte") {
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

public enum SettingsCategory: String, CaseIterable, Identifiable, Sendable {
    case appearance
    case notifications
    case privacy
    case about

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .appearance: return "Apariencia"
        case .notifications: return "Notificaciones"
        case .privacy: return "Privacidad"
        case .about: return "Acerca de"
        }
    }

    public var icon: String {
        switch self {
        case .appearance: return "paintbrush.fill"
        case .notifications: return "bell.fill"
        case .privacy: return "lock.shield.fill"
        case .about: return "info.circle.fill"
        }
    }

    public var description: String {
        switch self {
        case .appearance: return "Personaliza el aspecto de la aplicación"
        case .notifications: return "Gestiona tus notificaciones"
        case .privacy: return "Configura tu privacidad y seguridad"
        case .about: return "Información de la aplicación"
        }
    }
}

// MARK: - Supporting Views

private struct IPadSettingsSection<Content: View>: View {
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
                Image(systemName: theme.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? DSColors.accent : DSColors.textSecondary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(theme.displayName)
                        .font(DSTypography.body)
                        .foregroundColor(DSColors.textPrimary)

                    Text(themeDescription(for: theme))
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

    private func themeDescription(for theme: Theme) -> String {
        switch theme {
        case .light: return "Modo claro siempre activado"
        case .dark: return "Modo oscuro siempre activado"
        case .system: return "Sigue la configuración del sistema"
        }
    }
}

private struct IPadNotificationToggle: View {
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

private struct IPadPrivacyRow: View {
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

private struct IPadAboutRow: View {
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
