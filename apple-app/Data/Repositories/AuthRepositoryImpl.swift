//
//  AuthRepositoryImpl.swift
//  apple-app
//
//  Created on 16-11-25.
//  Updated on 24-01-25 - SPEC-003: Real API Migration
//  Updated on 24-11-25 - SPRINT2-T05: Auth centralizada con api-admin
//

import Foundation

/// Actor para manejo thread-safe de tokens
///
/// Este actor garantiza acceso thread-safe a los tokens en memoria mediante el modelo
/// de concurrencia de Swift. Los actores serializan el acceso a su estado mutable,
/// previniendo data races cuando múltiples tareas intentan leer/escribir tokens
/// concurrentemente (ej: refresh automático vs logout simultáneo).
///
/// - Note: Complementa el almacenamiento persistente en Keychain, actuando como caché rápido
private actor TokenStore {
    private var tokens: TokenInfo?

    func getTokens() -> TokenInfo? {
        tokens
    }

    func setTokens(_ newTokens: TokenInfo?) {
        tokens = newTokens
    }
}

/// Implementación del repositorio de autenticación
///
/// Usa `api-admin` como servicio central de autenticación.
/// Los tokens emitidos funcionan con todos los servicios del ecosistema EduGo.
///
/// ## Arquitectura
/// - Login/Refresh/Logout → api-admin (authAPIBaseURL)
/// - El accessToken se usa para api-mobile y api-admin
/// - Refresh automático cuando `shouldRefresh = true`
///
/// ## Thread Safety
/// Usa `TokenStore` actor para operaciones concurrentes con tokens.
final class AuthRepositoryImpl: AuthRepository, AuthTokenProvider, @unchecked Sendable {

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
    private let tokenExpirationKey = "token_expiration"
    private let storedEmailKey = "stored_email"
    private let storedPasswordKey = "stored_password"

    // MARK: - State

    /// Store thread-safe para tokens
    private let tokenStore = TokenStore()

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

        // Cargar tokens cacheados del Keychain (async, fire-and-forget en init)
        Task {
            await loadCachedTokens()
        }
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

            // Guardar tokens
            await saveTokens(tokenInfo)

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

        // Llamar API de logout solo en modo Real API
        if authMode == .realAPI {
            if let refreshToken = try? keychainService.getToken(for: refreshTokenKey) {
                // Llamar endpoint de logout (ignorar errores - best effort)
                let _: String? = try? await apiClient.execute(
                    endpoint: .logout,
                    method: .post,
                    body: LogoutRequest(refreshToken: refreshToken)
                )
            }
        }

        // Limpiar datos locales siempre
        clearLocalAuthData()

        logger.info("Logout successful")
        return .success(())
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

        } catch {
            // Si hay cualquier error (JWT inválido, keychain, etc), intentar refresh
            logger.warning("Error retrieving current user, attempting refresh", metadata: [
                "error": error.localizedDescription
            ])

            let refreshResult = await refreshSession()
            switch refreshResult {
            case .success(let user):
                return .success(user)
            case .failure(let error):
                return .failure(error)
            }
        }
    }

    // MARK: - Token Management

    @MainActor
    func refreshToken() async -> Result<AuthTokens, AppError> {
        logger.info("Token refresh attempt started")

        do {
            // Obtener refresh token actual
            guard let currentRefreshToken = try keychainService.getToken(for: refreshTokenKey) else {
                logger.warning("No refresh token available")
                return .failure(.network(.unauthorized))
            }

            let newTokens: TokenInfo

            switch authMode {
            case .dummyJSON:
                let response: DummyJSONLoginResponse = try await apiClient.execute(
                    endpoint: .refresh,
                    method: .post,
                    body: DummyJSONRefreshRequest(
                        refreshToken: currentRefreshToken,
                        expiresInMins: 30
                    )
                )
                newTokens = response.toTokenInfo()

            case .realAPI:
                let response: RefreshResponse = try await apiClient.execute(
                    endpoint: .refresh,
                    method: .post,
                    body: RefreshRequest(refreshToken: currentRefreshToken)
                )
                // En Real API, el refresh token no cambia
                newTokens = TokenInfo(
                    accessToken: response.accessToken,
                    refreshToken: currentRefreshToken,
                    expiresIn: response.expiresIn
                )
            }

            // Guardar nuevos tokens
            await saveTokens(newTokens)

            logger.info("Token refresh successful")
            return .success(newTokens)

        } catch let error as NetworkError {
            logger.error("Token refresh failed - Network error", metadata: [
                "error": error.localizedDescription
            ])

            // Si falla el refresh, limpiar sesión
            if error == .unauthorized {
                clearLocalAuthData()
            }

            return .failure(.network(error))
        } catch {
            logger.error("Token refresh failed", metadata: [
                "error": error.localizedDescription
            ])
            return .failure(.system(.unknown))
        }
    }

    func getValidAccessToken() async -> String? {
        // Obtener tokens del store
        var tokens = await tokenStore.getTokens()

        if tokens == nil {
            // Intentar cargar del Keychain
            await loadCachedTokens()
            tokens = await tokenStore.getTokens()
        }

        guard let tokens = tokens else {
            return nil
        }

        return await processTokenForAccess(tokens)
    }

    @MainActor
    private func processTokenForAccess(_ tokens: TokenInfo) async -> String? {
        // Si el token está expirado, no intentar refresh aquí
        if tokens.isExpired {
            logger.warning("Access token expired")
            return nil
        }

        // Si debe refrescarse, hacerlo
        if tokens.shouldRefresh {
            logger.info("Access token needs refresh, attempting...")
            let refreshResult = await refreshToken()

            switch refreshResult {
            case .success(let newTokens):
                return newTokens.accessToken
            case .failure:
                // Retornar el token actual aunque esté próximo a expirar
                logger.warning("Token refresh failed, returning token close to expiration", metadata: [
                    "timeRemaining": "\(Int(tokens.timeRemaining))s"
                ])
                return tokens.accessToken
            }
        }

        return tokens.accessToken
    }

    func isAuthenticated() async -> Bool {
        await getValidAccessToken() != nil
    }

    @MainActor
    func refreshSession() async -> Result<User, AppError> {
        logger.info("Session refresh attempt started")

        // Primero refrescar tokens
        let tokenResult = await refreshToken()

        switch tokenResult {
        case .success(let tokens):
            // Obtener user del nuevo JWT
            do {
                let payload = try jwtDecoder.decode(tokens.accessToken)
                let user = payload.toDomainUser
                logger.info("Session refresh successful")
                return .success(user)
            } catch {
                logger.error("Failed to decode refreshed token")
                return .failure(.system(.unknown))
            }

        case .failure(let error):
            return .failure(error)
        }
    }

    func hasActiveSession() async -> Bool {
        await isAuthenticated()
    }

    func getTokenInfo() async -> Result<TokenInfo, AppError> {
        // Intentar obtener del store
        if let tokens = await tokenStore.getTokens() {
            return .success(tokens)
        }

        // Intentar cargar del Keychain
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

            // Cachear
            await tokenStore.setTokens(tokenInfo)

            return .success(tokenInfo)

        } catch {
            return .failure(.network(.unauthorized))
        }
    }

    // MARK: - Local Data Management

    func clearLocalAuthData() {
        // Limpiar store de manera asíncrona (fire-and-forget)
        // Este patrón es intencional: no esperamos el resultado porque clearLocalAuthData
        // debe ser inmediato. El Task se ejecutará en background sin bloquear.
        Task {
            await tokenStore.setTokens(nil)
        }

        try? keychainService.deleteToken(for: accessTokenKey)
        try? keychainService.deleteToken(for: refreshTokenKey)
        try? keychainService.deleteToken(for: tokenExpirationKey)

        logger.info("Local auth data cleared")
    }

    // MARK: - Private Methods

    private func loadCachedTokens() async {
        do {
            guard let accessToken = try keychainService.getToken(for: accessTokenKey),
                  let refreshToken = try keychainService.getToken(for: refreshTokenKey) else {
                return
            }

            // Intentar obtener expiración del JWT
            if let payload = try? jwtDecoder.decode(accessToken) {
                let tokenInfo = TokenInfo(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    expiresAt: payload.exp
                )
                await tokenStore.setTokens(tokenInfo)
            }
        } catch {
            // Silenciosamente ignorar errores de carga
        }
    }

    private func saveTokens(_ tokens: TokenInfo) async {
        await tokenStore.setTokens(tokens)

        try? keychainService.saveToken(tokens.accessToken, for: accessTokenKey)
        try? keychainService.saveToken(tokens.refreshToken, for: refreshTokenKey)
    }

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
