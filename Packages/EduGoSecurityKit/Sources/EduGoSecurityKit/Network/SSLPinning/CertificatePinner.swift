//
//  CertificatePinner.swift
//  EduGoSecurityKit
//
//  Created on 24-01-25.
//  SPEC-008: Security Hardening - Certificate Pinning
//

import Foundation
import Security
import CommonCrypto

/// Protocol para validar certificados SSL
/// Nota: nonisolated porque es llamado desde URLSessionDelegate en background
public protocol CertificatePinner: Sendable {
    /// Valida un certificado para un host específico
    nonisolated func validate(_ trust: SecTrust, for host: String) -> Bool
}

/// Implementación de Certificate Pinning usando public key pinning
/// nonisolated porque se usa desde URLSessionDelegate que no está en MainActor
public final class DefaultCertificatePinner: CertificatePinner, Sendable {
    private let pinnedPublicKeyHashes: Set<String>

    public init(pinnedPublicKeyHashes: Set<String> = []) {
        self.pinnedPublicKeyHashes = pinnedPublicKeyHashes

        #if DEBUG
        if pinnedPublicKeyHashes.isEmpty {
            print("⚠️ Certificate pinning deshabilitado (desarrollo)")
        }
        #endif
    }

    public nonisolated func validate(_ trust: SecTrust, for host: String) -> Bool {
        // Si no hay hashes configurados, permitir (desarrollo)
        guard !pinnedPublicKeyHashes.isEmpty else {
            return true
        }

        // Evaluar trust básico
        var error: CFError?
        guard SecTrustEvaluateWithError(trust, &error) else {
            return false
        }

        // Extraer public key del servidor
        guard let serverPublicKey = SecTrustCopyKey(trust),
              let serverKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) as Data? else {
            return false
        }

        // Calcular SHA256
        let serverKeyHash = sha256(data: serverKeyData)

        // Verificar contra hashes pinneados
        return pinnedPublicKeyHashes.contains(serverKeyHash)
    }

    // MARK: - SHA256

    private nonisolated func sha256(data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Testing

#if DEBUG
/// Actor mock para testing - thread-safe por diseño
public actor MockCertificatePinnerState {
    public var validateResult = true
    public var validateCallCount = 0
    public var lastHost: String?

    public init() {}

    public func setValidateResult(_ result: Bool) {
        validateResult = result
    }

    public func recordValidation(host: String) -> Bool {
        validateCallCount += 1
        lastHost = host
        return validateResult
    }

    public func getCallCount() -> Int {
        validateCallCount
    }

    public func getLastHostValue() -> String? {
        lastHost
    }
}

/// Mock para testing usando actor interno para thread safety
public final class MockCertificatePinner: CertificatePinner, Sendable {
    public let state = MockCertificatePinnerState()

    public init() {}

    public nonisolated func validate(_ trust: SecTrust, for host: String) -> Bool {
        // Para contexto nonisolated, usamos un valor fijo
        // El estado real se puede verificar async en tests
        true
    }

    /// Configurar resultado para tests (async)
    public func setValidateResult(_ result: Bool) async {
        await state.setValidateResult(result)
    }

    /// Obtener conteo de llamadas (async)
    public func getValidateCallCount() async -> Int {
        await state.getCallCount()
    }

    /// Obtener último host validado (async)
    public func getLastHost() async -> String? {
        await state.getLastHostValue()
    }
}
#endif
