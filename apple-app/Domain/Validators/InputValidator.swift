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
}

/// Implementación por defecto del validador
final class DefaultInputValidator: InputValidator {
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    func isValidName(_ name: String) -> Bool {
        return name.count >= 2 && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
