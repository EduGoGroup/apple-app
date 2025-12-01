//
//  AuthRepository.swift
//  apple-app
//
//  Created on 16-11-25.
//  Updated on 24-11-25 - SPRINT2-T04: Protocol para auth centralizada
//

import Foundation

/// Protocolo que define las operaciones de autenticación
///
/// Este contrato será implementado por `AuthRepositoryImpl` que apunta
/// a `api-admin` como servicio central de autenticación.
///
/// ## Flujo de autenticación centralizada
/// 1. `login()` → Obtiene tokens de api-admin
/// 2. Los tokens se guardan en Keychain
/// 3. El accessToken se usa para llamadas a api-mobile y api-admin
/// 4. `refreshToken()` se llama automáticamente cuando `shouldRefresh = true`
///
/// ## Uso
/// ```swift
/// let result = await authRepository.login(email: "user@edugo.com", password: "pass")
/// switch result {
/// case .success(let user):
///     // Usuario autenticado, tokens guardados
/// case .failure(let error):
///     // Manejar error
/// }
/// ```
///
/// - Note: Este protocolo está aislado a MainActor para garantizar
///   thread-safety en operaciones con Keychain y estado de UI.
@MainActor
public protocol AuthRepository: Sendable {
    // MARK: - Authentication

    /// Autentica al usuario con email y contraseña
    ///
    /// Llama a `api-admin` `/v1/auth/login` y guarda tokens en Keychain.
    ///
    /// - Parameters:
    ///   - email: Email del usuario
    ///   - password: Contraseña del usuario
    /// - Returns: Result con el User autenticado o AppError
    func login(email: String, password: String) async -> Result<User, AppError>

    /// Cierra la sesión del usuario actual
    ///
    /// Revoca tokens en `api-admin` `/v1/auth/logout` y limpia Keychain.
    ///
    /// - Returns: Result con Void en éxito o AppError
    func logout() async -> Result<Void, AppError>

    // MARK: - Token Management

    /// Refresca el access token usando el refresh token
    ///
    /// Llama a `api-admin` `/v1/auth/refresh`. El nuevo access token
    /// funciona con todos los servicios del ecosistema.
    ///
    /// - Returns: Result con nuevos AuthTokens o AppError
    func refreshToken() async -> Result<AuthTokens, AppError>

    /// Obtiene un access token válido para usar en requests
    ///
    /// Si el token está próximo a expirar (`shouldRefresh = true`),
    /// intenta refrescarlo automáticamente antes de retornarlo.
    ///
    /// - Returns: Access token válido o nil si no hay sesión/falla refresh
    func getValidAccessToken() async -> String?

    /// Verifica si hay una sesión activa con tokens válidos
    ///
    /// IMPORTANTE: Esta función puede realizar una llamada de red para refrescar
    /// tokens expirados automáticamente si es necesario.
    ///
    /// - Returns: true si hay sesión activa con tokens no expirados
    func isAuthenticated() async -> Bool

    // MARK: - User Information

    /// Obtiene el usuario actualmente autenticado
    ///
    /// Primero intenta obtener del cache/JWT local.
    /// Si no está disponible, llama a `api-admin` `/v1/auth/me`.
    ///
    /// - Returns: Result con el User actual o AppError
    func getCurrentUser() async -> Result<User, AppError>

    /// Refresca la sesión y retorna el usuario actualizado
    ///
    /// Combina `refreshToken()` con obtención de user info.
    ///
    /// - Returns: Result con el User actualizado o AppError
    func refreshSession() async -> Result<User, AppError>

    // MARK: - Token Information

    /// Obtiene la información actual de tokens
    ///
    /// Incluye access token, refresh token y metadata de expiración.
    ///
    /// - Returns: Result con TokenInfo/AuthTokens o AppError
    func getTokenInfo() async -> Result<TokenInfo, AppError>

    // MARK: - Session State

    /// Verifica si hay una sesión activa (alias para isAuthenticated)
    ///
    /// @deprecated Usar isAuthenticated() en su lugar
    /// - Returns: true si hay un usuario autenticado
    func hasActiveSession() async -> Bool

    // MARK: - Local Data Management

    /// Limpia todos los datos de autenticación locales
    ///
    /// NO revoca tokens en el servidor, solo limpia Keychain local.
    /// Usar `logout()` para cierre de sesión completo.
    func clearLocalAuthData() async

    // MARK: - Biometric Authentication

    /// Realiza login con autenticación biométrica (Face ID / Touch ID)
    ///
    /// Requiere que el usuario haya iniciado sesión previamente
    /// y tenga credenciales guardadas.
    ///
    /// - Returns: Result con el User autenticado o AppError
    func loginWithBiometrics() async -> Result<User, AppError>
}

// MARK: - Default Implementations

public extension AuthRepository {
    /// Verifica si el usuario está autenticado con un token válido
    func isAuthenticated() async -> Bool {
        await getValidAccessToken() != nil
    }

    /// Alias para isAuthenticated
    func hasActiveSession() async -> Bool {
        await isAuthenticated()
    }
}

// MARK: - Token Provider Protocol

/// Protocolo para proveer tokens a otros componentes (APIClient, etc.)
///
/// Permite desacoplar la obtención de tokens de la implementación del repositorio.
@MainActor
public protocol AuthTokenProvider: Sendable {
    /// Obtiene un access token válido para usar en requests
    func getValidAccessToken() async -> String?
}

// MARK: - AuthRepository conforms to AuthTokenProvider

public extension AuthRepository {
    // AuthRepository ya implementa getValidAccessToken(),
    // por lo que automáticamente puede ser usado como AuthTokenProvider
}
