//
//  SettingsView.swift
//  EduGoFeatures
//
//  Created on 16-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//

import SwiftUI
import EduGoDomainCore
import EduGoDesignSystem
import EduGoFoundation

/// Pantalla de configuración de la aplicación usando DSForm pattern
public struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    public init(
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

    public var body: some View {
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

                // Sección de Idioma
                DSFormSection(
                    title: String(localized: "settings.section.language")
                ) {
                    languagePicker
                }

                // Sección de Información usando DSDetailRow
                DSFormSection(
                    title: String(localized: "settings.section.info")
                ) {
                    infoRows
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
}
