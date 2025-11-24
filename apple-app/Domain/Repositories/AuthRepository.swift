//
//  AuthRepository.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Protocolo que define las operaciones de autenticación
/// Este contrato será implementado por la capa de Data
protocol AuthRepository: Sendable {
    /// Realiza el login con email y contraseña
    /// - Parameters:
    ///   - email: Email del usuario
    ///   - password: Contraseña del usuario
    /// - Returns: Result con el User autenticado o AppError
    func login(email: String, password: String) async -> Result<User, AppError>

    /// Cierra la sesión del usuario actual
    /// - Returns: Result con Void en éxito o AppError
    func logout() async -> Result<Void, AppError>

    /// Obtiene el usuario actualmente autenticado
    /// - Returns: Result con el User actual o AppError
    func getCurrentUser() async -> Result<User, AppError>

    /// Refresca la sesión usando el refresh token
    /// - Returns: Result con el User actualizado o AppError
    func refreshSession() async -> Result<User, AppError>

    /// Verifica si hay una sesión activa
    /// - Returns: true si hay un usuario autenticado
    func hasActiveSession() async -> Bool

    /// Realiza login con autenticación biométrica (Face ID / Touch ID)
    /// - Returns: Result con el User autenticado o AppError
    func loginWithBiometrics() async -> Result<User, AppError>

    /// Obtiene la información actual de tokens
    /// - Returns: Result con TokenInfo o AppError
    func getTokenInfo() async -> Result<TokenInfo, AppError>
}
