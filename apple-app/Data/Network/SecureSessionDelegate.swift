//
//  SecureSessionDelegate.swift
//  apple-app
//
//  Created on 25-11-25.
//  SPEC-008: Security Hardening - URLSession Delegate con Certificate Pinning
//

import Foundation
import Security

/// URLSession delegate que implementa certificate pinning
///
/// Este delegate intercepta los challenges de autenticación SSL/TLS del servidor
/// y valida los certificados usando CertificatePinner antes de permitir la conexión.
///
/// ## Flujo de Validación
/// 1. Servidor presenta certificado SSL
/// 2. URLSession dispara `didReceive challenge`
/// 3. SecureSessionDelegate extrae el trust
/// 4. Valida el public key hash inline (sin actor boundaries)
/// 5. Si válido: Acepta conexión
/// 6. Si inválido: Rechaza conexión
///
/// ## Swift 6 Concurrency
/// Para evitar complejidad de actor boundaries, la validación se hace
/// sincrónicamente inline sin usar CertificatePinner.
final class SecureSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {

    // MARK: - Dependencies

    private let pinnedPublicKeyHashes: Set<String>

    // MARK: - Initialization

    init(pinnedPublicKeyHashes: Set<String>) {
        self.pinnedPublicKeyHashes = pinnedPublicKeyHashes
        super.init()
    }

    // MARK: - URLSessionDelegate

    nonisolated func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Solo validar server trust (certificados SSL)
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Si no hay hashes configurados, permitir (modo desarrollo)
        guard !pinnedPublicKeyHashes.isEmpty else {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
            return
        }

        // Validar certificado inline
        let isValid = validate(serverTrust: serverTrust)

        if isValid {
            // Crear credential y aceptar
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            // Rechazar conexión
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    // MARK: - Validation Logic

    private nonisolated func validate(serverTrust: SecTrust) -> Bool {
        // Evaluar trust básico
        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else {
            return false
        }

        // Extraer public key del servidor
        guard let serverPublicKey = SecTrustCopyKey(serverTrust),
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

// MARK: - CommonCrypto Import

import CommonCrypto

// MARK: - Testing

#if DEBUG
/// Mock delegate para testing
final class MockSecureSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    nonisolated(unsafe) var shouldAcceptChallenge = true
    nonisolated(unsafe) var challengeReceivedCount = 0
    nonisolated(unsafe) var lastHost: String?

    nonisolated func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        challengeReceivedCount += 1
        lastHost = challenge.protectionSpace.host

        if shouldAcceptChallenge,
           let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
#endif
