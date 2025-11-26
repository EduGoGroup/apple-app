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
///
/// # ============================================================
/// # EXCEPCIÓN DE CONCURRENCIA DOCUMENTADA
/// # ============================================================
/// Tipo: Wrapper de C/Objective-C con datos inmutables
/// Componente: URLSessionDelegate para certificate pinning
/// Justificación: Solo contiene datos inmutables (pinnedPublicKeyHashes: Set<String>).
///                Todos los métodos del delegate son nonisolated por protocolo.
///                La validación se hace de forma sincrónica sin estado mutable.
/// Referencia: https://developer.apple.com/documentation/foundation/urlsessiondelegate
/// Ticket: N/A (patrón estándar de URLSessionDelegate)
/// Fecha: 2025-11-26
/// Revisión: No requiere revisión (inmutable por diseño)
/// # ============================================================
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
///
/// ## Swift 6 Concurrency
/// FASE 1 - Refactoring: Eliminado nonisolated(unsafe), usado actor interno
/// para proteger estado mutable de forma thread-safe.
final class MockSecureSessionDelegate: NSObject, URLSessionDelegate, Sendable {

    /// Actor interno para estado mutable thread-safe
    actor State {
        var shouldAcceptChallenge = true
        var challengeReceivedCount = 0
        var lastHost: String?

        func recordChallenge(host: String) {
            challengeReceivedCount += 1
            lastHost = host
        }

        func reset() {
            shouldAcceptChallenge = true
            challengeReceivedCount = 0
            lastHost = nil
        }
    }

    let state = State()

    nonisolated func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let host = challenge.protectionSpace.host

        // Registrar el challenge de forma async (fire-and-forget para el mock)
        Task {
            await state.recordChallenge(host: host)
        }

        // Respuesta sincrónica para el mock (siempre acepta en tests)
        if let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    // MARK: - Test Helpers

    /// Obtiene el número de challenges recibidos
    func getChallengeCount() async -> Int {
        await state.challengeReceivedCount
    }

    /// Obtiene el último host que presentó un challenge
    func getLastHost() async -> String? {
        await state.lastHost
    }

    /// Resetea el estado del mock
    func resetState() async {
        await state.reset()
    }
}
#endif
