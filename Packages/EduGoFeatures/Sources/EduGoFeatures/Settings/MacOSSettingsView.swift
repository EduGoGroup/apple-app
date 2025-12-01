//
//  MacOSSettingsView.swift
//  EduGoFeatures
//
//  Created on 01-12-25.
//  Migrated from apple-app for SPM modularization
//  SPEC-006: macOS-optimized settings
//

#if os(macOS)
import SwiftUI
import EduGoDomainCore
import EduGoDesignSystem

// MARK: - Settings Tabs

/// Tabs para la vista de Settings de macOS
public enum SettingsTab: String, CaseIterable, Sendable {
    case general
    case appearance
    case notifications
    case privacy
    case advanced
}

// MARK: - MacOSSettingsView

/// SettingsView optimizado para macOS usando TabView nativo
///
/// Características macOS-specific:
/// - Estilo de Settings nativo de macOS (TabView con iconos)
/// - Window sizing apropiado
/// - Keyboard shortcuts integrados
/// - macOS-style controls con DSForm
///
/// - Important: Solo disponible en macOS
@MainActor
public struct MacOSSettingsView: View {
    // MARK: - Dependencies

    private let updateThemeUseCase: UpdateThemeUseCase
    private let preferencesRepository: PreferencesRepository

    // MARK: - State

    @State private var viewModel: SettingsViewModel
    @State private var selectedTab: SettingsTab = .general

    // MARK: - Init

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

    // MARK: - Body

    public var body: some View {
        TabView(selection: $selectedTab) {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(SettingsTab.general)

            appearanceTab
                .tabItem {
                    Label("Apariencia", systemImage: "paintbrush")
                }
                .tag(SettingsTab.appearance)

            notificationsTab
                .tabItem {
                    Label("Notificaciones", systemImage: "bell")
                }
                .tag(SettingsTab.notifications)

            privacyTab
                .tabItem {
                    Label("Privacidad", systemImage: "lock.shield")
                }
                .tag(SettingsTab.privacy)

            advancedTab
                .tabItem {
                    Label("Avanzado", systemImage: "slider.horizontal.3")
                }
                .tag(SettingsTab.advanced)
        }
        .frame(width: 600, height: 500)
        .task {
            await viewModel.loadPreferences()
        }
    }

    // MARK: - General Tab

    private var generalTab: some View {
        DSForm {
            DSFormSection(title: "Información de la App") {
                LabeledContent("Versión") {
                    Text("0.1.0 (Pre-release)")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Plataforma") {
                    Text("macOS")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("macOS Version") {
                    Text("15.0+")
                        .foregroundStyle(.secondary)
                }
            }

            DSFormSection(title: "Comportamiento") {
                Toggle("Iniciar al arrancar el sistema", isOn: .constant(false))
                Toggle("Mantener en el Dock", isOn: .constant(true))
                Toggle("Mostrar icono en barra de menú", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Appearance Tab

    private var appearanceTab: some View {
        DSForm {
            DSFormSection(title: "Tema de Apariencia") {
                Picker("Tema", selection: Binding(
                    get: { viewModel.currentTheme },
                    set: { theme in
                        Task {
                            await viewModel.updateTheme(theme)
                        }
                    }
                )) {
                    ForEach([Theme.light, Theme.dark, Theme.system], id: \.self) { theme in
                        HStack {
                            Image(systemName: theme.iconName)
                            Text(theme.displayName)
                        }
                        .tag(theme)
                    }
                }
                .pickerStyle(.inline)
            }

            DSFormSection(title: "Idioma") {
                Picker("Idioma", selection: Binding(
                    get: { viewModel.currentLanguage },
                    set: { language in
                        Task {
                            await viewModel.updateLanguage(language)
                        }
                    }
                )) {
                    ForEach(Array(Language.allCases), id: \.self) { (language: Language) in
                        HStack {
                            Text(language.flagEmoji)
                            Text(language.displayName)
                        }
                        .tag(language)
                    }
                }
                .pickerStyle(.inline)
            }

            DSFormSection(title: "Accesibilidad") {
                Toggle("Reducir transparencia", isOn: .constant(false))
                Toggle("Aumentar contraste", isOn: .constant(false))
                Toggle("Reducir movimiento", isOn: .constant(false))
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Notifications Tab

    private var notificationsTab: some View {
        DSForm {
            DSFormSection(title: "General") {
                Toggle("Activar notificaciones", isOn: .constant(true))
            }

            DSFormSection(title: "Tipos de Notificaciones") {
                Toggle("Nuevos cursos", isOn: .constant(true))
                Toggle("Mensajes del foro", isOn: .constant(true))
                Toggle("Actualizaciones de la app", isOn: .constant(false))
                Toggle("Recordatorios de estudio", isOn: .constant(true))
            }

            DSFormSection(title: "Estilo") {
                Toggle("Mostrar en centro de notificaciones", isOn: .constant(true))
                Toggle("Reproducir sonido", isOn: .constant(true))
                Toggle("Mostrar badge en Dock", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Privacy Tab

    private var privacyTab: some View {
        DSForm {
            DSFormSection(title: "Seguridad") {
                Toggle("Autenticación biométrica (Touch ID)", isOn: .constant(true))

                Button("Cambiar contraseña...") {
                    // TODO: Implementar cambio de contraseña
                }
                .buttonStyle(.link)
            }

            DSFormSection(title: "Privacidad de Datos") {
                Toggle("Compartir datos de uso", isOn: .constant(false))
                Toggle("Análisis de rendimiento", isOn: .constant(false))

                Button("Ver política de privacidad...") {
                    if let url = URL(string: "https://edugo.com/privacy") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
            }

            DSFormSection(title: "Datos Almacenados") {
                Button("Limpiar caché...") {
                    // TODO: Implementar limpieza de caché
                }

                Button("Borrar datos de sesión...") {
                    // TODO: Implementar borrado de datos
                }
                .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Advanced Tab

    private var advancedTab: some View {
        DSForm {
            DSFormSection(title: "Desarrollo") {
                Toggle("Modo de desarrollo", isOn: .constant(false))
                Toggle("Mostrar logs en consola", isOn: .constant(false))
                Toggle("Activar debug de red", isOn: .constant(false))
            }

            DSFormSection(title: "Configuración de API") {
                Picker("Entorno API", selection: .constant("production")) {
                    Text("Producción").tag("production")
                    Text("Staging").tag("staging")
                    Text("Desarrollo").tag("development")
                }
            }

            DSFormSection(title: "Utilidades") {
                Button("Ver atajos de teclado...") {
                    // TODO: Mostrar ventana de shortcuts
                }

                Button("Restablecer configuración...") {
                    // TODO: Implementar reset
                }
                .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Preview

#Preview("macOS Settings") {
    MacOSSettingsView(
        updateThemeUseCase: MockUpdateThemeUseCase(),
        preferencesRepository: MockPreferencesRepository()
    )
}

// MARK: - Preview Mocks

@MainActor
private final class MockUpdateThemeUseCase: UpdateThemeUseCase {
    func execute(_ theme: Theme) async {
        // Mock - no operation
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

#endif // os(macOS)
