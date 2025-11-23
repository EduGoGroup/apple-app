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

    // Dependency Container
    @EnvironmentObject var container: DependencyContainer

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
            SplashView(authRepository: container.resolve(AuthRepository.self))
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
                SplashView(authRepository: container.resolve(AuthRepository.self))
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
                SplashView(authRepository: container.resolve(AuthRepository.self))
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
                        let logoutUseCase = container.resolve(LogoutUseCase.self)
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
            SplashView(authRepository: container.resolve(AuthRepository.self))

        case .login:
            LoginView(loginUseCase: container.resolve(LoginUseCase.self))

        case .home:
            HomeView(
                getCurrentUserUseCase: container.resolve(GetCurrentUserUseCase.self),
                logoutUseCase: container.resolve(LogoutUseCase.self)
            )

        case .settings:
            SettingsView(
                updateThemeUseCase: container.resolve(UpdateThemeUseCase.self),
                preferencesRepository: container.resolve(PreferencesRepository.self)
            )
        }
    }
}

// MARK: - Previews

#Preview("Adaptive Navigation") {
    let previewContainer = DependencyContainer()

    // Setup mínimo para preview
    previewContainer.register(KeychainService.self, scope: .singleton) {
        DefaultKeychainService.shared
    }

    previewContainer.register(APIClient.self, scope: .singleton) {
        DefaultAPIClient(baseURL: AppConfig.baseURL)
    }

    previewContainer.register(AuthRepository.self, scope: .singleton) {
        AuthRepositoryImpl(
            apiClient: previewContainer.resolve(APIClient.self),
            keychainService: previewContainer.resolve(KeychainService.self)
        )
    }

    previewContainer.register(PreferencesRepository.self, scope: .singleton) {
        PreferencesRepositoryImpl()
    }

    previewContainer.register(InputValidator.self, scope: .singleton) {
        DefaultInputValidator()
    }

    previewContainer.register(LoginUseCase.self) {
        DefaultLoginUseCase(
            authRepository: previewContainer.resolve(AuthRepository.self),
            validator: previewContainer.resolve(InputValidator.self)
        )
    }

    previewContainer.register(LogoutUseCase.self) {
        DefaultLogoutUseCase(
            authRepository: previewContainer.resolve(AuthRepository.self)
        )
    }

    previewContainer.register(GetCurrentUserUseCase.self) {
        DefaultGetCurrentUserUseCase(
            authRepository: previewContainer.resolve(AuthRepository.self)
        )
    }

    previewContainer.register(UpdateThemeUseCase.self) {
        DefaultUpdateThemeUseCase(
            preferencesRepository: previewContainer.resolve(PreferencesRepository.self)
        )
    }

    return AdaptiveNavigationView()
        .environmentObject(previewContainer)
}
