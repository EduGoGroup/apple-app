//
//  RetryPolicy.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-004: Network Layer Enhancement - Retry Policy
//

import Foundation

/// Estrategia de backoff para reintentos
enum BackoffStrategy: Sendable {
    /// Backoff exponencial: delay = base * (2 ^ attempt)
    case exponential(base: TimeInterval)

    /// Backoff lineal: delay = interval * attempt
    case linear(interval: TimeInterval)

    /// Delay fijo entre reintentos
    case fixed(interval: TimeInterval)

    /// Calcula el delay para un intento específico
    /// - Parameter attempt: Número de intento (0-indexed)
    /// - Returns: Tiempo de espera en segundos
    func delay(for attempt: Int) -> TimeInterval {
        switch self {
        case .exponential(let base):
            return base * pow(2.0, Double(attempt))
        case .linear(let interval):
            return interval * Double(attempt + 1)
        case .fixed(let interval):
            return interval
        }
    }
}

/// Política de reintentos para requests HTTP
struct RetryPolicy: Sendable {
    let maxAttempts: Int
    let backoffStrategy: BackoffStrategy
    let retryableStatusCodes: Set<Int>

    /// Política por defecto: 3 intentos con exponential backoff
    static let `default` = RetryPolicy(
        maxAttempts: 3,
        backoffStrategy: .exponential(base: 1.0),
        retryableStatusCodes: [408, 429, 500, 502, 503, 504]
    )

    /// Política agresiva: 5 intentos con backoff corto
    static let aggressive = RetryPolicy(
        maxAttempts: 5,
        backoffStrategy: .exponential(base: 0.5),
        retryableStatusCodes: [408, 429, 500, 502, 503, 504]
    )

    /// Sin reintentos
    static let none = RetryPolicy(
        maxAttempts: 1,
        backoffStrategy: .fixed(interval: 0),
        retryableStatusCodes: []
    )

    /// Verifica si un status code es retryable
    func shouldRetry(statusCode: Int, attempt: Int) -> Bool {
        guard attempt < maxAttempts else { return false }
        return retryableStatusCodes.contains(statusCode)
    }
}
