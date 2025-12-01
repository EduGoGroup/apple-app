//
//  JWTDecoder.swift
//  EduGoSecurityKit
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration - JWT Decoder
//  Migrated to EduGoSecurityKit on Sprint 3
//

import Foundation
import EduGoDomainCore
import EduGoObservability

// MARK: - Protocol

/// Servicio para decodificar y validar JWT tokens
public protocol JWTDecoder: Sendable {
    /// Decodifica un JWT token y retorna sus claims
    /// - Parameter token: JWT token en formato string
    /// - Returns: Payload decodificado con claims
    /// - Throws: JWTError si el token es inválido
    func decode(_ token: String) async throws -> JWTPayload
}

// MARK: - Payload

/// Representa los claims de un JWT token
public struct JWTPayload: Sendable, Equatable {
    public let sub: String       // Subject (User ID)
    public let email: String     // Email del usuario
    public let role: String      // Rol del usuario
    public let exp: Date         // Expiration time
    public let iat: Date         // Issued at
    public let iss: String       // Issuer

    public init(
        sub: String,
        email: String,
        role: String,
        exp: Date,
        iat: Date,
        iss: String
    ) {
        self.sub = sub
        self.email = email
        self.role = role
        self.exp = exp
        self.iat = iat
        self.iss = iss
    }

    /// Indica si el token expiró
    public var isExpired: Bool {
        Date() >= exp
    }

    /// Convierte el payload a User de dominio
    public var toDomainUser: User {
        User(
            id: sub,
            email: email,
            displayName: email.components(separatedBy: "@").first ?? "User",
            role: UserRole(rawValue: role) ?? .student,
            isEmailVerified: true
        )
    }
}

// MARK: - Errors

/// Errores de decodificación de JWT
public enum JWTError: Error, LocalizedError, Sendable {
    case invalidFormat
    case invalidBase64
    case missingClaims
    case invalidIssuer
    case expired

    public var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "JWT format inválido (debe tener 3 segmentos: header.payload.signature)"
        case .invalidBase64:
            return "Base64 inválido en payload del JWT"
        case .missingClaims:
            return "Claims requeridos faltantes en el JWT"
        case .invalidIssuer:
            return "Issuer del JWT no es válido (esperado: edugo-central o edugo-mobile)"
        case .expired:
            return "JWT token expirado"
        }
    }
}

// MARK: - Implementation

/// Implementación por defecto del decodificador JWT
public final class DefaultJWTDecoder: JWTDecoder, Sendable {
    private let logger = LoggerFactory.auth
    /// Issuers válidos: edugo-central (api-admin) y edugo-mobile (legacy)
    private let validIssuers = ["edugo-central", "edugo-mobile"]

    public init() {}

    public func decode(_ token: String) async throws -> JWTPayload {
        await logger.debug("Decoding JWT token")

        // 1. Separar en segmentos (header.payload.signature)
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3 else {
            await logger.error("JWT format invalid", metadata: [
                "segments": segments.count.description
            ])
            throw JWTError.invalidFormat
        }

        // 2. Decodificar payload (segmento 1)
        let payloadSegment = segments[1]
        guard let payloadData = base64URLDecode(payloadSegment) else {
            await logger.error("Failed to decode base64URL payload")
            throw JWTError.invalidBase64
        }

        // 3. Parsear JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        let dto = try decoder.decode(JWTPayloadDTO.self, from: payloadData)

        // 4. Validar issuer (acepta edugo-central o edugo-mobile)
        guard let issuer = dto.iss, validIssuers.contains(issuer) else {
            await logger.error("Invalid issuer", metadata: [
                "expected": validIssuers.joined(separator: " o "),
                "actual": dto.iss ?? "nil"
            ])
            throw JWTError.invalidIssuer
        }

        // 5. Construir payload
        let payload = JWTPayload(
            sub: dto.sub,
            email: dto.email,
            role: dto.role,
            exp: Date(timeIntervalSince1970: dto.exp),
            iat: Date(timeIntervalSince1970: dto.iat),
            iss: dto.iss ?? ""
        )

        await logger.debug("JWT decoded successfully", metadata: [
            "userId": payload.sub,
            "role": payload.role
        ])

        return payload
    }

    // MARK: - Base64URL Decoding

    /// Decodifica una string en formato Base64URL
    ///
    /// Base64URL es similar a Base64 pero usa caracteres URL-safe:
    /// - Reemplaza '+' con '-'
    /// - Reemplaza '/' con '_'
    /// - Omite padding '='
    private func base64URLDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Agregar padding si falta
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        return Data(base64Encoded: base64)
    }
}

// MARK: - DTO Internal

/// DTO interno para decodificar el payload del JWT
private struct JWTPayloadDTO: Codable, Sendable {
    let sub: String
    let email: String
    let role: String
    let exp: TimeInterval
    let iat: TimeInterval
    let iss: String?
}

// MARK: - Testing

#if DEBUG
extension JWTPayload {
    /// Payload fixture para testing
    public static func fixture() -> JWTPayload {
        JWTPayload(
            sub: "550e8400-e29b-41d4-a716-446655440000",
            email: "test@edugo.com",
            role: "student",
            exp: Date().addingTimeInterval(900), // Expira en 15 min
            iat: Date(),
            iss: "edugo-mobile"
        )
    }

    /// Payload expirado para testing
    public static var expired: JWTPayload {
        JWTPayload(
            sub: "550e8400-e29b-41d4-a716-446655440000",
            email: "test@edugo.com",
            role: "student",
            exp: Date().addingTimeInterval(-3600), // Expiró hace 1 hora
            iat: Date().addingTimeInterval(-4500),
            iss: "edugo-mobile"
        )
    }
}

/// Mock JWT Decoder para testing
///
/// ## Swift 6 Concurrency
/// FASE 2 - Refactoring: Eliminado NSLock, marcado como @MainActor.
/// Cumple con Regla 2.3 adaptada: Mocks @MainActor cuando protocolo es sincrónico.
@MainActor
public final class MockJWTDecoder: JWTDecoder {
    public var payloadToReturn: JWTPayload?
    public var errorToThrow: Error?

    public init() {}

    nonisolated public func decode(_ token: String) async throws -> JWTPayload {
        try await MainActor.run {
            if let error = errorToThrow {
                throw error
            }
            return payloadToReturn ?? .fixture()
        }
    }

    public func reset() {
        payloadToReturn = nil
        errorToThrow = nil
    }
}
#endif
