//
//  SecurityGuardInterceptor.swift
//  apple-app
//
//  Created on 25-11-25.
//  SPEC-008: Security Hardening - Security Guard Interceptor
//

import Foundation

/// Interceptor que valida la seguridad del dispositivo antes de cada request
///
/// Este interceptor protege contra:
/// - Dispositivos con jailbreak
/// - Debuggers adjuntos
/// - Dispositivos alterados/tampered
///
/// Si se detecta algún problema de seguridad, el request es rechazado antes
/// de enviarse, previniendo que datos sensibles salgan del dispositivo comprometido.
///
/// ## Swift 6 Concurrency
/// FASE 3 - Refactoring: Eliminado @unchecked Sendable, marcado como @MainActor.
/// Debe ser @MainActor porque:
/// 1. SecurityValidator es @MainActor (dependencia)
/// 2. Los interceptores se ejecutan en el contexto de APIClient (@MainActor)
/// 3. Simplifica el modelo de concurrencia del network layer
@MainActor
final class SecurityGuardInterceptor: RequestInterceptor {

    // MARK: - Dependencies

    private let securityValidator: SecurityValidator
    private let logger = LoggerFactory.network

    // MARK: - Configuration

    /// Indica si debe bloquear requests en dispositivos comprometidos
    /// En desarrollo, solo logea warnings. En producción, bloquea.
    private let strictMode: Bool

    // MARK: - Initialization

    init(
        securityValidator: SecurityValidator,
        strictMode: Bool = !AppEnvironment.isDevelopment
    ) {
        self.securityValidator = securityValidator
        self.strictMode = strictMode
    }

    // MARK: - RequestInterceptor

    func intercept(_ request: URLRequest) async throws -> URLRequest {
        // Validar seguridad del dispositivo
        let isTampered = await securityValidator.isTampered

        if isTampered {
            logger.warning("Security violation detected", metadata: [
                "jailbroken": "\(await securityValidator.isJailbroken)",
                "debugger": "\(securityValidator.isDebuggerAttached)",
                "strictMode": "\(strictMode)"
            ])

            if strictMode {
                // Modo estricto (producción): Bloquear request
                logger.error("Request blocked due to security violation")
                throw SecurityError.tamperedDevice
            } else {
                // Modo permisivo (desarrollo): Solo advertir
                logger.notice("⚠️ Security violation detected but allowed in development mode")
            }
        }

        // Dispositivo seguro, permitir request
        return request
    }
}

// MARK: - Testing

#if DEBUG
/// Mock interceptor para testing
actor MockSecurityGuardInterceptor: RequestInterceptor {
    var shouldBlock = false
    var interceptCallCount = 0

    func intercept(_ request: URLRequest) async throws -> URLRequest {
        interceptCallCount += 1

        if shouldBlock {
            throw SecurityError.tamperedDevice
        }

        return request
    }
}
#endif
