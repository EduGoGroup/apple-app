//
//  TestDependencyContainer.swift
//  apple-appTests
//
//  Created on 23-01-25.
//

import Foundation
@testable import apple_app

/// Container especializado para testing que facilita el registro de mocks
///
/// Ejemplo de uso:
/// ```swift
/// final class LoginViewModelTests: XCTestCase {
///     var container: TestDependencyContainer!
///
///     override func setUp() {
///         container = TestDependencyContainer()
///
///         // Registrar mocks
///         let mockAuthRepo = MockAuthRepository()
///         container.registerMock(AuthRepository.self, mock: mockAuthRepo)
///     }
/// }
/// ```
final class TestDependencyContainer: DependencyContainer {

    /// Registra un mock con scope factory por defecto
    ///
    /// - Parameters:
    ///   - type: Tipo del protocolo a mockear
    ///   - mock: Instancia del mock
    ///
    /// - Note: Siempre usa scope `.factory` para facilitar reset entre tests
    func registerMock<T>(_ type: T.Type, mock: T) {
        register(type, scope: .factory) { mock }
    }

    /// Verifica que todas las dependencias necesarias estén registradas
    ///
    /// - Parameter types: Tipos a verificar
    /// - Returns: Array de tipos faltantes (vacío si todos están registrados)
    func verifyRegistrations(_ types: [Any.Type]) -> [String] {
        var missing: [String] = []

        for type in types {
            let key = String(describing: type)
            if !isRegistered(type) {
                missing.append(key)
            }
        }

        return missing
    }
}
