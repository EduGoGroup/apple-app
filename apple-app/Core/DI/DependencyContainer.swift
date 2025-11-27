//
//  DependencyContainer.swift
//  apple-app
//
//  Created on 23-01-25.
//

import Foundation
import Combine
import SwiftUI

/// Contenedor de inyección de dependencias type-safe
///
/// Con Swift 6.2 Approachable Concurrency, usamos @MainActor para serialización
/// automática en lugar de locks manuales. Esto simplifica el código y garantiza
/// thread-safety por el modelo de actores.
///
/// Permite registrar y resolver dependencias con diferentes scopes:
/// - `.singleton`: Una única instancia compartida
/// - `.factory`: Nueva instancia cada vez
/// - `.transient`: Alias de factory
///
/// Ejemplo de uso:
/// ```swift
/// // Registrar
/// container.register(AuthRepository.self, scope: .singleton) {
///     AuthRepositoryImpl(apiClient: container.resolve(APIClient.self))
/// }
///
/// // Resolver
/// let authRepo = container.resolve(AuthRepository.self)
/// ```
@MainActor
public class DependencyContainer: ObservableObject {
    // MARK: - Storage

    /// Almacena las factories de creación para cada tipo
    private var factories: [String: Any] = [:]

    /// Almacena las instancias singleton creadas
    private var singletons: [String: Any] = [:]

    /// Almacena el scope de cada tipo registrado
    private var scopes: [String: DependencyScope] = [:]

    // MARK: - Initialization
    // Thread safety garantizada por @MainActor - no se necesitan locks

    public init() {}

    // MARK: - Registration

    /// Registra una dependencia con su factory de creación
    ///
    /// - Parameters:
    ///   - type: Tipo a registrar (ej: `AuthRepository.self`)
    ///   - scope: Ciclo de vida de la dependencia (default: `.factory`)
    ///   - factory: Closure que crea la instancia del tipo
    ///
    /// - Note: Si registras el mismo tipo dos veces, la última registración sobrescribe la anterior
    ///
    /// Ejemplo:
    /// ```swift
    /// container.register(AuthRepository.self, scope: .singleton) {
    ///     AuthRepositoryImpl(apiClient: container.resolve(APIClient.self))
    /// }
    /// ```
    public func register<T>(
        _ type: T.Type,
        scope: DependencyScope = .factory,
        factory: @escaping () -> T
    ) {
        let key = String(describing: type)

        // Thread safety garantizada por @MainActor - no se necesitan locks
        factories[key] = factory
        scopes[key] = scope

        // Si ya existía un singleton, limpiarlo (permitir re-registro)
        if singletons[key] != nil {
            singletons.removeValue(forKey: key)
        }
    }

    // MARK: - Resolution

    /// Resuelve una dependencia registrada
    ///
    /// - Parameter type: Tipo a resolver (ej: `AuthRepository.self`)
    /// - Returns: Instancia del tipo solicitado
    ///
    /// - Important: Si el tipo no está registrado, la app crasheará con `fatalError`.
    ///              Esto es intencional para detectar errores de configuración en desarrollo.
    ///
    /// Ejemplo:
    /// ```swift
    /// let authRepo = container.resolve(AuthRepository.self)
    /// ```
    public func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)

        // Thread safety garantizada por @MainActor - no se necesitan locks
        guard let factory = factories[key] as? () -> T else {
            fatalError("""
                ⚠️ DependencyContainer Error:
                No se encontró registro para '\(key)'.

                ¿Olvidaste registrarlo en setupDependencies()?

                Ejemplo:
                container.register(\(key).self, scope: .singleton) {
                    // Tu implementación aquí
                }
                """)
        }

        let scope = scopes[key] ?? .factory

        switch scope {
        case .singleton:
            // Si ya existe singleton, retornarlo
            if let singleton = singletons[key] as? T {
                return singleton
            }

            // Crear nueva instancia y guardarla
            let instance = factory()
            singletons[key] = instance
            return instance

        case .factory, .transient:
            // Siempre crear nueva instancia
            return factory()
        }
    }

    // MARK: - Utilities

    /// Elimina un registro de dependencia (útil para testing)
    /// - Parameter type: Tipo a eliminar
    public func unregister<T>(_ type: T.Type) {
        let key = String(describing: type)

        factories.removeValue(forKey: key)
        singletons.removeValue(forKey: key)
        scopes.removeValue(forKey: key)
    }

    /// Elimina todos los registros (útil para reset en tests)
    public func unregisterAll() {
        factories.removeAll()
        singletons.removeAll()
        scopes.removeAll()
    }

    /// Verifica si un tipo está registrado
    /// - Parameter type: Tipo a verificar
    /// - Returns: `true` si el tipo está registrado
    public func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = String(describing: type)
        return factories[key] != nil
    }
}
