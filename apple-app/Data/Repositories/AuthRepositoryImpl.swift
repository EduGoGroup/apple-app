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

            // Guardar tokens en Keychain
            try keychainService.saveToken(response.accessToken, for: accessTokenKey)
            try keychainService.saveToken(response.refreshToken, for: refreshTokenKey)

            return .success(response.toDomain())

        } catch let error as NetworkError {
            print("❌ Login NetworkError: \(error)")
            return .failure(.network(error))
        } catch let error as KeychainError {
            print("❌ Login KeychainError: \(error)")
            return .failure(.system(.system(error.localizedDescription)))
        } catch {
            print("❌ Login Unknown Error: \(error)")
            print("❌ Error Type: \(type(of: error))")
            return .failure(.system(.system("Error: \(error.localizedDescription)")))
        }
    }

    func logout() async -> Result<Void, AppError> {
        do {
            // Eliminar tokens del Keychain
            try keychainService.deleteToken(for: accessTokenKey)
            try keychainService.deleteToken(for: refreshTokenKey)

            return .success(())

        } catch let error as KeychainError {
            return .failure(.system(.system(error.localizedDescription)))
        } catch {
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
        do {
            // Obtener refresh token del Keychain
            guard let refreshToken = try keychainService.getToken(for: refreshTokenKey) else {
                return .failure(.network(.unauthorized))
            }

            let request = RefreshRequest(
                refreshToken: refreshToken,
                expiresInMins: AppConfig.tokenExpirationMinutes
            )

            let response: LoginResponse = try await apiClient.execute(
                endpoint: .refresh,
                method: .post,
                body: request
            )

            // Actualizar tokens en Keychain
            try keychainService.saveToken(response.accessToken, for: accessTokenKey)
            try keychainService.saveToken(response.refreshToken, for: refreshTokenKey)

            return .success(response.toDomain())

        } catch let error as NetworkError {
            // Si el refresh falla, eliminar tokens
            try? keychainService.deleteToken(for: accessTokenKey)
            try? keychainService.deleteToken(for: refreshTokenKey)
            return .failure(.network(error))

        } catch let error as KeychainError {
            return .failure(.system(.system(error.localizedDescription)))
        } catch {
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
