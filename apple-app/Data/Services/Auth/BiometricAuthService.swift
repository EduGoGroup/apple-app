//
//  BiometricAuthService.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration - Biometric Authentication
//

import LocalAuthentication
import Foundation

// MARK: - Protocol

/// Servicio para autenticación biométrica (Face ID / Touch ID)
protocol BiometricAuthService: Sendable {
    /// Indica si la autenticación biométrica está disponible
    var isAvailable: Bool { get async }

    /// Tipo de biometría disponible en el dispositivo
    var biometryType: LABiometryType { get async }

    /// Autentica al usuario con biometría
    /// - Parameter reason: Razón mostrada al usuario
    /// - Returns: true si autenticación exitosa
    /// - Throws: BiometricError si falla
    func authenticate(reason: String) async throws -> Bool
}

// MARK: - Errors

/// Errores de autenticación biométrica
enum BiometricError: Error, LocalizedError {
    case notAvailable
    case authenticationFailed
    case userCancelled
    case biometryLocked
    case biometryNotEnrolled
    case passcodeNotSet

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Autenticación biométrica no disponible en este dispositivo"
        case .authenticationFailed:
            return "La autenticación biométrica falló"
        case .userCancelled:
            return "El usuario canceló la autenticación"
        case .biometryLocked:
            return "Biometría bloqueada por demasiados intentos fallidos"
        case .biometryNotEnrolled:
            return "No hay Face ID o Touch ID configurado en este dispositivo"
        case .passcodeNotSet:
            return "No hay código de acceso configurado en el dispositivo"
        }
    }
}

// MARK: - Implementation

/// Implementación usando LocalAuthentication framework de Apple
final class LocalAuthenticationService: BiometricAuthService, @unchecked Sendable {

    var isAvailable: Bool {
        get async {
            await MainActor.run {
                let context = LAContext()
                var error: NSError?
                return context.canEvaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    error: &error
                )
            }
        }
    }

    var biometryType: LABiometryType {
        get async {
            await MainActor.run {
                let context = LAContext()
                _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
                return context.biometryType
            }
        }
    }

    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancelar"
        context.localizedFallbackTitle = "Usar contraseña"

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch let error as LAError {
            throw mapLAError(error)
        }
    }

    // MARK: - Error Mapping

    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .userCancel:
            return .userCancelled
        case .biometryLockout:
            return .biometryLocked
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .biometryNotAvailable:
            return .notAvailable
        case .passcodeNotSet:
            return .passcodeNotSet
        default:
            return .authenticationFailed
        }
    }
}

// MARK: - Testing

#if DEBUG
/// Mock Biometric Service para testing
///
/// ## Swift 6 Concurrency
/// FASE 2 - Refactoring: Eliminado @unchecked Sendable, marcado como @MainActor.
/// Cumple con Regla 2.3 adaptada: Mocks @MainActor cuando protocolo tiene métodos sincrónicos.
@MainActor
final class MockBiometricService: BiometricAuthService {
    var isAvailableValue = true
    var biometryTypeValue: LABiometryType = .faceID
    var authenticateResult: Bool = true
    var authenticateError: Error?
    var authenticateCallCount = 0

    var isAvailable: Bool {
        get async { isAvailableValue }
    }

    var biometryType: LABiometryType {
        get async { biometryTypeValue }
    }

    func authenticate(reason: String) async throws -> Bool {
        authenticateCallCount += 1

        if let error = authenticateError {
            throw error
        }

        return authenticateResult
    }

    func reset() {
        isAvailableValue = true
        biometryTypeValue = .faceID
        authenticateResult = true
        authenticateError = nil
        authenticateCallCount = 0
    }
}
#endif
