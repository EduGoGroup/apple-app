//
//  LoginWithBiometricsUseCase.swift
//  apple-app
//
//  Created on 25-11-25.
//  SPEC-003: Authentication - Biometric Login
//

import Foundation

/// Caso de uso para login con autenticación biométrica (Face ID / Touch ID)
///
/// Aislado a MainActor porque depende de AuthRepository que es @MainActor
/// y es usado por ViewModels que también son @MainActor.
@MainActor
public protocol LoginWithBiometricsUseCase: Sendable {
    /// Ejecuta login usando las credenciales almacenadas y autenticación biométrica
    /// - Returns: Usuario autenticado o error
    func execute() async -> Result<User, AppError>
}

/// Implementación del caso de uso de login biométrico
@MainActor
public final class DefaultLoginWithBiometricsUseCase: LoginWithBiometricsUseCase {
    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    public func execute() async -> Result<User, AppError> {
        // Delegar al repositorio que maneja la lógica completa:
        // 1. Verificar disponibilidad de biometría
        // 2. Solicitar autenticación biométrica
        // 3. Recuperar credenciales del Keychain
        // 4. Ejecutar login con credenciales
        await authRepository.loginWithBiometrics()
    }
}

// MARK: - Testing

#if DEBUG
/// Mock para testing
@MainActor
public final class MockLoginWithBiometricsUseCase: LoginWithBiometricsUseCase {
    public var result: Result<User, AppError> = .success(.fixture())
    public var executeCallCount = 0

    public init() {}

    public func execute() async -> Result<User, AppError> {
        executeCallCount += 1
        return result
    }
}
#endif
