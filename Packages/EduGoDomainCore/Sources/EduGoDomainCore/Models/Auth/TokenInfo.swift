//
//  TokenInfo.swift
//  EduGoDomainCore
//
//  Created on 24-01-25.
//  Updated on 24-11-25 - SPRINT2-T03: Integración con Environment centralizado
//  Updated on 30-11-25 - Modularización: Constantes locales para Domain puro
//  SPEC-003: Authentication Real API Migration
//

import Foundation

// MARK: - Token Configuration Constants

/// Configuración de tokens para Domain (capa pura sin dependencias externas)
/// Estos valores pueden ser sobrescritos por la capa de aplicación si es necesario
public enum TokenConfiguration {
    /// Duración por defecto del access token (15 minutos)
    public static let defaultAccessTokenDuration: TimeInterval = 900

    /// Threshold para refresh automático (2 minutos antes de expirar)
    public static let defaultRefreshThreshold: TimeInterval = 120
}

/// Alias para compatibilidad con documentación de Sprint 2
/// AuthTokens y TokenInfo son intercambiables
public typealias AuthTokens = TokenInfo

/// Información de tokens de autenticación con expiración
///
/// Contiene access token y refresh token con metadata de expiración.
/// Usa `TokenConfiguration` para valores por defecto de threshold y duración.
///
/// ## Propiedades Calculadas
/// - `isExpired`: true si el token ya expiró
/// - `shouldRefresh`: true si debe refrescarse (según threshold configurado)
/// - `timeRemaining`: segundos hasta expiración
///
/// ## Uso
/// ```swift
/// let tokens = TokenInfo(accessToken: "...", refreshToken: "...", expiresIn: 900)
///
/// if tokens.shouldRefresh {
///     // Iniciar refresh automático
/// }
/// ```
public struct TokenInfo: Codable, Sendable, Equatable {
    // MARK: - Properties

    /// Token de acceso JWT
    public let accessToken: String

    /// Token de refresh para obtener nuevos access tokens
    public let refreshToken: String

    /// Fecha/hora de expiración del access token
    public let expiresAt: Date

    /// Momento en que se crearon los tokens (para cálculos de vida útil)
    public let createdAt: Date

    // MARK: - Computed Properties

    /// Indica si el token ya expiró
    public var isExpired: Bool {
        Date() >= expiresAt
    }

    /// Indica si el token necesita refresh
    ///
    /// Usa `TokenConfiguration.defaultRefreshThreshold` (default: 2 minutos antes de expirar)
    public var shouldRefresh: Bool {
        let threshold = TokenConfiguration.defaultRefreshThreshold
        return Date() >= expiresAt.addingTimeInterval(-threshold)
    }

    /// Indica si el token necesita refresh (alias para compatibilidad)
    @available(*, deprecated, message: "Usar shouldRefresh en su lugar")
    public var needsRefresh: Bool {
        shouldRefresh
    }

    /// Tiempo restante en segundos hasta expiración
    public var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSinceNow)
    }

    /// Tiempo restante hasta expiración (alias para compatibilidad)
    @available(*, deprecated, message: "Usar timeRemaining en su lugar")
    public var timeUntilExpiration: TimeInterval {
        timeRemaining
    }

    /// Segundos totales de vida del token (desde creación hasta expiración)
    public var expiresIn: Int {
        Int(expiresAt.timeIntervalSince(createdAt))
    }

    /// Porcentaje de vida útil restante (0.0 = expirado, 1.0 = recién creado)
    public var remainingLifePercentage: Double {
        guard !isExpired else { return 0.0 }

        let totalLife = TokenConfiguration.defaultAccessTokenDuration
        let remaining = timeRemaining

        return max(0.0, min(1.0, remaining / totalLife))
    }

    // MARK: - Initializers

    /// Inicializador completo
    public init(accessToken: String, refreshToken: String, expiresAt: Date, createdAt: Date = Date()) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }

    /// Crea TokenInfo desde expiresIn (segundos)
    /// - Parameters:
    ///   - accessToken: Token de acceso JWT
    ///   - refreshToken: Token de refresh
    ///   - expiresIn: Segundos hasta expiración
    public init(accessToken: String, refreshToken: String, expiresIn: Int) {
        let now = Date()
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = now.addingTimeInterval(TimeInterval(expiresIn))
        self.createdAt = now
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
    }
}

// MARK: - CustomDebugStringConvertible

extension TokenInfo: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        TokenInfo(
          accessToken: \(accessToken.prefix(20))...,
          refreshToken: \(refreshToken.prefix(10))...,
          expiresAt: \(expiresAt),
          isExpired: \(isExpired),
          shouldRefresh: \(shouldRefresh),
          timeRemaining: \(Int(timeRemaining))s
        )
        """
    }
}

// MARK: - Testing

#if DEBUG
extension TokenInfo {
    /// Token fixture para testing con valores por defecto
    static func fixture(
        accessToken: String = "mock_access_token",
        refreshToken: String = "mock_refresh_token",
        expiresIn: TimeInterval = 900
    ) -> TokenInfo {
        TokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: Int(expiresIn)
        )
    }

    /// Token expirado para testing
    static var expired: TokenInfo {
        TokenInfo(
            accessToken: "expired_token",
            refreshToken: "expired_refresh",
            expiresAt: Date().addingTimeInterval(-3600), // Expiró hace 1 hora
            createdAt: Date().addingTimeInterval(-4500)  // Creado hace 1.25 horas
        )
    }

    /// Token que necesita refresh para testing (dentro del threshold)
    static var needingRefresh: TokenInfo {
        // Usar threshold de configuración + un poco menos
        let threshold = TokenConfiguration.defaultRefreshThreshold
        return TokenInfo(
            accessToken: "soon_to_expire",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(threshold - 30), // 30 seg dentro del threshold
            createdAt: Date().addingTimeInterval(-870) // Creado hace ~14.5 minutos
        )
    }

    /// Token recién creado para testing
    static var fresh: TokenInfo {
        TokenInfo(
            accessToken: "fresh_token",
            refreshToken: "fresh_refresh",
            expiresIn: Int(TokenConfiguration.defaultAccessTokenDuration)
        )
    }

    /// Token válido pero no fresco (a mitad de vida)
    static var halfLife: TokenInfo {
        let halfDuration = TokenConfiguration.defaultAccessTokenDuration / 2
        return TokenInfo(
            accessToken: "half_life_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(halfDuration),
            createdAt: Date().addingTimeInterval(-halfDuration)
        )
    }
}
#endif
