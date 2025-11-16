//
//  AppNavigationView.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Vista principal de navegación de la aplicación
/// Maneja el routing y la inyección de dependencias
struct AppNavigationView: View {
    @State private var coordinator = NavigationCoordinator()

    // Dependencias (Dependency Injection)
    private let apiClient: APIClient
    private let keychainService: KeychainService
    private let authRepository: AuthRepository
    private let preferencesRepository: PreferencesRepository

    init() {
        // Inicializar servicios
        self.apiClient = DefaultAPIClient(baseURL: AppConfig.baseURL)
        self.keychainService = DefaultKeychainService.shared

        // Inicializar repositorios
        self.authRepository = AuthRepositoryImpl(
            apiClient: apiClient,
            keychainService: keychainService
        )
        self.preferencesRepository = PreferencesRepositoryImpl()
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            // Pantalla inicial: Splash
            splashView
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .environment(coordinator)
    }

    // MARK: - Views

    private var splashView: some View {
        SplashView(authRepository: authRepository)
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .splash:
            splashView

        case .login:
            LoginView(
                loginUseCase: DefaultLoginUseCase(
                    authRepository: authRepository,
                    validator: DefaultInputValidator()
                )
            )

        case .home:
            HomeView(
                getCurrentUserUseCase: DefaultGetCurrentUserUseCase(
                    authRepository: authRepository
                ),
                logoutUseCase: DefaultLogoutUseCase(
                    authRepository: authRepository
                )
            )

        case .settings:
            SettingsView(
                updateThemeUseCase: DefaultUpdateThemeUseCase(
                    preferencesRepository: preferencesRepository
                ),
                preferencesRepository: preferencesRepository
            )
        }
    }
}

// MARK: - Previews

#Preview {
    AppNavigationView()
}
