//
//  AdaptiveNavigationView.swift
//  apple-app
//
//  Created on 16-11-25.
//  Refactored on 27-11-25.
//  SPEC-006: Enhanced with iPad/macOS/visionOS optimization
//

import SwiftUI

/// Vista raíz de navegación que maneja autenticación y navegación adaptativa
///
/// Arquitectura:
/// - NO autenticado: Muestra LoginView fullscreen (sin sidebar)
/// - Autenticado: Muestra navegación completa adaptada por plataforma:
///   - iPhone: TabView
///   - iPad: NavigationSplitView con sidebar colapsable
///   - macOS: NavigationSplitView con toolbar y sidebar fijo
///   - visionOS: Window groups con navegación espacial
///
/// - Important: Usa PlatformCapabilities para detección de plataforma
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

        // Verificar si hay sesión guardada en Keychain
        let authRepository = container.resolve(AuthRepository.self)
        let hasSession = await authRepository.hasActiveSession()

        if hasSession {
            // Recuperar usuario actual del token guardado
            let userResult = await authRepository.getCurrentUser()

            switch userResult {
            case .success(let user):
                // Restaurar sesión
                authState.authenticate(user: user)
            case .failure:
                // Si falla obtener el usuario, hacer logout
                authState.logout()
            }
        } else {
            // No hay sesión guardada
            authState.logout()
        }

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

// MARK: - Authenticated App (Adaptativo por Plataforma)

private struct AuthenticatedApp: View {
    @Environment(AuthenticationState.self) private var authState
    @EnvironmentObject var container: DependencyContainer
    @State private var selectedRoute: Route = .home
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    // Environment values para Size Classes
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        // Usar PlatformCapabilities para determinar el estilo de navegación
        switch PlatformCapabilities.recommendedNavigationStyle {
        case .tabs:
            phoneNavigation
        case .sidebar:
            tabletNavigation
        case .spatial:
            #if os(visionOS)
            spatialNavigation
            #else
            tabletNavigation // Fallback si no es visionOS
            #endif
        }
    }

    // MARK: - iPhone Navigation

    private var phoneNavigation: some View {
        TabView(selection: $selectedRoute) {
            destination(for: .home)
                .tabItem {
                    Label(String(localized: "home.title"), systemImage: "house.fill")
                }
                .tag(Route.home)

            destination(for: .courses)
                .tabItem {
                    Label(String(localized: "courses.title"), systemImage: "book.fill")
                }
                .tag(Route.courses)

            destination(for: .progress)
                .tabItem {
                    Label(String(localized: "progress.title"), systemImage: "chart.bar.fill")
                }
                .tag(Route.progress)

            destination(for: .settings)
                .tabItem {
                    Label(String(localized: "settings.title"), systemImage: "gear")
                }
                .tag(Route.settings)
        }
        .tint(DSColors.accent)
    }

    // MARK: - iPad/Mac Navigation

    private var tabletNavigation: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            sidebarContent
                .navigationSplitViewColumnWidth(
                    min: sidebarMinWidth,
                    ideal: sidebarIdealWidth,
                    max: sidebarMaxWidth
                )
        } detail: {
            // Detail view
            destination(for: selectedRoute)
                .navigationTitle(navigationTitle)
                #if os(macOS)
                .toolbar {
                    macOSToolbar
                }
                #endif
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - Sidebar Configuration

    private var sidebarMinWidth: CGFloat {
        #if os(macOS)
        return 200
        #else
        return 250
        #endif
    }

    private var sidebarIdealWidth: CGFloat {
        #if os(macOS)
        return 250
        #else
        // iPad: Más ancho para mejor usabilidad con dedos
        return 320
        #endif
    }

    private var sidebarMaxWidth: CGFloat {
        #if os(macOS)
        return 300
        #else
        return 400
        #endif
    }

    // MARK: - Sidebar Content

    private var sidebarContent: some View {
        List {
            Section("Navegación") {
                NavigationLink(value: Route.home) {
                    Label(String(localized: "home.title"), systemImage: "house.fill")
                }
                .tag(Route.home)

                NavigationLink(value: Route.courses) {
                    Label(String(localized: "courses.title"), systemImage: "book.fill")
                }
                .tag(Route.courses)

                NavigationLink(value: Route.calendar) {
                    Label(String(localized: "calendar.title"), systemImage: "calendar")
                }
                .tag(Route.calendar)

                NavigationLink(value: Route.progress) {
                    Label(String(localized: "progress.title"), systemImage: "chart.bar.fill")
                }
                .tag(Route.progress)

                NavigationLink(value: Route.community) {
                    Label(String(localized: "community.title"), systemImage: "person.2.fill")
                }
                .tag(Route.community)

                NavigationLink(value: Route.settings) {
                    Label(String(localized: "settings.title"), systemImage: "gear")
                }
                .tag(Route.settings)
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

            // Información de plataforma (solo en DEBUG)
            #if DEBUG
            Section("Debug") {
                DisclosureGroup("Platform Info") {
                    Text(PlatformCapabilities.debugDescription)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            #endif
        }
        .navigationTitle("EduGo")
        #if os(macOS)
        .listStyle(.sidebar)
        #else
        .listStyle(.insetGrouped)
        #endif
    }

    // MARK: - macOS Toolbar

    #if os(macOS)
    @ToolbarContentBuilder
    private var macOSToolbar: some ToolbarContent {
        MacOSToolbarConfiguration.mainToolbarContent(
            onSidebarToggle: {
                MacOSWindowControls.toggleSidebar()
            },
            onRefresh: {
                Task {
                    await refreshCurrentView()
                }
            },
            onSearch: {
                // TODO: Implementar búsqueda
                print("Search triggered")
            }
        )
    }

    /// Refresca la vista actual según la ruta seleccionada
    private func refreshCurrentView() async {
        switch selectedRoute {
        case .home:
            // TODO: Refrescar home - recargar datos del usuario
            break
        case .courses:
            // TODO: Refrescar courses
            break
        case .calendar:
            // TODO: Refrescar calendar
            break
        case .progress:
            // TODO: Refrescar progress
            break
        case .community:
            // TODO: Refrescar community
            break
        case .settings:
            // TODO: Refrescar settings
            break
        case .login:
            break
        }
    }
    #endif

    // MARK: - Navigation Title

    private var navigationTitle: String {
        switch selectedRoute {
        case .home:
            return String(localized: "home.title")
        case .courses:
            return String(localized: "courses.title")
        case .calendar:
            return String(localized: "calendar.title")
        case .progress:
            return String(localized: "progress.title")
        case .community:
            return String(localized: "community.title")
        case .settings:
            return String(localized: "settings.title")
        case .login:
            return ""
        }
    }

    // MARK: - Destinations

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .login:
            // Login nunca debería mostrarse aquí (ya estamos autenticados)
            EmptyView()

        case .home:
            // Usar layout específico según plataforma
            #if os(visionOS)
            VisionOSHomeView(
                getCurrentUserUseCase: container.resolve(GetCurrentUserUseCase.self),
                logoutUseCase: container.resolve(LogoutUseCase.self),
                getRecentActivityUseCase: container.resolve(GetRecentActivityUseCase.self),
                getUserStatsUseCase: container.resolve(GetUserStatsUseCase.self),
                getRecentCoursesUseCase: container.resolve(GetRecentCoursesUseCase.self),
                authState: authState
            )
            #elseif os(macOS)
            // macOS usa el mismo layout que iPad (pantalla grande)
            IPadHomeView(
                getCurrentUserUseCase: container.resolve(GetCurrentUserUseCase.self),
                logoutUseCase: container.resolve(LogoutUseCase.self),
                getRecentActivityUseCase: container.resolve(GetRecentActivityUseCase.self),
                getUserStatsUseCase: container.resolve(GetUserStatsUseCase.self),
                getRecentCoursesUseCase: container.resolve(GetRecentCoursesUseCase.self),
                authState: authState
            )
            #else
            // iOS: iPad usa layout de dos columnas, iPhone usa layout simple
            if PlatformCapabilities.isIPad {
                IPadHomeView(
                    getCurrentUserUseCase: container.resolve(GetCurrentUserUseCase.self),
                    logoutUseCase: container.resolve(LogoutUseCase.self),
                    getRecentActivityUseCase: container.resolve(GetRecentActivityUseCase.self),
                    getUserStatsUseCase: container.resolve(GetUserStatsUseCase.self),
                    getRecentCoursesUseCase: container.resolve(GetRecentCoursesUseCase.self),
                    authState: authState
                )
            } else {
                HomeView(
                    getCurrentUserUseCase: container.resolve(GetCurrentUserUseCase.self),
                    logoutUseCase: container.resolve(LogoutUseCase.self),
                    getRecentActivityUseCase: container.resolve(GetRecentActivityUseCase.self),
                    getUserStatsUseCase: container.resolve(GetUserStatsUseCase.self),
                    getRecentCoursesUseCase: container.resolve(GetRecentCoursesUseCase.self),
                    authState: authState
                )
            }
            #endif

        case .settings:
            // Usar layout específico según plataforma
            if PlatformCapabilities.isIPad {
                IPadSettingsView(
                    updateThemeUseCase: container.resolve(UpdateThemeUseCase.self),
                    preferencesRepository: container.resolve(PreferencesRepository.self)
                )
            } else {
                SettingsView(
                    updateThemeUseCase: container.resolve(UpdateThemeUseCase.self),
                    preferencesRepository: container.resolve(PreferencesRepository.self)
                )
            }

        case .courses:
            #if os(visionOS)
            VisionOSCoursesView()
            #else
            if PlatformCapabilities.isIPad {
                IPadCoursesView()
            } else {
                CoursesView()
            }
            #endif

        case .calendar:
            #if os(visionOS)
            VisionOSCalendarView()
            #else
            if PlatformCapabilities.isIPad {
                IPadCalendarView()
            } else {
                CalendarView()
            }
            #endif

        case .progress:
            #if os(visionOS)
            VisionOSProgressView()
            #else
            if PlatformCapabilities.isIPad {
                IPadProgressView()
            } else {
                UserProgressView()
            }
            #endif

        case .community:
            #if os(visionOS)
            VisionOSCommunityView()
            #else
            if PlatformCapabilities.isIPad {
                IPadCommunityView()
            } else {
                CommunityView()
            }
            #endif
        }
    }

    // MARK: - visionOS Spatial Navigation

    #if os(visionOS)
    private var spatialNavigation: some View {
        NavigationSplitView {
            spatialSidebar
        } detail: {
            destination(for: selectedRoute)
                .ornament(attachmentAnchor: .scene(.bottom)) {
                    VisionOSConfiguration.navigationOrnament(
                        onHome: { selectedRoute = .home },
                        onSettings: { selectedRoute = .settings }
                    )
                }
                .ornament(attachmentAnchor: .scene(.top)) {
                    VisionOSConfiguration.actionsOrnament(
                        onRefresh: {
                            Task {
                                // Refrescar vista actual
                            }
                        },
                        onShare: {
                            // TODO: Implementar share
                        }
                    )
                }
        }
    }

    private var spatialSidebar: some View {
        List {
            Section("Navegación") {
                Button {
                    selectedRoute = .home
                } label: {
                    Label(String(localized: "home.title"), systemImage: "house.fill")
                }
                .tag(Route.home)

                Button {
                    selectedRoute = .courses
                } label: {
                    Label(String(localized: "courses.title"), systemImage: "book.fill")
                }
                .tag(Route.courses)

                Button {
                    selectedRoute = .calendar
                } label: {
                    Label(String(localized: "calendar.title"), systemImage: "calendar")
                }
                .tag(Route.calendar)

                Button {
                    selectedRoute = .progress
                } label: {
                    Label(String(localized: "progress.title"), systemImage: "chart.bar.fill")
                }
                .tag(Route.progress)

                Button {
                    selectedRoute = .community
                } label: {
                    Label(String(localized: "community.title"), systemImage: "person.2.fill")
                }
                .tag(Route.community)

                Button {
                    selectedRoute = .settings
                } label: {
                    Label(String(localized: "settings.title"), systemImage: "gear")
                }
                .tag(Route.settings)
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
    }
    #endif

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

#Preview("Platform Detection") {
    VStack(spacing: DSSpacing.large) {
        Text("Platform: \(String(describing: PlatformCapabilities.currentDevice))")
        Text("Navigation Style: \(String(describing: PlatformCapabilities.recommendedNavigationStyle))")
        Text("Screen Size: \(PlatformCapabilities.screenCapabilities.screenSize.debugDescription)")
    }
    .padding()
}
