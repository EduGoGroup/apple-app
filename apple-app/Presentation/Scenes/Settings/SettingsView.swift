//
//  SettingsView.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Pantalla de configuración de la aplicación
struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    init(
        updateThemeUseCase: UpdateThemeUseCase,
        preferencesRepository: PreferencesRepository
    ) {
        self._viewModel = State(
            initialValue: SettingsViewModel(
                updateThemeUseCase: updateThemeUseCase,
                preferencesRepository: preferencesRepository
            )
        )
    }

    var body: some View {
        ZStack {
            DSColors.backgroundPrimary.ignoresSafeArea()

            Form {
                // Sección de Apariencia
                Section {
                    themePicker
                } header: {
                    Text(String(localized: "settings.section.appearance"))
                        .font(DSTypography.subheadline)
                }

                // SPEC-010: Sección de Idioma
                Section {
                    languagePicker
                } header: {
                    Text(String(localized: "settings.section.language"))
                        .font(DSTypography.subheadline)
                }

                // Sección de Información
                Section {
                    infoRows
                } header: {
                    Text(String(localized: "settings.section.info"))
                        .font(DSTypography.subheadline)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(String(localized: "settings.title"))
        #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .task {
            await viewModel.loadPreferences()
        }
    }

    // MARK: - View Components

    private var themePicker: some View {
        HStack {
            Label(String(localized: "settings.theme.label"), systemImage: "paintbrush")
                .font(DSTypography.body)

            Spacer()

            Picker("", selection: Binding(
                get: { viewModel.currentTheme },
                set: { theme in
                    Task {
                        await viewModel.updateTheme(theme)
                    }
                }
            )) {
                ForEach(Theme.allCases, id: \.self) { theme in
                    HStack {
                        Image(systemName: themeIcon(for: theme))
                        Text(themeDisplayName(for: theme))
                    }
                    .tag(theme)
                }
            }
            .pickerStyle(.menu)
            .disabled(viewModel.isLoading)
        }
    }

    // SPEC-010: Language Picker
    private var languagePicker: some View {
        HStack {
            Label(String(localized: "settings.language.label"), systemImage: "globe")
                .font(DSTypography.body)

            Spacer()

            Picker("", selection: Binding(
                get: { viewModel.currentLanguage },
                set: { language in
                    Task {
                        await viewModel.updateLanguage(language)
                    }
                }
            )) {
                ForEach(Language.allCases, id: \.self) { language in
                    HStack {
                        Text(language.flagEmoji)
                        Text(language.displayName)
                    }
                    .tag(language)
                }
            }
            .pickerStyle(.menu)
            .disabled(viewModel.isLoading)
        }
    }

    private var infoRows: some View {
        VStack(spacing: 0) {
            infoRow(label: String(localized: "settings.info.version"), value: "1.0.0")
            Divider().padding(.leading, DSSpacing.xl)
            infoRow(label: String(localized: "settings.info.build"), value: "1")
            Divider().padding(.leading, DSSpacing.xl)
            infoRow(label: String(localized: "settings.info.environment"), value: AppEnvironment.displayName)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(DSTypography.body)
                .foregroundColor(DSColors.textPrimary)

            Spacer()

            Text(value)
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
        }
        .padding(.vertical, DSSpacing.small)
    }

    // MARK: - Helpers

    private func themeIcon(for theme: Theme) -> String {
        switch theme {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "gear"
        }
    }

    private func themeDisplayName(for theme: Theme) -> String {
        switch theme {
        case .light:
            return String(localized: "settings.theme.light")
        case .dark:
            return String(localized: "settings.theme.dark")
        case .system:
            return String(localized: "settings.theme.system")
        }
    }
}

// MARK: - Previews

#Preview("Settings") {
    let prefsRepo = PreferencesRepositoryImpl()

    NavigationStack {
        SettingsView(
            updateThemeUseCase: DefaultUpdateThemeUseCase(preferencesRepository: prefsRepo),
            preferencesRepository: prefsRepo
        )
    }
    .environment(NavigationCoordinator())
}
