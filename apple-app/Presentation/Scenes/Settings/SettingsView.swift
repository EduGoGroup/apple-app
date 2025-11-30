//
//  SettingsView.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Pantalla de configuración de la aplicación usando DSForm pattern
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
            DSColors.backgroundPrimary
                .ignoresSafeArea()

            DSForm {
            // Sección de Apariencia
            DSFormSection(
                title: String(localized: "settings.section.appearance")
            ) {
                themePicker
            }

            // SPEC-010: Sección de Idioma
            DSFormSection(
                title: String(localized: "settings.section.language")
            ) {
                languagePicker
            }

            // Sección de Información usando DSDetailRow
            DSFormSection(
                title: String(localized: "settings.section.info")
            ) {
                if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
                    infoRowsModern
                } else {
                    infoRowsLegacy
                }
            }
            }
        }
        .navigationTitle(String(localized: "settings.title"))
        #if os(iOS)
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
                        Image(systemName: theme.iconName)
                        Text(theme.displayName)
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

    // Info rows usando DSDetailRow (iOS 18+)
    @available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
    private var infoRowsModern: some View {
        VStack(spacing: 0) {
            DSDetailRow(
                label: String(localized: "settings.info.version"),
                value: "1.0.0"
            )

            Divider()
                .padding(.leading, DSSpacing.medium)

            DSDetailRow(
                label: String(localized: "settings.info.build"),
                value: "1"
            )

            Divider()
                .padding(.leading, DSSpacing.medium)

            DSDetailRow(
                label: String(localized: "settings.info.environment"),
                value: AppEnvironment.displayName
            )
        }
    }

    // Info rows legacy (pre iOS 18)
    private var infoRowsLegacy: some View {
        VStack(spacing: 0) {
            infoRow(
                label: String(localized: "settings.info.version"),
                value: "1.0.0"
            )

            Divider()
                .padding(.leading, DSSpacing.xl)

            infoRow(
                label: String(localized: "settings.info.build"),
                value: "1"
            )

            Divider()
                .padding(.leading, DSSpacing.xl)

            infoRow(
                label: String(localized: "settings.info.environment"),
                value: AppEnvironment.displayName
            )
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
