//
//  LoggerExtensions.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Core/Logging/
//  SPEC-002: Professional Logging System
//

import Foundation

// MARK: - Privacy Helpers

public extension Logger {
    /// Log un token JWT con redacción automática
    ///
    /// Redacta el token mostrando solo los primeros y últimos 4 caracteres
    /// para permitir identificación sin exponer el token completo.
    ///
    /// ## Ejemplo
    /// ```swift
    /// logger.logToken("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
    /// // Log: "Token: eyJh...VCJ9"
    /// ```
    ///
    /// - Parameters:
    ///   - token: Token a loggear (será redactado)
    ///   - label: Etiqueta descriptiva (default: "Token")
    func logToken(_ token: String, label: String = "Token") async {
        let redacted = redactToken(token)
        await debug("\(label): \(redacted)")
    }

    /// Log un email con redacción parcial
    ///
    /// Redacta el username mostrando solo los primeros 2 caracteres,
    /// manteniendo el dominio visible.
    ///
    /// ## Ejemplo
    /// ```swift
    /// logger.logEmail("user@example.com")
    /// // Log: "Email: us***@example.com"
    /// ```
    ///
    /// - Parameters:
    ///   - email: Email a loggear (será redactado)
    ///   - label: Etiqueta descriptiva (default: "Email")
    func logEmail(_ email: String, label: String = "Email") async {
        let redacted = redactEmail(email)
        await debug("\(label): \(redacted)")
    }

    /// Log un User ID con redacción parcial
    ///
    /// Redacta el ID mostrando solo los primeros y últimos 4 caracteres.
    ///
    /// ## Ejemplo
    /// ```swift
    /// logger.logUserId("550e8400-e29b-41d4-a716-446655440000")
    /// // Log: "UserID: 550e***0000"
    /// ```
    ///
    /// - Parameters:
    ///   - userId: User ID a loggear (será redactado)
    ///   - label: Etiqueta descriptiva (default: "UserID")
    func logUserId(_ userId: String, label: String = "UserID") async {
        let redacted = redactId(userId)
        await debug("\(label): \(redacted)")
    }

    // MARK: - Private Redaction Functions

    /// Redacta un token mostrando primeros y últimos 4 caracteres
    private func redactToken(_ token: String) -> String {
        guard token.count > 8 else { return "***" }
        return "\(token.prefix(4))...\(token.suffix(4))"
    }

    /// Redacta un email ocultando la mayor parte del username
    private func redactEmail(_ email: String) -> String {
        let parts = email.split(separator: "@")
        guard parts.count == 2 else { return "***" }

        let username = String(parts[0])
        let domain = String(parts[1])
        let redactedUsername = username.count > 2 ? "\(username.prefix(2))***" : "***"

        return "\(redactedUsername)@\(domain)"
    }

    /// Redacta un ID mostrando primeros y últimos 4 caracteres
    private func redactId(_ id: String) -> String {
        guard id.count > 8 else { return "***" }
        return "\(id.prefix(4))***\(id.suffix(4))"
    }
}

// MARK: - Password Protection

public extension Logger {
    /// ⚠️ NUNCA loggear passwords
    ///
    /// Este método existe solo para documentar y prevenir logging de passwords.
    /// Intentar usarlo generará un error de compilación.
    ///
    /// ## Razón
    /// Passwords NUNCA deben loggearse, ni siquiera redactados, por razones de seguridad.
    ///
    /// - Parameter password: Password (NUNCA usar este método)
    @available(*, unavailable, message: "❌ Never log passwords, even redacted. This is a security violation.")
    func logPassword(_ password: String) {
        fatalError("Passwords must never be logged")
    }
}

// MARK: - HTTP Helpers

public extension Logger {
    /// Log un HTTP request con información estructurada
    /// - Parameters:
    ///   - method: HTTP method (GET, POST, etc.)
    ///   - url: URL del request
    ///   - headers: Headers HTTP (tokens serán redactados)
    func logHTTPRequest(method: String, url: String, headers: [String: String]? = nil) async {
        var metadata: [String: String] = [
            "method": method,
            "url": url
        ]

        // Redactar headers sensibles
        if let headers = headers {
            let redactedHeaders = headers.mapValues { value in
                if value.starts(with: "Bearer ") {
                    let token = String(value.dropFirst(7))
                    return "Bearer \(redactToken(token))"
                }
                return value
            }
            metadata["headers"] = redactedHeaders.description
        }

        await info("HTTP Request", metadata: metadata)
    }

    /// Log un HTTP response con información estructurada
    /// - Parameters:
    ///   - statusCode: Status code HTTP
    ///   - url: URL del request
    ///   - size: Tamaño de la respuesta en bytes (opcional)
    func logHTTPResponse(statusCode: Int, url: String, size: Int? = nil) async {
        var metadata: [String: String] = [
            "statusCode": "\(statusCode)",
            "url": url
        ]

        if let size = size {
            metadata["size"] = "\(size) bytes"
        }

        if statusCode >= 400 {
            await error("HTTP Response", metadata: metadata)
        } else {
            await info("HTTP Response", metadata: metadata)
        }
    }
}
