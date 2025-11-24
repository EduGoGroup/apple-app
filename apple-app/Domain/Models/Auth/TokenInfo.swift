//
//  TokenInfo.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration
//

import Foundation

/// Información de tokens de autenticación con expiración
struct TokenInfo: Codable, Sendable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date

    // MARK: - Computed Properties

    /// Indica si el token expiró
    var isExpired: Bool {
        Date() >= expiresAt
    }

    /// Indica si el token necesita refresh (expira en < 5 minutos)
    var needsRefresh: Bool {
        let fiveMinutesFromNow = Date().addingTimeInterval(300)
        return fiveMinutesFromNow >= expiresAt
    }

    /// Tiempo restante hasta expiración
    var timeUntilExpiration: TimeInterval {
        expiresAt.timeIntervalSinceNow
    }

    /// Porcentaje de vida útil restante (0.0 = expirado, 1.0 = recién creado)
    var remainingLifePercentage: Double {
        guard !isExpired else { return 0.0 }

        // Asumimos 15 minutos de vida total (900 segundos)
        let totalLife: TimeInterval = 900
        let remaining = timeUntilExpiration

        return max(0.0, min(1.0, remaining / totalLife))
    }

    // MARK: - Initializers

    init(accessToken: String, refreshToken: String, expiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    /// Crea TokenInfo desde expiresIn (segundos)
    init(accessToken: String, refreshToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
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
            expiresAt: Date().addingTimeInterval(expiresIn)
        )
    }

    /// Token expirado para testing
    static var expired: TokenInfo {
        TokenInfo(
            accessToken: "expired_token",
            refreshToken: "expired_refresh",
            expiresAt: Date().addingTimeInterval(-3600) // Expiró hace 1 hora
        )
    }

    /// Token que necesita refresh para testing
    static var needingRefresh: TokenInfo {
        TokenInfo(
            accessToken: "soon_to_expire",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(240) // Expira en 4 minutos
        )
    }

    /// Token recién creado para testing
    static var fresh: TokenInfo {
        TokenInfo(
            accessToken: "fresh_token",
            refreshToken: "fresh_refresh",
            expiresAt: Date().addingTimeInterval(900) // Expira en 15 minutos
        )
    }
}
#endif
