//
//  MacOSSettingsView.swift
//  apple-app
//
//  Created on 27-11-25.
//  SPEC-006: macOS-optimized settings con iOS 26+/macOS 26+ primero
//

#if os(macOS)
import SwiftUI

/// SettingsView optimizado para macOS usando DSForm pattern
///
/// Características macOS-specific:
/// - Estilo de Settings nativo de macOS (TabView con iconos)
/// - Window sizing apropiado
/// - Keyboard shortcuts integrados
/// - macOS-style controls con DSForm
///
/// - Important: Solo disponible en macOS
@MainActor
struct MacOSSettingsView: View {
    let updateThemeUseCase: UpdateThemeUseCase
    let preferencesRepository: PreferencesRepository

    @State private var viewModel: SettingsViewModel
    @State private var selectedTab: SettingsTab = .general

    init(
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

    var body: some View {
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
                if #available(macOS 15.0, *) {
                    LabeledContent("Versión") {
                        Text("0.1.0 (Pre-release)")
                            .foregroundColor(.secondary)
                    }

                    LabeledContent("Platform") {
                        Text(String(describing: PlatformCapabilities.currentDevice))
                            .foregroundColor(.secondary)
                    }

                    LabeledContent("macOS Version") {
                        Text("26.0+")
                            .foregroundColor(.secondary)
                    }
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
                            Image(systemName: theme.icon)
                            Text(theme.displayName)
                        }
                        .tag(theme)
                    }
                }
                .pickerStyle(.inline)
            }

            DSFormSection(title: "Accesibilidad") {
                Toggle("Reducir transparencia", isOn: .constant(false))
                Toggle("Aumentar contraste", isOn: .constant(false))
                Toggle("Reducir movimiento", isOn: .constant(false))
            }

            DSFormSection(title: "Tipografía") {
                Picker("Tamaño de fuente", selection: .constant("medium")) {
                    Text("Pequeño").tag("small")
                    Text("Mediano").tag("medium")
                    Text("Grande").tag("large")
                }
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
                .foregroundColor(.red)
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

                if #available(macOS 15.0, *) {
                    LabeledContent("Auth API") {
                        Text(AppEnvironment.authAPIBaseURL.absoluteString)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    LabeledContent("Mobile API") {
                        Text(AppEnvironment.mobileAPIBaseURL.absoluteString)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }

            DSFormSection(title: "Utilidades") {
                Button("Ver atajos de teclado...") {
                    // TODO: Mostrar ventana de shortcuts
                }

                Button("Restablecer configuración...") {
                    // TODO: Implementar reset
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Settings Tabs

enum SettingsTab: String, CaseIterable {
    case general
    case appearance
    case notifications
    case privacy
    case advanced
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
}

// MARK: - Previews

#Preview("macOS Settings") {
    MacOSSettingsView(
        updateThemeUseCase: PreviewMocks.updateThemeUseCase,
        preferencesRepository: PreviewMocks.preferencesRepository
    )
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

#endif // os(macOS)
