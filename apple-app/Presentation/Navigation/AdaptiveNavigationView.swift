//
//  AdaptiveNavigationView.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Vista de navegación adaptativa que cambia según el dispositivo
/// - iPhone: NavigationStack
/// - iPad/Mac: NavigationSplitView con sidebar
struct AdaptiveNavigationView: View {
    @State private var coordinator = NavigationCoordinator()
    @State private var selectedRoute: Route? = nil

    // Dependencias
    private let authRepository: AuthRepository
    private let preferencesRepository: PreferencesRepository

    init(
        authRepository: AuthRepository,
        preferencesRepository: PreferencesRepository
    ) {
        self.authRepository = authRepository
        self.preferencesRepository = preferencesRepository
    }

    var body: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            // iPhone: NavigationStack tradicional
            phoneNavigation
        } else {
            // iPad: NavigationSplitView
            tabletNavigation
        }
        #else
        // macOS: NavigationSplitView
        desktopNavigation
        #endif
    }

    // MARK: - iPhone Navigation

    private var phoneNavigation: some View {
        NavigationStack(path: $coordinator.path) {
            SplashView(authRepository: authRepository)
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .environment(coordinator)
    }

    // MARK: - iPad Navigation

    private var tabletNavigation: some View {
        NavigationSplitView {
            // Sidebar
            sidebarContent
        } detail: {
            // Detail view
            if let route = selectedRoute {
                destination(for: route)
            } else {
                SplashView(authRepository: authRepository)
            }
        }
        .environment(coordinator)
    }

    // MARK: - macOS Navigation

    private var desktopNavigation: some View {
        NavigationSplitView {
            // Sidebar más compacto para macOS
            sidebarContent
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        } detail: {
            // Detail view
            if let route = selectedRoute {
                destination(for: route)
            } else {
                SplashView(authRepository: authRepository)
            }
        }
        .environment(coordinator)
    }

    // MARK: - Sidebar Content

    private var sidebarContent: some View {
        List(selection: $selectedRoute) {
            Section("Navegación") {
                NavigationLink(value: Route.home) {
                    Label("Inicio", systemImage: "house.fill")
                }

                NavigationLink(value: Route.settings) {
                    Label("Configuración", systemImage: "gear")
                }
            }

            Section("Cuenta") {
                Button {
                    Task {
                        let logoutUseCase = DefaultLogoutUseCase(authRepository: authRepository)
                        _ = await logoutUseCase.execute()
                        selectedRoute = .login
                    }
                } label: {
                    Label("Cerrar Sesión", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("EduGo")
        .listStyle(.sidebar)
    }

    // MARK: - Destination Builder

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .splash:
            SplashView(authRepository: authRepository)

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

#Preview("Adaptive Navigation") {
    AdaptiveNavigationView(
        authRepository: AuthRepositoryImpl(
            apiClient: DefaultAPIClient(baseURL: AppConfig.baseURL)
        ),
        preferencesRepository: PreferencesRepositoryImpl()
    )
}
