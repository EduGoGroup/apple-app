//
//  InputValidator.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Validador de entradas del usuario
protocol InputValidator: Sendable {
    /// Valida si un email tiene formato correcto
    func isValidEmail(_ email: String) -> Bool

    /// Valida si una contraseña cumple los requisitos mínimos
    func isValidPassword(_ password: String) -> Bool

    /// Valida si un nombre es válido
    func isValidName(_ name: String) -> Bool

    // SPEC-008: Security validations

    /// Sanitiza input removiendo caracteres peligrosos
    func sanitize(_ input: String) -> String

    /// Valida que no contenga SQL injection patterns
    func isSafeSQLInput(_ input: String) -> Bool

    /// Valida que no contenga XSS patterns
    func isSafeHTMLInput(_ input: String) -> Bool

    /// Valida path (no path traversal)
    func isSafePath(_ path: String) -> Bool
}

/// Implementación por defecto del validador
final class DefaultInputValidator: InputValidator {
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    func isValidPassword(_ password: String) -> Bool {
        password.count >= 6
    }

    func isValidName(_ name: String) -> Bool {
        name.count >= 2 && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - SPEC-008: Security Validations

    func sanitize(_ input: String) -> String {
        // Remover caracteres peligrosos
        let dangerous = CharacterSet(charactersIn: "<>\"'&;")
        return input.components(separatedBy: dangerous).joined()
    }

    func isSafeSQLInput(_ input: String) -> Bool {
        let sqlPatterns = [
            "(?i)\\b(select|insert|update|delete|drop|create|alter|exec|execute|union)\\b",
            "--",
            "/\\*",
            "\\*/",
            "';",
            "\";"
        ]

        for pattern in sqlPatterns where input.range(of: pattern, options: .regularExpression) != nil {
            return false
        }

        return true
    }

    func isSafeHTMLInput(_ input: String) -> Bool {
        let xssPatterns = [
            "<script",
            "javascript:",
            "onerror=",
            "onload=",
            "<iframe",
            "<object",
            "<embed"
        ]

        let lowercased = input.lowercased()

        for pattern in xssPatterns where lowercased.contains(pattern) {
            return false
        }

        return true
    }

    func isSafePath(_ path: String) -> Bool {
        // Prevenir path traversal
        let dangerousPatterns = [
            "../",
            "..\\",
            "%2e%2e/",
            "%2e%2e\\",
            "....//",
            "....//"
        ]

        let lowercased = path.lowercased()

        for pattern in dangerousPatterns where lowercased.contains(pattern) {
            return false
        }

        return true
    }
}
