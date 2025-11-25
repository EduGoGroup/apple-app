//
//  View+Injection.swift
//  apple-app
//
//  Created on 23-01-25.
//

import SwiftUI

// MARK: - Environment Key

/// Environment key para acceder al DependencyContainer
/// @preconcurrency permite defer isolation checking a runtime para compatibilidad
/// con Swift 6 strict concurrency
private struct DependencyContainerKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue = DependencyContainer()
}

extension EnvironmentValues {
    /// Acceso al DependencyContainer desde el environment
    var dependencyContainer: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inyecta el DependencyContainer mediante una EnvironmentKey personalizada
    ///
    /// - Parameter container: Container a inyectar
    /// - Returns: Vista con el container en su environment
    ///
    /// Ejemplo:
    /// ```swift
    /// ContentView()
    ///     .withDependencyContainer(container)
    /// ```
    public func withDependencyContainer(_ container: DependencyContainer) -> some View {
        self.environment(\.dependencyContainer, container)
    }
}
