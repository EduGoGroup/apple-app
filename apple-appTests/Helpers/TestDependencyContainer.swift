//
//  TestDependencyContainer.swift
//  apple-appTests
//
//  Created on 23-01-25.
//  Updated on 24-11-25 - Fix concurrency issues
//

import Foundation
@testable import apple_app

/// Container especializado para testing que facilita el registro de mocks
///
/// Ejemplo de uso:
/// ```swift
/// @Suite struct LoginViewModelTests {
///     var container: TestDependencyContainer!
///
///     init() {
///         container = TestDependencyContainer()
///
///         // Registrar mocks
///         let mockAuthRepo = MockAuthRepository()
///         container.registerMock(AuthRepository.self, mock: mockAuthRepo)
///     }
/// }
/// ```
///
/// ## Swift 6 Concurrency
/// FASE 3 - Refactoring: Eliminado @unchecked Sendable, marcado como @MainActor.
/// Debe ser @MainActor porque:
/// 1. Solo se usa en setup de tests (contexto main thread)
/// 2. DependencyContainer padre no es Sendable
/// 3. Los tests Swift Testing se ejecutan en main actor por defecto
@MainActor
final class TestDependencyContainer: DependencyContainer {
    /// Tipos registrados para verificación
    private var registeredTypeKeys: Set<String> = []

    /// Registra un mock con scope factory por defecto
    ///
    /// - Parameters:
    ///   - type: Tipo del protocolo a mockear
    ///   - mock: Instancia del mock
    ///
    /// - Note: Siempre usa scope `.factory` para facilitar reset entre tests
    func registerMock<T>(_ type: T.Type, mock: T) {
        let key = String(describing: type)
        registeredTypeKeys.insert(key)
        super.register(type, scope: .factory) { mock }
    }

    /// Verifica que todas las dependencias necesarias estén registradas
    ///
    /// - Parameter types: Tipos a verificar
    /// - Returns: Array de tipos faltantes (vacío si todos están registrados)
    func verifyRegistrations(_ types: [any Any.Type]) -> [String] {
        var missing: [String] = []

        for type in types {
            let key = String(describing: type)
            if !registeredTypeKeys.contains(key) && !isRegistered(type) {
                missing.append(key)
            }
        }

        return missing
    }

    /// Verifica si un tipo arbitrario está registrado
    private func isRegistered(_ type: any Any.Type) -> Bool {
        let key = String(describing: type)
        return registeredTypeKeys.contains(key)
    }
}
