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
                    Text("Apariencia")
                        .font(DSTypography.subheadline)
                }

                // Sección de Información
                Section {
                    infoRows
                } header: {
                    Text("Información")
                        .font(DSTypography.subheadline)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Configuración")
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
            Label("Tema", systemImage: "paintbrush")
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

    private var infoRows: some View {
        VStack(spacing: 0) {
            infoRow(label: "Versión", value: "1.0.0")
            Divider().padding(.leading, DSSpacing.xl)
            infoRow(label: "Build", value: "1")
            Divider().padding(.leading, DSSpacing.xl)
            infoRow(label: "Ambiente", value: AppEnvironment.displayName)
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
            return "Claro"
        case .dark:
            return "Oscuro"
        case .system:
            return "Sistema"
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
