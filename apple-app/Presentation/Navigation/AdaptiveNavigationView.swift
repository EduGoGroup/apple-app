//
//  AdaptiveNavigationView.swift
//  apple-app
//
//  Created on 16-11-25.
//  Refactored on 23-11-25.
//

import SwiftUI

/// Vista raíz de navegación que maneja autenticación y navegación adaptativa
///
/// Arquitectura:
/// - NO autenticado: Muestra LoginView fullscreen (sin sidebar)
/// - Autenticado: Muestra navegación completa con sidebar (iPad/Mac) o tabs (iPhone)
struct AdaptiveNavigationView: View {
    @State private var authState = AuthenticationState()
    @State private var isCheckingSession = true

    @EnvironmentObject var container: DependencyContainer

    var body: some View {
        Group {
            if isCheckingSession {
                // Splash mientras verifica sesión
                SplashScreen()
            } else if authState.isAuthenticated {
                // Usuario autenticado: Mostrar app completa
                AuthenticatedApp()
                    .environment(authState)
                    .environmentObject(container)
            } else {
                // Usuario NO autenticado: Mostrar login fullscreen
                LoginFlow()
                    .environment(authState)
                    .environmentObject(container)
            }
        }
        .task {
            await checkInitialSession()
        }
    }

    // MARK: - Session Check

    @MainActor
    private func checkInitialSession() async {
        // Delay para mostrar splash
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Por ahora, siempre ir a login
        // TODO: Verificar sesión guardada en Keychain
        authState.logout()
        isCheckingSession = false
    }
}

// MARK: - Splash Screen

private struct SplashScreen: View {
    var body: some View {
        ZStack {
            DSColors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: DSSpacing.xl) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 80))
                    .foregroundColor(DSColors.accent)

                Text("EduGo")
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: DSColors.accent))
                    .scaleEffect(1.2)
            }
        }
    }
}

// MARK: - Login Flow (Sin Sidebar)

private struct LoginFlow: View {
    @Environment(AuthenticationState.self) private var authState
    @EnvironmentObject var container: DependencyContainer

    var body: some View {
        LoginView(loginUseCase: container.resolve(LoginUseCase.self))
            .environment(authState)
    }
}

// MARK: - Authenticated App (Con Sidebar)

private struct AuthenticatedApp: View {
    @Environment(AuthenticationState.self) private var authState
    @EnvironmentObject var container: DependencyContainer
    @State private var selectedRoute: Route = .home

    var body: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            // iPhone: NavigationStack simple
            phoneNavigation
        } else {
            // iPad: NavigationSplitView con sidebar
            tabletNavigation
        }
        #else
        // macOS: NavigationSplitView con sidebar
        desktopNavigation
        #endif
    }

    // MARK: - iPhone Navigation

    private var phoneNavigation: some View {
        TabView(selection: $selectedRoute) {
            destination(for: .home)
                .tabItem {
                    Label("Inicio", systemImage: "house.fill")
                }
                .tag(Route.home)

            destination(for: .settings)
                .tabItem {
                    Label("Configuración", systemImage: "gear")
                }
                .tag(Route.settings)
        }
    }

    // MARK: - iPad/Mac Navigation

    private var tabletNavigation: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            destination(for: selectedRoute)
        }
    }

    private var desktopNavigation: some View {
        NavigationSplitView {
            sidebar
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        } detail: {
            destination(for: selectedRoute)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List {
            Section("Navegación") {
                #if os(macOS)
                Button {
                    selectedRoute = .home
                } label: {
                    Label("Inicio", systemImage: "house.fill")
                }

                Button {
                    selectedRoute = .settings
                } label: {
                    Label("Configuración", systemImage: "gear")
                }
                #else
                NavigationLink(value: Route.home) {
                    Label("Inicio", systemImage: "house.fill")
                }

                NavigationLink(value: Route.settings) {
                    Label("Configuración", systemImage: "gear")
                }
                #endif
            }

            Section("Cuenta") {
                Button(role: .destructive) {
                    Task {
                        await performLogout()
                    }
                } label: {
                    Label("Cerrar Sesión", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("EduGo")
        #if os(macOS)
        .listStyle(.sidebar)
        #endif
    }

    // MARK: - Destinations

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .login:
            // Login nunca debería mostrarse aquí (ya estamos autenticados)
            EmptyView()

        case .home:
            HomeView(
                getCurrentUserUseCase: container.resolve(GetCurrentUserUseCase.self),
                logoutUseCase: container.resolve(LogoutUseCase.self),
                authState: authState
            )

        case .settings:
            SettingsView(
                updateThemeUseCase: container.resolve(UpdateThemeUseCase.self),
                preferencesRepository: container.resolve(PreferencesRepository.self)
            )
        }
    }

    // MARK: - Logout

    private func performLogout() async {
        let logoutUseCase = container.resolve(LogoutUseCase.self)
        _ = await logoutUseCase.execute()
        authState.logout()
    }
}

// MARK: - Previews

#Preview("Login Flow") {
    let container = DependencyContainer()
    // Setup básico para preview
    container.register(KeychainService.self, scope: .singleton) {
        DefaultKeychainService.shared
    }
    container.register(APIClient.self, scope: .singleton) {
        DefaultAPIClient(baseURL: AppEnvironment.authAPIBaseURL)
    }
    container.register(JWTDecoder.self, scope: .singleton) {
        DefaultJWTDecoder()
    }
    container.register(BiometricAuthService.self, scope: .singleton) {
        LocalAuthenticationService()
    }
    container.register(TokenRefreshCoordinator.self, scope: .singleton) {
        TokenRefreshCoordinator(
            apiClient: container.resolve(APIClient.self),
            keychainService: container.resolve(KeychainService.self),
            jwtDecoder: container.resolve(JWTDecoder.self)
        )
    }
    container.register(AuthRepository.self, scope: .singleton) {
        AuthRepositoryImpl(
            apiClient: container.resolve(APIClient.self),
            keychainService: container.resolve(KeychainService.self),
            jwtDecoder: container.resolve(JWTDecoder.self),
            tokenCoordinator: container.resolve(TokenRefreshCoordinator.self),
            biometricService: container.resolve(BiometricAuthService.self)
        )
    }
    container.register(InputValidator.self, scope: .singleton) {
        DefaultInputValidator()
    }
    container.register(LoginUseCase.self) {
        DefaultLoginUseCase(
            authRepository: container.resolve(AuthRepository.self),
            validator: container.resolve(InputValidator.self)
        )
    }

    return AdaptiveNavigationView()
        .environmentObject(container)
}
