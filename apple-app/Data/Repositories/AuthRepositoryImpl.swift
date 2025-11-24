//
//  AuthRepositoryImpl.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Implementación del repositorio de autenticación usando DummyJSON API
final class AuthRepositoryImpl: AuthRepository, @unchecked Sendable {
    private let apiClient: APIClient
    private let keychainService: KeychainService
    private let logger = LoggerFactory.auth

    // Claves para almacenar tokens en Keychain
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"

    init(
        apiClient: APIClient,
        keychainService: KeychainService = DefaultKeychainService.shared
    ) {
        self.apiClient = apiClient
        self.keychainService = keychainService
    }

    // MARK: - AuthRepository Implementation

    func login(email: String, password: String) async -> Result<User, AppError> {
        logger.info("Login attempt started")
        logger.logEmail(email)

        do {
            // DummyJSON usa username en lugar de email
            // Para este ejemplo, usamos el email como username
            let username = email.components(separatedBy: "@").first ?? email

            let request = LoginRequest(
                username: username,
                password: password,
                expiresInMins: AppConfig.tokenExpirationMinutes
            )

            let response: LoginResponse = try await apiClient.execute(
                endpoint: .login,
                method: .post,
                body: request
            )

            logger.debug("Login API response received", metadata: [
                "userId": response.id.description,
                "username": response.username
            ])

            // Guardar tokens en Keychain
            try keychainService.saveToken(response.accessToken, for: accessTokenKey)
            logger.logToken(response.accessToken, label: "AccessToken")

            try keychainService.saveToken(response.refreshToken, for: refreshTokenKey)
            logger.debug("Tokens saved to Keychain")

            logger.info("Login successful")
            return .success(response.toDomain())

        } catch let error as NetworkError {
            logger.error("Login failed - Network error", metadata: [
                "error": error.localizedDescription,
                "errorType": String(describing: type(of: error))
            ])
            return .failure(.network(error))
        } catch let error as KeychainError {
            logger.error("Login failed - Keychain error", metadata: [
                "error": error.localizedDescription
            ])
            return .failure(.system(.system(error.localizedDescription)))
        } catch {
            logger.error("Login failed - Unknown error", metadata: [
                "error": error.localizedDescription,
                "errorType": String(describing: type(of: error))
            ])
            return .failure(.system(.system("Error: \(error.localizedDescription)")))
        }
    }

    func logout() async -> Result<Void, AppError> {
        logger.info("Logout attempt started")

        do {
            // Eliminar tokens del Keychain
            try keychainService.deleteToken(for: accessTokenKey)
            try keychainService.deleteToken(for: refreshTokenKey)

            logger.info("Logout successful - Tokens deleted from Keychain")
            return .success(())

        } catch let error as KeychainError {
            logger.error("Logout failed - Keychain error", metadata: [
                "error": error.localizedDescription
            ])
            return .failure(.system(.system(error.localizedDescription)))
        } catch {
            logger.error("Logout failed - Unknown error", metadata: [
                "error": error.localizedDescription
            ])
            return .failure(.system(.unknown))
        }
    }

    func getCurrentUser() async -> Result<User, AppError> {
        do {
            // Verificar que existe token de acceso
            guard let _ = try keychainService.getToken(for: accessTokenKey) else {
                return .failure(.network(.unauthorized))
            }

            let userDTO: UserDTO = try await apiClient.execute(
                endpoint: .currentUser,
                method: .get,
                body: nil as String?
            )

            return .success(userDTO.toDomain())

        } catch let error as NetworkError {
            // Si el token expiró, intentar refresh
            if case .unauthorized = error {
                let refreshResult = await refreshSession()
                switch refreshResult {
                case .success:
                    // Reintentar después del refresh
                    return await getCurrentUser()
                case .failure(let refreshError):
                    return .failure(refreshError)
                }
            }
            return .failure(.network(error))

        } catch let error as KeychainError {
            return .failure(.system(.system(error.localizedDescription)))
        } catch {
            return .failure(.system(.unknown))
        }
    }

    func refreshSession() async -> Result<User, AppError> {
        logger.info("Token refresh attempt started")

        do {
            // Obtener refresh token del Keychain
            guard let refreshToken = try keychainService.getToken(for: refreshTokenKey) else {
                logger.warning("Token refresh failed - No refresh token in Keychain")
                return .failure(.network(.unauthorized))
            }

            logger.logToken(refreshToken, label: "RefreshToken")

            let request = RefreshRequest(
                refreshToken: refreshToken,
                expiresInMins: AppConfig.tokenExpirationMinutes
            )

            let response: LoginResponse = try await apiClient.execute(
                endpoint: .refresh,
                method: .post,
                body: request
            )

            logger.debug("Token refresh API response received", metadata: [
                "userId": response.id.description
            ])

            // Actualizar tokens en Keychain
            try keychainService.saveToken(response.accessToken, for: accessTokenKey)
            logger.logToken(response.accessToken, label: "NewAccessToken")

            try keychainService.saveToken(response.refreshToken, for: refreshTokenKey)
            logger.debug("New tokens saved to Keychain")

            logger.info("Token refresh successful")
            return .success(response.toDomain())

        } catch let error as NetworkError {
            logger.error("Token refresh failed - Network error", metadata: [
                "error": error.localizedDescription
            ])

            // Si el refresh falla, eliminar tokens
            try? keychainService.deleteToken(for: accessTokenKey)
            try? keychainService.deleteToken(for: refreshTokenKey)
            logger.warning("Tokens deleted due to refresh failure")

            return .failure(.network(error))

        } catch let error as KeychainError {
            logger.error("Token refresh failed - Keychain error", metadata: [
                "error": error.localizedDescription
            ])
            return .failure(.system(.system(error.localizedDescription)))
        } catch {
            logger.error("Token refresh failed - Unknown error", metadata: [
                "error": error.localizedDescription
            ])
            return .failure(.system(.unknown))
        }
    }

    func hasActiveSession() async -> Bool {
        do {
            // Verificar que existe token de acceso
            return try keychainService.getToken(for: accessTokenKey) != nil
        } catch {
            return false
        }
    }
}
