//
//  AuthRepositoryImpl.swift
//  apple-app
//
//  Created on 16-11-25.
//  Updated on 24-01-25 - SPEC-003: Real API Migration
//

import Foundation

/// Implementación del repositorio de autenticación
///
/// Soporta dos modos via feature flag:
/// - DummyJSON: Para desarrollo/testing
/// - Real API: Para staging/production
final class AuthRepositoryImpl: AuthRepository, @unchecked Sendable {

    // MARK: - Dependencies

    private let apiClient: APIClient
    private let keychainService: KeychainService
    private let jwtDecoder: JWTDecoder
    private let tokenCoordinator: TokenRefreshCoordinator
    private let biometricService: BiometricAuthService
    private let logger = LoggerFactory.auth

    // MARK: - Configuration

    /// Modo de autenticación (DummyJSON vs Real API)
    private let authMode: AuthenticationMode

    // Claves para almacenar datos en Keychain
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let storedEmailKey = "stored_email"
    private let storedPasswordKey = "stored_password"

    // MARK: - Initialization

    init(
        apiClient: APIClient,
        keychainService: KeychainService = DefaultKeychainService.shared,
        jwtDecoder: JWTDecoder,
        tokenCoordinator: TokenRefreshCoordinator,
        biometricService: BiometricAuthService,
        authMode: AuthenticationMode? = nil
    ) {
        self.apiClient = apiClient
        self.keychainService = keychainService
        self.jwtDecoder = jwtDecoder
        self.tokenCoordinator = tokenCoordinator
        self.biometricService = biometricService
        self.authMode = authMode ?? AppEnvironment.authMode
    }

    // MARK: - AuthRepository Implementation

    @MainActor
    func login(email: String, password: String) async -> Result<User, AppError> {
        logger.info("Login attempt started")
        logger.logEmail(email)

        do {
            let user: User
            let tokenInfo: TokenInfo

            switch authMode {
            case .dummyJSON:
                (user, tokenInfo) = try await loginWithDummyJSON(email: email, password: password)
            case .realAPI:
                (user, tokenInfo) = try await loginWithRealAPI(email: email, password: password)
            }

            // Guardar tokens en Keychain
            try keychainService.saveToken(tokenInfo.accessToken, for: accessTokenKey)
            try keychainService.saveToken(tokenInfo.refreshToken, for: refreshTokenKey)

            logger.info("Login successful", metadata: ["userId": user.id])

            // Guardar credenciales para biometric login (opcional)
            try? keychainService.saveToken(email, for: storedEmailKey)
            try? keychainService.saveToken(password, for: storedPasswordKey)

            return .success(user)

        } catch let error as NetworkError {
            logger.error("Login failed - Network error", metadata: [
                "error": error.localizedDescription
            ])
            return .failure(.network(error))
        } catch let error as KeychainError {
            logger.error("Login failed - Keychain error", metadata: [
                "error": error.localizedDescription
            ])
            return .failure(.system(.system(error.localizedDescription)))
        } catch {
            logger.error("Login failed - Unknown error", metadata: [
                "error": error.localizedDescription
            ])
            return .failure(.system(.system("Error: \(error.localizedDescription)")))
        }
    }

    @MainActor
    func loginWithBiometrics() async -> Result<User, AppError> {
        logger.info("Biometric login attempt")

        // 1. Verificar disponibilidad
        guard await biometricService.isAvailable else {
            logger.warning("Biometric auth not available")
            return .failure(.system(.system("Autenticación biométrica no disponible")))
        }

        // 2. Autenticar con Face ID / Touch ID
        do {
            let authenticated = try await biometricService.authenticate(
                reason: "Iniciar sesión en EduGo"
            )

            guard authenticated else {
                logger.warning("Biometric auth cancelled")
                return .failure(.system(.cancelled))
            }

            // 3. Leer credenciales guardadas
            guard let email = try? keychainService.getToken(for: storedEmailKey),
                  let password = try? keychainService.getToken(for: storedPasswordKey) else {
                logger.warning("No stored credentials for biometric login")
                return .failure(.system(.system("No hay credenciales guardadas")))
            }

            // 4. Login normal con credenciales
            logger.info("Biometric auth successful, performing login")
            return await login(email: email, password: password)

        } catch {
            logger.error("Biometric login failed", metadata: [
                "error": error.localizedDescription
            ])
            return .failure(.system(.system(error.localizedDescription)))
        }
    }

    @MainActor
    func logout() async -> Result<Void, AppError> {
        logger.info("Logout attempt started")

        do {
            // Llamar API de logout solo en modo Real API
            if authMode == .realAPI {
                if let refreshToken = try? keychainService.getToken(for: refreshTokenKey) {
                    // Llamar endpoint de logout
                    let _: String? = try? await apiClient.execute(
                        endpoint: .logout,
                        method: .post,
                        body: LogoutRequest(refreshToken: refreshToken)
                    )
                }
            }

            // Eliminar tokens del Keychain
            try keychainService.deleteToken(for: accessTokenKey)
            try keychainService.deleteToken(for: refreshTokenKey)

            logger.info("Logout successful")
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

    @MainActor
    func getCurrentUser() async -> Result<User, AppError> {
        do {
            // Obtener access token
            guard let accessToken = try keychainService.getToken(for: accessTokenKey) else {
                return .failure(.network(.unauthorized))
            }

            // Decodificar JWT para obtener user info
            let payload = try jwtDecoder.decode(accessToken)
            let user = payload.toDomainUser

            logger.info("Current user retrieved from JWT", metadata: ["userId": user.id])

            return .success(user)

        } catch let error as JWTError {
            // Si el JWT es inválido o expiró, intentar refresh
            logger.warning("JWT invalid or expired, attempting refresh")

            let refreshResult = await refreshSession()
            switch refreshResult {
            case .success(let user):
                return .success(user)
            case .failure(let error):
                return .failure(error)
            }

        } catch let error as KeychainError {
            return .failure(.system(.system(error.localizedDescription)))
        } catch {
            return .failure(.system(.unknown))
        }
    }

    @MainActor
    func refreshSession() async -> Result<User, AppError> {
        logger.info("Token refresh attempt started")

        do {
            // Obtener refresh token
            guard let refreshToken = try keychainService.getToken(for: refreshTokenKey) else {
                logger.warning("Token refresh failed - No refresh token")
                return .failure(.network(.unauthorized))
            }

            let response: RefreshResponse

            switch authMode {
            case .dummyJSON:
                // DummyJSON retorna user completo
                let dummyResponse: DummyJSONLoginResponse = try await apiClient.execute(
                    endpoint: .refresh,
                    method: .post,
                    body: DummyJSONRefreshRequest(
                        refreshToken: refreshToken,
                        expiresInMins: 30
                    )
                )

                // Convertir a TokenInfo
                let tokenInfo = dummyResponse.toTokenInfo()
                try keychainService.saveToken(tokenInfo.accessToken, for: accessTokenKey)
                try keychainService.saveToken(tokenInfo.refreshToken, for: refreshTokenKey)

                logger.info("Token refresh successful (DummyJSON)")
                return .success(dummyResponse.toDomain())

            case .realAPI:
                // API Real solo retorna nuevo access token
                response = try await apiClient.execute(
                    endpoint: .refresh,
                    method: .post,
                    body: RefreshRequest(refreshToken: refreshToken)
                )

                // Actualizar solo access token (refresh NO cambia)
                try keychainService.saveToken(response.accessToken, for: accessTokenKey)

                // Obtener user del nuevo JWT
                let payload = try jwtDecoder.decode(response.accessToken)
                let user = payload.toDomainUser

                logger.info("Token refresh successful (Real API)")
                return .success(user)
            }

        } catch let error as NetworkError {
            logger.error("Token refresh failed - Network error", metadata: [
                "error": error.localizedDescription
            ])

            // Limpiar tokens si refresh falla
            try? keychainService.deleteToken(for: accessTokenKey)
            try? keychainService.deleteToken(for: refreshTokenKey)

            return .failure(.network(error))
        } catch {
            logger.error("Token refresh failed", metadata: [
                "error": error.localizedDescription
            ])
            return .failure(.system(.unknown))
        }
    }

    @MainActor
    func hasActiveSession() async -> Bool {
        do {
            guard let accessToken = try keychainService.getToken(for: accessTokenKey) else {
                return false
            }

            // Verificar que el token no esté expirado
            let payload = try jwtDecoder.decode(accessToken)
            return !payload.isExpired

        } catch {
            return false
        }
    }

    @MainActor
    func getTokenInfo() async -> Result<TokenInfo, AppError> {
        do {
            guard let accessToken = try keychainService.getToken(for: accessTokenKey) else {
                return .failure(.network(.unauthorized))
            }

            guard let refreshToken = try keychainService.getToken(for: refreshTokenKey) else {
                return .failure(.network(.unauthorized))
            }

            let payload = try jwtDecoder.decode(accessToken)

            let tokenInfo = TokenInfo(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: payload.exp
            )

            return .success(tokenInfo)

        } catch {
            return .failure(.network(.unauthorized))
        }
    }

    // MARK: - Private Methods

    @MainActor
    private func loginWithDummyJSON(email: String, password: String) async throws -> (User, TokenInfo) {
        let username = email.components(separatedBy: "@").first ?? email

        let request = DummyJSONLoginRequest(
            username: username,
            password: password,
            expiresInMins: 30
        )

        let response: DummyJSONLoginResponse = try await apiClient.execute(
            endpoint: .login,
            method: .post,
            body: request
        )

        return (response.toDomain(), response.toTokenInfo())
    }

    @MainActor
    private func loginWithRealAPI(email: String, password: String) async throws -> (User, TokenInfo) {
        let request = LoginRequest(email: email, password: password)

        let response: LoginResponse = try await apiClient.execute(
            endpoint: .login,
            method: .post,
            body: request
        )

        return (response.toDomain(), response.toTokenInfo())
    }
}
