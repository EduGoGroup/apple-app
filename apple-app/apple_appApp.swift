//
//  apple_appApp.swift
//  apple-app
//
//  Created by Jhoan Medina on 15-11-25.
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
        // Servicios base
        registerServices(in: container)

        // Validadores
        registerValidators(in: container)

        // Repositorios
        registerRepositories(in: container)

        // Casos de uso
        registerUseCases(in: container)
    }

    // MARK: - Services Registration

    /// Registra los servicios base de la aplicación
    private static func registerServices(in container: DependencyContainer) {
        // KeychainService - Singleton
        // Única instancia para todo el acceso al Keychain
        container.register(KeychainService.self, scope: .singleton) {
            DefaultKeychainService.shared
        }

        // NetworkMonitor - Singleton (SPEC-004)
        container.register(NetworkMonitor.self, scope: .singleton) {
            DefaultNetworkMonitor()
        }

        // APIClient - Singleton
        // Comparte URLSession y configuración
        container.register(APIClient.self, scope: .singleton) {
            // SPEC-004: Crear interceptores
            let authInterceptor = AuthInterceptor(
                tokenCoordinator: container.resolve(TokenRefreshCoordinator.self)
            )
            let loggingInterceptor = LoggingInterceptor()

            return DefaultAPIClient(
                baseURL: AppEnvironment.apiBaseURL,
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
        // JWTDecoder - Singleton (SPEC-003)
        container.register(JWTDecoder.self, scope: .singleton) {
            DefaultJWTDecoder()
        }

        // BiometricAuthService - Singleton (SPEC-003)
        container.register(BiometricAuthService.self, scope: .singleton) {
            LocalAuthenticationService()
        }

        // TokenRefreshCoordinator - Singleton (SPEC-003)
        container.register(TokenRefreshCoordinator.self, scope: .singleton) {
            TokenRefreshCoordinator(
                apiClient: container.resolve(APIClient.self),
                keychainService: container.resolve(KeychainService.self),
                jwtDecoder: container.resolve(JWTDecoder.self)
            )
        }

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
