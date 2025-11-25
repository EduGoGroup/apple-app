//
//  apple_appApp.swift
//  apple-app
//
//  Created by Jhoan Medina on 15-11-25.
//  Updated on 25-11-25 - SPEC-003: AuthInterceptor integration
//

import SwiftUI

@main
struct apple_appApp: App {
    // MARK: - Dependency Container

    @StateObject private var container: DependencyContainer

    // MARK: - Initialization

    init() {
        // Crear container
        let container = DependencyContainer()
        _container = StateObject(wrappedValue: container)

        // Configurar dependencias
        Self.setupDependencies(in: container)
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            AdaptiveNavigationView()
                .environmentObject(container)
        }
        .commands {
            appCommands
        }
        #if os(macOS)
        .defaultSize(width: 1000, height: 700)
        #endif
    }

    // MARK: - Commands (Menu Bar)

    @CommandsBuilder
    private var appCommands: some Commands {
        // Comandos personalizados
        CommandMenu("Navegación") {
            Button("Inicio") {
                // TODO: Implementar navegación desde menú
            }
            .keyboardShortcut("h", modifiers: [.command])

            Button("Configuración") {
                // TODO: Implementar navegación desde menú
            }
            .keyboardShortcut(",", modifiers: [.command])

            Divider()

            Button("Cerrar Sesión") {
                // TODO: Implementar logout desde menú
            }
            .keyboardShortcut("q", modifiers: [.command, .shift])
        }
    }

    // MARK: - Dependency Setup

    /// Configura todas las dependencias de la aplicación
    /// - Parameter container: Container donde registrar las dependencias
    private static func setupDependencies(in container: DependencyContainer) {
        // Servicios base (Keychain, NetworkMonitor)
        registerBaseServices(in: container)

        // Auth services (JWT, Biometric, TokenCoordinator) - necesarios para APIClient
        registerAuthServices(in: container)

        // APIClient con todos los interceptores
        registerAPIClient(in: container)

        // Validadores
        registerValidators(in: container)

        // Repositorios
        registerRepositories(in: container)

        // Casos de uso
        registerUseCases(in: container)
    }

    // MARK: - Base Services Registration

    /// Registra servicios base (Keychain, NetworkMonitor)
    private static func registerBaseServices(in container: DependencyContainer) {
        // KeychainService - Singleton
        // Única instancia para todo el acceso al Keychain
        container.register(KeychainService.self, scope: .singleton) {
            DefaultKeychainService.shared
        }

        // NetworkMonitor - Singleton (SPEC-004)
        container.register(NetworkMonitor.self, scope: .singleton) {
            DefaultNetworkMonitor()
        }
    }

    // MARK: - Auth Services Registration

    /// Registra servicios de autenticación (JWT, Biometric, TokenCoordinator)
    /// Deben estar registrados ANTES de APIClient para evitar dependencia circular
    private static func registerAuthServices(in container: DependencyContainer) {
        // JWTDecoder - Singleton (SPEC-003)
        container.register(JWTDecoder.self, scope: .singleton) {
            DefaultJWTDecoder()
        }

        // BiometricAuthService - Singleton (SPEC-003)
        container.register(BiometricAuthService.self, scope: .singleton) {
            LocalAuthenticationService()
        }

        // TokenRefreshCoordinator - Singleton (SPEC-003)
        // IMPORTANTE: Se crea con un APIClient básico sin AuthInterceptor
        // para evitar dependencia circular (TokenCoordinator -> APIClient -> AuthInterceptor -> TokenCoordinator)
        container.register(TokenRefreshCoordinator.self, scope: .singleton) {
            // APIClient básico solo para refresh (sin AuthInterceptor)
            let refreshAPIClient = DefaultAPIClient(
                baseURL: AppEnvironment.authAPIBaseURL,
                requestInterceptors: [LoggingInterceptor()],
                responseInterceptors: [LoggingInterceptor()],
                retryPolicy: .default,
                networkMonitor: container.resolve(NetworkMonitor.self)
            )

            return TokenRefreshCoordinator(
                apiClient: refreshAPIClient,
                keychainService: container.resolve(KeychainService.self),
                jwtDecoder: container.resolve(JWTDecoder.self)
            )
        }
    }

    // MARK: - API Client Registration

    /// Registra APIClient con todos los interceptores (Auth + Logging)
    private static func registerAPIClient(in container: DependencyContainer) {
        // APIClient - Singleton
        // Configurado con interceptores completos: Auth + Logging (SPEC-003 + SPEC-004)
        container.register(APIClient.self, scope: .singleton) {
            // Logging interceptor (request + response)
            let loggingInterceptor = LoggingInterceptor()

            // Auth interceptor (auto-refresh de tokens) - SPEC-003
            let authInterceptor = AuthInterceptor(
                tokenCoordinator: container.resolve(TokenRefreshCoordinator.self)
            )

            return DefaultAPIClient(
                baseURL: AppEnvironment.mobileAPIBaseURL, // API móvil por defecto
                requestInterceptors: [authInterceptor, loggingInterceptor],
                responseInterceptors: [loggingInterceptor],
                retryPolicy: .default,
                networkMonitor: container.resolve(NetworkMonitor.self)
            )
        }
    }

    // MARK: - Validators Registration

    /// Registra los validadores de la aplicación
    private static func registerValidators(in container: DependencyContainer) {
        // InputValidator - Singleton
        // Sin estado, puede compartirse
        container.register(InputValidator.self, scope: .singleton) {
            DefaultInputValidator()
        }
    }

    // MARK: - Repositories Registration

    /// Registra los repositorios de la aplicación
    private static func registerRepositories(in container: DependencyContainer) {
        // AuthRepository - Singleton
        // Cachea estado de sesión y token
        container.register(AuthRepository.self, scope: .singleton) {
            AuthRepositoryImpl(
                apiClient: container.resolve(APIClient.self),
                keychainService: container.resolve(KeychainService.self),
                jwtDecoder: container.resolve(JWTDecoder.self),
                tokenCoordinator: container.resolve(TokenRefreshCoordinator.self),
                biometricService: container.resolve(BiometricAuthService.self)
            )
        }

        // PreferencesRepository - Singleton
        // Cachea preferencias del usuario
        container.register(PreferencesRepository.self, scope: .singleton) {
            PreferencesRepositoryImpl()
        }
    }

    // MARK: - Use Cases Registration

    /// Registra los casos de uso de la aplicación
    private static func registerUseCases(in container: DependencyContainer) {
        // LoginUseCase - Factory
        // Cada login es una operación independiente
        container.register(LoginUseCase.self, scope: .factory) {
            DefaultLoginUseCase(
                authRepository: container.resolve(AuthRepository.self),
                validator: container.resolve(InputValidator.self)
            )
        }

        // LoginWithBiometricsUseCase - Factory (SPEC-003)
        // Cada login biométrico es una operación independiente
        container.register(LoginWithBiometricsUseCase.self, scope: .factory) {
            DefaultLoginWithBiometricsUseCase(
                authRepository: container.resolve(AuthRepository.self)
            )
        }

        // LogoutUseCase - Factory
        // Cada logout es una operación independiente
        container.register(LogoutUseCase.self, scope: .factory) {
            DefaultLogoutUseCase(
                authRepository: container.resolve(AuthRepository.self)
            )
        }

        // GetCurrentUserUseCase - Factory
        // Cada consulta es independiente
        container.register(GetCurrentUserUseCase.self, scope: .factory) {
            DefaultGetCurrentUserUseCase(
                authRepository: container.resolve(AuthRepository.self)
            )
        }

        // UpdateThemeUseCase - Factory
        // Cada actualización es independiente
        container.register(UpdateThemeUseCase.self, scope: .factory) {
            DefaultUpdateThemeUseCase(
                preferencesRepository: container.resolve(PreferencesRepository.self)
            )
        }
    }
}
