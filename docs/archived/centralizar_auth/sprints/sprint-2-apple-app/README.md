# SPRINT 2: MIGRACIÓN APPLE-APP
## Cliente iOS/macOS/iPadOS/visionOS

**Sprint**: 2 de 5  
**Duración**: 3 días laborales  
**Proyecto**: `apple-app`  
**Ruta**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app`

---

## LECTURA OBLIGATORIA ANTES DE INICIAR

1. **Leer**: `centralizar_auth/REGLAS-DESARROLLO.md`
2. **Verificar**: `centralizar_auth/ESTADO-ACTUAL.md`
3. **Prerequisito**: Sprint 1 completado y mergeado

---

## OBJETIVO DEL SPRINT

Migrar la aplicación Apple para autenticarse únicamente con `api-admin` y usar el token universal en todos los servicios. La experiencia de usuario NO debe cambiar - el proceso debe ser transparente.

---

## ENTREGABLES

| ID | Entregable | Criterio de Aceptación |
|----|------------|------------------------|
| E1 | Environment actualizado | URLs separadas para auth (api-admin) y mobile (api-mobile) |
| E2 | AuthRepository migrado | Login/refresh/logout apuntan a api-admin |
| E3 | Token universal | El mismo token funciona con api-admin y api-mobile |
| E4 | Tests actualizados | ≥80% coverage, tests de integración pasando |
| E5 | Build en todos los targets | iOS, iPadOS, macOS, visionOS compilan sin errores |

---

# FASE 1: CONFIGURACIÓN Y ENVIRONMENT
## Día 1 (4-5 horas)

### Protocolo de Inicio - EJECUTAR PRIMERO

```bash
# 1. Navegar al proyecto
cd /Users/jhoanmedina/source/EduGo/EduUI/apple-app

# 2. Verificar ubicación
pwd
# DEBE mostrar: /Users/jhoanmedina/source/EduGo/EduUI/apple-app

# 3. Sincronizar rama dev
git checkout dev
git pull origin dev

# 4. Verificar compilación
xcodebuild -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
  build 2>&1 | tail -20
# DEBE completar con "BUILD SUCCEEDED"

# 5. Ejecutar tests baseline
xcodebuild -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
  test 2>&1 | grep -E "(Test Case|passed|failed)"
# GUARDAR resultado para comparar al final

# 6. Crear rama de trabajo
git checkout -b feature/sprint2-migracion-auth-centralizada
```

---

### TAREA T01: Actualizar Environment.swift con URLs separadas

**Descripción**: Modificar la configuración de ambiente para tener URLs separadas para cada servicio del ecosistema.

**Archivo**: `App/Config/Environment.swift`

**Código a implementar**:

```swift
// App/Config/Environment.swift

import Foundation

/// Configuración de ambiente para el ecosistema EduGo
/// 
/// URLs del ecosistema:
/// - authAPIBaseURL: api-admin (Puerto 8081) - Autenticación centralizada
/// - mobileAPIBaseURL: api-mobile (Puerto 9091) - Materiales y progreso
/// - adminAPIBaseURL: api-admin (Puerto 8081) - Funciones administrativas
enum Environment {
    
    // MARK: - Ambiente actual
    
    /// Ambiente actual basado en configuración de build
    static var current: EnvironmentType {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    // MARK: - URLs de APIs
    
    /// URL base para autenticación (api-admin)
    /// Endpoints: /v1/auth/login, /v1/auth/refresh, /v1/auth/logout, /v1/auth/verify
    static var authAPIBaseURL: URL {
        switch current {
        case .development:
            return URL(string: "http://localhost:8081")!
        case .staging:
            return URL(string: "https://staging-api-admin.edugo.com")!
        case .production:
            return URL(string: "https://api-admin.edugo.com")!
        }
    }
    
    /// URL base para API móvil (api-mobile)
    /// Endpoints: /v1/materials, /v1/progress, etc.
    static var mobileAPIBaseURL: URL {
        switch current {
        case .development:
            return URL(string: "http://localhost:9091")!
        case .staging:
            return URL(string: "https://staging-api-mobile.edugo.com")!
        case .production:
            return URL(string: "https://api-mobile.edugo.com")!
        }
    }
    
    /// URL base para administración (api-admin)
    /// Endpoints: /v1/schools, /v1/units, etc.
    static var adminAPIBaseURL: URL {
        switch current {
        case .development:
            return URL(string: "http://localhost:8081")!
        case .staging:
            return URL(string: "https://staging-api-admin.edugo.com")!
        case .production:
            return URL(string: "https://api-admin.edugo.com")!
        }
    }
    
    // MARK: - Configuración JWT
    
    /// Issuer esperado en los tokens JWT
    /// DEBE coincidir con el issuer configurado en api-admin
    static var jwtIssuer: String {
        "edugo-central"
    }
    
    /// Duración del access token (para cálculo de refresh anticipado)
    static var accessTokenDuration: TimeInterval {
        15 * 60 // 15 minutos
    }
    
    /// Tiempo antes de expiración para iniciar refresh automático
    static var tokenRefreshThreshold: TimeInterval {
        2 * 60 // 2 minutos antes de expirar
    }
    
    // MARK: - Tipos
    
    enum EnvironmentType {
        case development
        case staging
        case production
        
        var name: String {
            switch self {
            case .development: return "Development"
            case .staging: return "Staging"
            case .production: return "Production"
            }
        }
    }
}

// MARK: - Extensiones para debugging

extension Environment {
    /// Imprime la configuración actual (solo en DEBUG)
    static func printConfiguration() {
        #if DEBUG
        print("""
        ═══════════════════════════════════════════
        EduGo Environment Configuration
        ═══════════════════════════════════════════
        Environment: \(current.name)
        Auth API:    \(authAPIBaseURL)
        Mobile API:  \(mobileAPIBaseURL)
        Admin API:   \(adminAPIBaseURL)
        JWT Issuer:  \(jwtIssuer)
        ═══════════════════════════════════════════
        """)
        #endif
    }
}
```

**Validación**:
```bash
# Compilar el proyecto
xcodebuild -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
  build 2>&1 | tail -5
# DEBE mostrar "BUILD SUCCEEDED"

# Verificar que no hay warnings relacionados con Environment
xcodebuild -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
  build 2>&1 | grep -i "Environment" | grep -i "warning"
# NO debe mostrar warnings
```

**Commit**:
```bash
git add App/Config/Environment.swift
git commit -m "feat(config): actualizar Environment con URLs separadas para ecosistema

URLs configuradas:
- authAPIBaseURL: api-admin (8081) para autenticación
- mobileAPIBaseURL: api-mobile (9091) para materiales
- adminAPIBaseURL: api-admin (8081) para administración

Configuración JWT:
- jwtIssuer: 'edugo-central' (unificado)
- tokenRefreshThreshold: 2 minutos antes de expirar

Soporte para: development, staging, production

Refs: SPRINT2-T01"
```

**Estado**: ⬜ Pendiente

---

### TAREA T02: Crear AuthEndpoints con rutas centralizadas

**Descripción**: Crear un archivo que centralice todas las definiciones de endpoints de autenticación.

**Archivo**: `Data/Network/Endpoints/AuthEndpoints.swift` (crear si no existe)

**Código**:

```swift
// Data/Network/Endpoints/AuthEndpoints.swift

import Foundation

/// Endpoints de autenticación centralizados
/// Todos apuntan a api-admin como servicio central de auth
enum AuthEndpoints {
    case login
    case refresh
    case logout
    case me
    case verify
    
    /// Path del endpoint
    var path: String {
        switch self {
        case .login:
            return "/v1/auth/login"
        case .refresh:
            return "/v1/auth/refresh"
        case .logout:
            return "/v1/auth/logout"
        case .me:
            return "/v1/auth/me"
        case .verify:
            return "/v1/auth/verify"
        }
    }
    
    /// URL completa del endpoint
    var url: URL {
        Environment.authAPIBaseURL.appendingPathComponent(path)
    }
    
    /// Método HTTP
    var method: HTTPMethod {
        switch self {
        case .login, .refresh, .logout, .verify:
            return .post
        case .me:
            return .get
        }
    }
    
    /// Indica si requiere autenticación
    var requiresAuth: Bool {
        switch self {
        case .login, .refresh:
            return false
        case .logout, .me, .verify:
            return true
        }
    }
}

// MARK: - Request Bodies

extension AuthEndpoints {
    
    /// Request body para login
    struct LoginRequest: Encodable {
        let email: String
        let password: String
    }
    
    /// Request body para refresh
    struct RefreshRequest: Encodable {
        let refreshToken: String
        
        enum CodingKeys: String, CodingKey {
            case refreshToken = "refresh_token"
        }
    }
    
    /// Request body para logout
    struct LogoutRequest: Encodable {
        let refreshToken: String
        
        enum CodingKeys: String, CodingKey {
            case refreshToken = "refresh_token"
        }
    }
}

// MARK: - Response Bodies

extension AuthEndpoints {
    
    /// Response de login exitoso
    struct LoginResponse: Decodable {
        let accessToken: String
        let refreshToken: String
        let expiresIn: Int
        let tokenType: String
        let user: UserResponse
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case tokenType = "token_type"
            case user
        }
    }
    
    /// Response de refresh exitoso
    struct RefreshResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: Int
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
        }
    }
    
    /// Información del usuario
    struct UserResponse: Decodable {
        let id: String
        let email: String
        let firstName: String
        let lastName: String
        let role: String
        let isActive: Bool
        let emailVerified: Bool
        
        enum CodingKeys: String, CodingKey {
            case id
            case email
            case firstName = "first_name"
            case lastName = "last_name"
            case role
            case isActive = "is_active"
            case emailVerified = "email_verified"
        }
    }
}

// MARK: - Mapper a Domain

extension AuthEndpoints.UserResponse {
    /// Convierte la respuesta del API a la entidad de dominio
    func toDomain() -> User {
        User(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            role: UserRole(rawValue: role) ?? .student,
            isActive: isActive,
            emailVerified: emailVerified
        )
    }
}

extension AuthEndpoints.LoginResponse {
    /// Convierte la respuesta de login a AuthTokens
    func toAuthTokens() -> AuthTokens {
        AuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }
}
```

**Validación**:
```bash
# Verificar que compila
xcodebuild -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
  build 2>&1 | tail -5
```

**Commit**:
```bash
git add Data/Network/Endpoints/AuthEndpoints.swift
git commit -m "feat(network): crear AuthEndpoints con definiciones centralizadas

Endpoints definidos:
- login: POST /v1/auth/login
- refresh: POST /v1/auth/refresh
- logout: POST /v1/auth/logout
- me: GET /v1/auth/me
- verify: POST /v1/auth/verify

Incluye:
- Request bodies (LoginRequest, RefreshRequest, LogoutRequest)
- Response bodies (LoginResponse, RefreshResponse)
- Mappers a entidades de dominio

Refs: SPRINT2-T02"
```

**Estado**: ⬜ Pendiente

---

### TAREA T03: Crear entidad AuthTokens en Domain

**Descripción**: Crear la entidad de dominio para manejar los tokens de autenticación.

**Archivo**: `Domain/Entities/AuthTokens.swift` (crear si no existe)

**Código**:

```swift
// Domain/Entities/AuthTokens.swift

import Foundation

/// Tokens de autenticación del usuario
/// Contiene access token y refresh token con metadata
public struct AuthTokens: Equatable {
    
    // MARK: - Propiedades
    
    /// Token de acceso JWT
    public let accessToken: String
    
    /// Token de refresh para obtener nuevos access tokens
    public let refreshToken: String
    
    /// Segundos hasta que el access token expire
    public let expiresIn: Int
    
    /// Momento en que se crearon los tokens
    public let createdAt: Date
    
    // MARK: - Propiedades Calculadas
    
    /// Fecha de expiración del access token
    public var expiresAt: Date {
        createdAt.addingTimeInterval(TimeInterval(expiresIn))
    }
    
    /// Indica si el access token está expirado
    public var isExpired: Bool {
        Date() >= expiresAt
    }
    
    /// Indica si el token está próximo a expirar
    /// Usa el threshold configurado en Environment
    public var shouldRefresh: Bool {
        let threshold = Environment.tokenRefreshThreshold
        return Date() >= expiresAt.addingTimeInterval(-threshold)
    }
    
    /// Tiempo restante en segundos antes de expirar
    public var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSinceNow)
    }
    
    // MARK: - Inicializador
    
    public init(
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        createdAt: Date = Date()
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.createdAt = createdAt
    }
}

// MARK: - Codable

extension AuthTokens: Codable {
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case createdAt = "created_at"
    }
}

// MARK: - Debug

extension AuthTokens: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        AuthTokens(
          accessToken: \(accessToken.prefix(20))...,
          refreshToken: \(refreshToken.prefix(10))...,
          expiresIn: \(expiresIn)s,
          expiresAt: \(expiresAt),
          isExpired: \(isExpired),
          shouldRefresh: \(shouldRefresh)
        )
        """
    }
}
```

**Validación**:
```bash
xcodebuild -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
  build 2>&1 | tail -5
```

**Commit**:
```bash
git add Domain/Entities/AuthTokens.swift
git commit -m "feat(domain): crear entidad AuthTokens para tokens de autenticación

Propiedades:
- accessToken, refreshToken, expiresIn, createdAt

Propiedades calculadas:
- expiresAt: Fecha de expiración
- isExpired: Si el token ya expiró
- shouldRefresh: Si debe refrescarse (2 min antes)
- timeRemaining: Segundos restantes

Implementa: Equatable, Codable, CustomDebugStringConvertible

Refs: SPRINT2-T03"
```

**Estado**: ⬜ Pendiente

---

### TAREA T04: Actualizar AuthRepository Protocol

**Descripción**: Actualizar el protocolo del repositorio de autenticación para reflejar la nueva arquitectura.

**Archivo**: `Domain/Repositories/AuthRepository.swift`

**Código**:

```swift
// Domain/Repositories/AuthRepository.swift

import Foundation

/// Protocolo que define las operaciones de autenticación
/// 
/// Implementación: AuthRepositoryImpl apunta a api-admin (auth centralizada)
/// 
/// Flujo de autenticación:
/// 1. login() → Obtiene tokens de api-admin
/// 2. Los tokens se guardan en Keychain
/// 3. El accessToken se usa para llamadas a api-mobile y api-admin
/// 4. refreshToken() se llama automáticamente cuando shouldRefresh = true
public protocol AuthRepository {
    
    /// Autentica al usuario con email y password
    /// - Parameters:
    ///   - email: Email del usuario
    ///   - password: Contraseña del usuario
    /// - Returns: Usuario autenticado o error
    func login(email: String, password: String) async -> Result<User, AppError>
    
    /// Refresca el access token usando el refresh token
    /// - Returns: Nuevos tokens o error
    func refreshToken() async -> Result<AuthTokens, AppError>
    
    /// Cierra la sesión del usuario
    /// Revoca tokens en el servidor y limpia storage local
    /// - Returns: Void o error
    func logout() async -> Result<Void, AppError>
    
    /// Obtiene el usuario actual (si hay sesión activa)
    /// - Returns: Usuario o nil si no hay sesión
    func getCurrentUser() async -> User?
    
    /// Verifica si hay una sesión activa con tokens válidos
    /// - Returns: true si hay sesión activa con tokens no expirados
    func isAuthenticated() async -> Bool
    
    /// Obtiene el access token actual (si existe y no está expirado)
    /// Si está próximo a expirar, intenta refrescarlo automáticamente
    /// - Returns: Access token válido o nil
    func getValidAccessToken() async -> String?
    
    /// Limpia todos los datos de autenticación locales
    /// NO revoca tokens en el servidor
    func clearLocalAuthData()
}

// MARK: - Extensión con implementaciones por defecto

public extension AuthRepository {
    
    /// Verifica si el usuario está autenticado con un token válido
    func isAuthenticated() async -> Bool {
        await getValidAccessToken() != nil
    }
}
```

**Validación**:
```bash
xcodebuild -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
  build 2>&1 | tail -5
```

**Commit**:
```bash
git add Domain/Repositories/AuthRepository.swift
git commit -m "feat(domain): actualizar AuthRepository protocol para auth centralizada

Métodos:
- login(email, password): Autenticación con api-admin
- refreshToken(): Refresh automático de tokens
- logout(): Revocación y limpieza
- getCurrentUser(): Usuario actual
- isAuthenticated(): Verificación de sesión
- getValidAccessToken(): Token válido con auto-refresh
- clearLocalAuthData(): Limpieza local

Documentación clara del flujo de autenticación

Refs: SPRINT2-T04"
```

**Estado**: ⬜ Pendiente

---

# FASE 2: MIGRACIÓN DEL REPOSITORY
## Día 2 (6-8 horas)

### TAREA T05: Implementar AuthRepositoryImpl actualizado

**Descripción**: Actualizar la implementación del repositorio para usar api-admin como servicio de autenticación.

**Archivo**: `Data/Repositories/AuthRepositoryImpl.swift`

**Código**:

```swift
// Data/Repositories/AuthRepositoryImpl.swift

import Foundation

/// Implementación del repositorio de autenticación
/// Usa api-admin como servicio central de auth
public final class AuthRepositoryImpl: AuthRepository {
    
    // MARK: - Dependencias
    
    private let apiClient: APIClient
    private let keychainService: KeychainService
    
    // MARK: - Estado interno
    
    private var cachedUser: User?
    private var cachedTokens: AuthTokens?
    private let tokenLock = NSLock()
    
    // MARK: - Inicialización
    
    public init(
        apiClient: APIClient,
        keychainService: KeychainService
    ) {
        self.apiClient = apiClient
        self.keychainService = keychainService
        loadCachedData()
    }
    
    // MARK: - AuthRepository Implementation
    
    public func login(email: String, password: String) async -> Result<User, AppError> {
        // 1. Preparar request
        let endpoint = AuthEndpoints.login
        let body = AuthEndpoints.LoginRequest(email: email, password: password)
        
        // 2. Llamar a api-admin
        let result: Result<AuthEndpoints.LoginResponse, AppError> = await apiClient.request(
            url: endpoint.url,
            method: endpoint.method,
            body: body,
            requiresAuth: false
        )
        
        // 3. Procesar respuesta
        switch result {
        case .success(let response):
            // Guardar tokens
            let tokens = response.toAuthTokens()
            saveTokens(tokens)
            
            // Guardar usuario
            let user = response.user.toDomain()
            saveUser(user)
            
            return .success(user)
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func refreshToken() async -> Result<AuthTokens, AppError> {
        // 1. Obtener refresh token actual
        guard let currentTokens = getCachedTokens(),
              !currentTokens.refreshToken.isEmpty else {
            return .failure(.unauthorized(message: "No hay refresh token disponible"))
        }
        
        // 2. Preparar request
        let endpoint = AuthEndpoints.refresh
        let body = AuthEndpoints.RefreshRequest(refreshToken: currentTokens.refreshToken)
        
        // 3. Llamar a api-admin
        let result: Result<AuthEndpoints.RefreshResponse, AppError> = await apiClient.request(
            url: endpoint.url,
            method: endpoint.method,
            body: body,
            requiresAuth: false
        )
        
        // 4. Procesar respuesta
        switch result {
        case .success(let response):
            let newTokens = AuthTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken ?? currentTokens.refreshToken,
                expiresIn: response.expiresIn
            )
            saveTokens(newTokens)
            return .success(newTokens)
            
        case .failure(let error):
            // Si falla el refresh, limpiar sesión
            if case .unauthorized = error {
                clearLocalAuthData()
            }
            return .failure(error)
        }
    }
    
    public func logout() async -> Result<Void, AppError> {
        // 1. Obtener refresh token para revocar
        guard let tokens = getCachedTokens() else {
            // No hay sesión, simplemente limpiar
            clearLocalAuthData()
            return .success(())
        }
        
        // 2. Preparar request
        let endpoint = AuthEndpoints.logout
        let body = AuthEndpoints.LogoutRequest(refreshToken: tokens.refreshToken)
        
        // 3. Llamar a api-admin (ignorar errores, limpiar de todos modos)
        let _: Result<EmptyResponse, AppError> = await apiClient.request(
            url: endpoint.url,
            method: endpoint.method,
            body: body,
            requiresAuth: true
        )
        
        // 4. Limpiar datos locales siempre
        clearLocalAuthData()
        
        return .success(())
    }
    
    public func getCurrentUser() async -> User? {
        // Primero verificar cache
        if let user = cachedUser {
            return user
        }
        
        // Si no hay cache pero hay token, obtener del servidor
        guard await isAuthenticated() else {
            return nil
        }
        
        let endpoint = AuthEndpoints.me
        let result: Result<AuthEndpoints.UserResponse, AppError> = await apiClient.request(
            url: endpoint.url,
            method: endpoint.method,
            requiresAuth: true
        )
        
        if case .success(let response) = result {
            let user = response.toDomain()
            saveUser(user)
            return user
        }
        
        return nil
    }
    
    public func isAuthenticated() async -> Bool {
        await getValidAccessToken() != nil
    }
    
    public func getValidAccessToken() async -> String? {
        tokenLock.lock()
        defer { tokenLock.unlock() }
        
        guard let tokens = cachedTokens else {
            return nil
        }
        
        // Si el token está expirado, no intentar refresh aquí
        if tokens.isExpired {
            return nil
        }
        
        // Si debe refrescarse, hacerlo
        if tokens.shouldRefresh {
            tokenLock.unlock() // Liberar lock durante la operación async
            let refreshResult = await refreshToken()
            tokenLock.lock() // Re-adquirir lock
            
            if case .success(let newTokens) = refreshResult {
                return newTokens.accessToken
            }
            return nil
        }
        
        return tokens.accessToken
    }
    
    public func clearLocalAuthData() {
        tokenLock.lock()
        defer { tokenLock.unlock() }
        
        cachedUser = nil
        cachedTokens = nil
        
        try? keychainService.delete(key: .accessToken)
        try? keychainService.delete(key: .refreshToken)
        try? keychainService.delete(key: .tokenExpiration)
        try? keychainService.delete(key: .currentUser)
    }
    
    // MARK: - Private Methods
    
    private func loadCachedData() {
        // Cargar tokens del Keychain
        if let accessToken = try? keychainService.get(key: .accessToken),
           let refreshToken = try? keychainService.get(key: .refreshToken),
           let expiresInString = try? keychainService.get(key: .tokenExpiration),
           let expiresIn = Int(expiresInString) {
            cachedTokens = AuthTokens(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresIn: expiresIn
            )
        }
        
        // Cargar usuario del Keychain
        if let userData = try? keychainService.getData(key: .currentUser),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            cachedUser = user
        }
    }
    
    private func getCachedTokens() -> AuthTokens? {
        tokenLock.lock()
        defer { tokenLock.unlock() }
        return cachedTokens
    }
    
    private func saveTokens(_ tokens: AuthTokens) {
        tokenLock.lock()
        defer { tokenLock.unlock() }
        
        cachedTokens = tokens
        
        try? keychainService.save(key: .accessToken, value: tokens.accessToken)
        try? keychainService.save(key: .refreshToken, value: tokens.refreshToken)
        try? keychainService.save(key: .tokenExpiration, value: String(tokens.expiresIn))
    }
    
    private func saveUser(_ user: User) {
        cachedUser = user
        
        if let userData = try? JSONEncoder().encode(user) {
            try? keychainService.saveData(key: .currentUser, data: userData)
        }
    }
}

// MARK: - Helper Types

private struct EmptyResponse: Decodable {}
```

**Validación**:
```bash
xcodebuild -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
  build 2>&1 | tail -5
```

**Commit**:
```bash
git add Data/Repositories/AuthRepositoryImpl.swift
git commit -m "feat(data): implementar AuthRepositoryImpl para auth centralizada

Implementación completa:
- login(): Autenticación con api-admin
- refreshToken(): Refresh automático con rotation
- logout(): Revocación en servidor + limpieza local
- getCurrentUser(): Cache + fallback a servidor
- getValidAccessToken(): Auto-refresh si shouldRefresh
- clearLocalAuthData(): Limpieza completa de Keychain

Thread-safety con NSLock para operaciones de tokens
Persistencia en Keychain para tokens y usuario

Refs: SPRINT2-T05"
```

**Estado**: ⬜ Pendiente

---

### TAREA T06: Actualizar APIClient para usar token centralizado

**Descripción**: Asegurar que el APIClient use el token de api-admin para todas las llamadas autenticadas.

**Archivo**: `Data/Network/APIClient.swift`

**Código a verificar/modificar**:

```swift
// Data/Network/APIClient.swift
// Verificar que el método de inyección de token funcione correctamente

extension APIClient {
    
    /// Ejecuta un request con autenticación automática
    func request<T: Decodable, B: Encodable>(
        url: URL,
        method: HTTPMethod,
        body: B? = nil,
        requiresAuth: Bool = true
    ) async -> Result<T, AppError> {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Inyectar token de autenticación si es requerido
        if requiresAuth {
            // El token viene de api-admin pero funciona con api-mobile
            guard let token = await authTokenProvider?.getValidAccessToken() else {
                return .failure(.unauthorized(message: "No hay token de autenticación"))
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Codificar body si existe
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                return .failure(.encoding(message: "Error codificando request"))
            }
        }
        
        // Ejecutar request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.network(message: "Respuesta inválida"))
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    return .success(decoded)
                } catch {
                    return .failure(.decoding(message: "Error decodificando respuesta: \(error)"))
                }
                
            case 401:
                return .failure(.unauthorized(message: "Token inválido o expirado"))
                
            case 403:
                return .failure(.forbidden(message: "Acceso denegado"))
                
            case 404:
                return .failure(.notFound(message: "Recurso no encontrado"))
                
            case 429:
                return .failure(.rateLimited(message: "Demasiadas solicitudes"))
                
            default:
                return .failure(.server(message: "Error del servidor: \(httpResponse.statusCode)"))
            }
            
        } catch {
            return .failure(.network(message: "Error de red: \(error.localizedDescription)"))
        }
    }
}
```

**Validación**:
```bash
# Verificar que compila
xcodebuild -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
  build 2>&1 | tail -5

# Verificar que no hay referencias hardcodeadas a URLs antiguas
grep -r "localhost:9091" . --include="*.swift" | grep -v "mobileAPIBaseURL"
# NO debe encontrar nada (solo mobileAPIBaseURL debe referenciar 9091)
```

**Commit** (si hubo cambios):
```bash
git add Data/Network/APIClient.swift
git commit -m "fix(network): asegurar inyección correcta de token centralizado

Verificaciones:
- Token se inyecta desde authTokenProvider
- Header Authorization: Bearer {token}
- Manejo de 401 para trigger de refresh
- Manejo de 429 para rate limiting

Refs: SPRINT2-T06"
```

**Estado**: ⬜ Pendiente

---

# FASE 3: INTEGRACIÓN Y USE CASES
## Día 2-3 (4-5 horas)

### TAREA T07: Verificar Use Cases existentes

**Descripción**: Verificar que los Use Cases de materiales y otras funcionalidades funcionen con el token universal.

**Archivos a verificar**:
- `Domain/UseCases/GetMaterialsUseCase.swift`
- `Domain/UseCases/GetSchoolsUseCase.swift`
- Otros Use Cases que llamen a api-mobile

**Verificación**:

```swift
// Ejemplo de verificación en GetMaterialsUseCase.swift
// El Use Case NO debe saber de dónde viene el token
// Solo usa el repository que internamente obtiene token válido

public final class GetMaterialsUseCase {
    private let materialsRepository: MaterialsRepository
    
    public func execute() async -> Result<[Material], AppError> {
        // El MaterialsRepository usa APIClient
        // APIClient obtiene token de AuthRepository
        // El token es de api-admin pero funciona con api-mobile
        // porque ambos usan el mismo JWT_SECRET y JWT_ISSUER
        
        return await materialsRepository.getMaterials()
    }
}
```

**Validación**:
```bash
# Ejecutar tests de los Use Cases
xcodebuild -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
  test -only-testing:apple-appTests/UseCaseTests \
  2>&1 | grep -E "(Test Case|passed|failed)"
```

**Commit** (si hubo cambios):
```bash
git add Domain/UseCases/
git commit -m "refactor(usecases): verificar compatibilidad con token universal

Use Cases verificados:
- GetMaterialsUseCase: OK
- GetSchoolsUseCase: OK
- [otros]: OK

No se requieren cambios - los Use Cases son agnósticos
del origen del token

Refs: SPRINT2-T07"
```

**Estado**: ⬜ Pendiente

---

### TAREA T08: Actualizar tests unitarios de AuthRepository

**Descripción**: Actualizar los tests para reflejar la nueva implementación.

**Archivo**: `apple-appTests/Data/Repositories/AuthRepositoryTests.swift`

**Código**:

```swift
// apple-appTests/Data/Repositories/AuthRepositoryTests.swift

import Testing
@testable import apple_app

@Suite("AuthRepository Tests")
struct AuthRepositoryTests {
    
    // MARK: - Setup
    
    var mockAPIClient: MockAPIClient!
    var mockKeychainService: MockKeychainService!
    var sut: AuthRepositoryImpl!
    
    init() {
        mockAPIClient = MockAPIClient()
        mockKeychainService = MockKeychainService()
        sut = AuthRepositoryImpl(
            apiClient: mockAPIClient,
            keychainService: mockKeychainService
        )
    }
    
    // MARK: - Login Tests
    
    @Test("Login exitoso retorna usuario y guarda tokens")
    func loginSuccess() async {
        // Given
        let expectedUser = User.mock
        let expectedTokens = AuthTokens(
            accessToken: "test-access-token",
            refreshToken: "test-refresh-token",
            expiresIn: 900
        )
        
        mockAPIClient.mockResponse = AuthEndpoints.LoginResponse(
            accessToken: expectedTokens.accessToken,
            refreshToken: expectedTokens.refreshToken,
            expiresIn: expectedTokens.expiresIn,
            tokenType: "Bearer",
            user: .mock
        )
        
        // When
        let result = await sut.login(email: "test@test.com", password: "password123")
        
        // Then
        switch result {
        case .success(let user):
            #expect(user.email == expectedUser.email)
            #expect(mockKeychainService.savedValues[.accessToken] == expectedTokens.accessToken)
            #expect(mockKeychainService.savedValues[.refreshToken] == expectedTokens.refreshToken)
        case .failure(let error):
            Issue.record("Login debió ser exitoso: \(error)")
        }
    }
    
    @Test("Login con credenciales incorrectas retorna error")
    func loginFailure() async {
        // Given
        mockAPIClient.mockError = .unauthorized(message: "Credenciales inválidas")
        
        // When
        let result = await sut.login(email: "wrong@test.com", password: "wrong")
        
        // Then
        switch result {
        case .success:
            Issue.record("Login debió fallar")
        case .failure(let error):
            #expect(error.isUnauthorized)
        }
    }
    
    // MARK: - Refresh Tests
    
    @Test("Refresh token actualiza access token")
    func refreshTokenSuccess() async {
        // Given
        mockKeychainService.savedValues[.accessToken] = "old-token"
        mockKeychainService.savedValues[.refreshToken] = "valid-refresh"
        mockKeychainService.savedValues[.tokenExpiration] = "900"
        
        // Re-crear sut para cargar tokens
        sut = AuthRepositoryImpl(
            apiClient: mockAPIClient,
            keychainService: mockKeychainService
        )
        
        mockAPIClient.mockResponse = AuthEndpoints.RefreshResponse(
            accessToken: "new-access-token",
            refreshToken: "new-refresh-token",
            expiresIn: 900
        )
        
        // When
        let result = await sut.refreshToken()
        
        // Then
        switch result {
        case .success(let tokens):
            #expect(tokens.accessToken == "new-access-token")
            #expect(mockKeychainService.savedValues[.accessToken] == "new-access-token")
        case .failure(let error):
            Issue.record("Refresh debió ser exitoso: \(error)")
        }
    }
    
    // MARK: - Logout Tests
    
    @Test("Logout limpia datos locales")
    func logoutClearsData() async {
        // Given
        mockKeychainService.savedValues[.accessToken] = "token"
        mockKeychainService.savedValues[.refreshToken] = "refresh"
        
        // When
        let result = await sut.logout()
        
        // Then
        #expect(result.isSuccess)
        #expect(mockKeychainService.savedValues[.accessToken] == nil)
        #expect(mockKeychainService.savedValues[.refreshToken] == nil)
    }
    
    // MARK: - Token Validation Tests
    
    @Test("getValidAccessToken retorna token si no expirado")
    func getValidTokenReturnsIfValid() async {
        // Given
        mockKeychainService.savedValues[.accessToken] = "valid-token"
        mockKeychainService.savedValues[.refreshToken] = "refresh"
        mockKeychainService.savedValues[.tokenExpiration] = "900"
        
        sut = AuthRepositoryImpl(
            apiClient: mockAPIClient,
            keychainService: mockKeychainService
        )
        
        // When
        let token = await sut.getValidAccessToken()
        
        // Then
        #expect(token == "valid-token")
    }
    
    @Test("isAuthenticated retorna false sin tokens")
    func isAuthenticatedFalseWithoutTokens() async {
        // Given - no tokens
        
        // When
        let isAuth = await sut.isAuthenticated()
        
        // Then
        #expect(!isAuth)
    }
}

// MARK: - Mocks

class MockAPIClient: APIClient {
    var mockResponse: Any?
    var mockError: AppError?
    
    func request<T: Decodable, B: Encodable>(
        url: URL,
        method: HTTPMethod,
        body: B?,
        requiresAuth: Bool
    ) async -> Result<T, AppError> {
        if let error = mockError {
            return .failure(error)
        }
        if let response = mockResponse as? T {
            return .success(response)
        }
        return .failure(.unknown(message: "Mock no configurado"))
    }
}

class MockKeychainService: KeychainService {
    var savedValues: [KeychainKey: String] = [:]
    
    func save(key: KeychainKey, value: String) throws {
        savedValues[key] = value
    }
    
    func get(key: KeychainKey) throws -> String? {
        savedValues[key]
    }
    
    func delete(key: KeychainKey) throws {
        savedValues.removeValue(forKey: key)
    }
}
```

**Validación**:
```bash
# Ejecutar tests del repository
xcodebuild -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
  test -only-testing:apple-appTests/AuthRepositoryTests \
  2>&1 | grep -E "(Test Case|passed|failed)"
```

**Commit**:
```bash
git add apple-appTests/Data/Repositories/AuthRepositoryTests.swift
git commit -m "test(auth): actualizar tests de AuthRepository

Tests incluidos:
- loginSuccess: Login correcto guarda tokens
- loginFailure: Credenciales incorrectas retorna error
- refreshTokenSuccess: Refresh actualiza tokens
- logoutClearsData: Logout limpia Keychain
- getValidTokenReturnsIfValid: Token válido se retorna
- isAuthenticatedFalseWithoutTokens: Sin tokens = no auth

Mocks creados: MockAPIClient, MockKeychainService

Refs: SPRINT2-T08"
```

**Estado**: ⬜ Pendiente

---

# FASE 4: VALIDACIÓN FINAL
## Día 3 (3-4 horas)

### TAREA T09: Testing manual completo

**Descripción**: Realizar pruebas manuales del flujo completo de autenticación.

**Checklist de pruebas**:

```markdown
## Testing Manual - Sprint 2

### Preparación
- [ ] api-admin corriendo en localhost:8081
- [ ] api-mobile corriendo en localhost:9091
- [ ] Simulador iOS configurado

### Flujo de Login
- [ ] Abrir app → Muestra pantalla de login
- [ ] Ingresar email incorrecto → Muestra error
- [ ] Ingresar password incorrecto → Muestra error
- [ ] Ingresar credenciales correctas → Login exitoso
- [ ] Usuario redirigido a Home

### Flujo de Token Universal
- [ ] Después de login, navegar a Materials
- [ ] Materials carga correctamente (token funciona con api-mobile)
- [ ] Navegar a Schools (si aplica)
- [ ] Schools carga correctamente

### Flujo de Refresh
- [ ] Esperar a que token esté próximo a expirar (o modificar threshold)
- [ ] Realizar acción que requiera API call
- [ ] Token se refresca automáticamente
- [ ] Acción completa exitosamente

### Flujo de Logout
- [ ] Presionar logout
- [ ] Sesión cerrada
- [ ] Intentar navegar a pantalla protegida
- [ ] Redirige a login

### Manejo de Errores
- [ ] Detener api-admin → App muestra error apropiado
- [ ] Detener api-mobile → App muestra error apropiado
- [ ] Restaurar servicios → App recupera funcionalidad

### Persistencia
- [ ] Login exitoso
- [ ] Cerrar app completamente
- [ ] Abrir app nuevamente
- [ ] Sesión se mantiene (si token no expiró)
```

**Estado**: ⬜ Pendiente

---

### TAREA T10: Build en todos los targets

**Descripción**: Verificar que el proyecto compila en todos los targets de Apple.

**Comandos**:

```bash
# iOS
echo "Building for iOS..."
xcodebuild -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
  build 2>&1 | tail -3

# iPadOS
echo "Building for iPadOS..."
xcodebuild -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4),OS=18.0' \
  build 2>&1 | tail -3

# macOS
echo "Building for macOS..."
xcodebuild -scheme apple-app \
  -destination 'platform=macOS' \
  build 2>&1 | tail -3

# visionOS (si está disponible)
echo "Building for visionOS..."
xcodebuild -scheme apple-app \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' \
  build 2>&1 | tail -3 || echo "visionOS no disponible"
```

**Validación**: Todos los builds deben mostrar "BUILD SUCCEEDED"

**Commit** (solo si hubo fixes):
```bash
git add .
git commit -m "fix: corregir compilación para todos los targets Apple

Targets verificados:
- iOS 18.0: BUILD SUCCEEDED
- iPadOS 18.0: BUILD SUCCEEDED
- macOS: BUILD SUCCEEDED
- visionOS 2.0: BUILD SUCCEEDED

Refs: SPRINT2-T10"
```

**Estado**: ⬜ Pendiente

---

### TAREA T11: Ejecutar todos los tests

**Descripción**: Ejecutar la suite completa de tests y verificar coverage.

**Comandos**:

```bash
# Ejecutar todos los tests
xcodebuild -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
  test 2>&1 | tee test-results.txt

# Contar resultados
echo "Tests pasados: $(grep -c 'passed' test-results.txt)"
echo "Tests fallidos: $(grep -c 'failed' test-results.txt)"

# Verificar coverage (si está configurado)
# xcrun llvm-cov report ...
```

**Validación**:
- 0 tests fallidos
- Coverage >= 80% en código nuevo

**Estado**: ⬜ Pendiente

---

### TAREA T12: Crear PR y validar pipeline

**Descripción**: Crear Pull Request y esperar validación del pipeline.

**Acciones**:

```bash
# 1. Verificar estado del repositorio
git status
# Debe mostrar solo archivos tracked

# 2. Push de la rama
git push origin feature/sprint2-migracion-auth-centralizada

# 3. Crear PR en GitHub con el siguiente contenido:
```

**Título del PR**:
```
feat(auth): Sprint 2 - Migración de Apple-App a autenticación centralizada
```

**Descripción del PR**:
```markdown
## Resumen

Migración completa de apple-app para usar api-admin como servicio central de autenticación.

## Cambios Realizados

### Configuración
- Environment.swift con URLs separadas (auth, mobile, admin)
- AuthEndpoints.swift con definiciones centralizadas

### Domain
- AuthTokens entity con lógica de expiración
- AuthRepository protocol actualizado

### Data
- AuthRepositoryImpl apuntando a api-admin
- APIClient con inyección de token universal

### Tests
- Tests unitarios de AuthRepository actualizados
- Tests de integración con token universal

## Testing

### Manual
- [x] Login con api-admin
- [x] Token funciona con api-mobile
- [x] Refresh automático
- [x] Logout revoca tokens

### Automatizado
- [x] Unit tests pasando
- [x] Build en iOS, iPadOS, macOS, visionOS

## Breaking Changes

Ninguno para el usuario final. El cambio es transparente.

## Screenshots

[Si aplica]

## Checklist

- [x] Código compila sin warnings
- [x] Tests pasando
- [x] Documentación actualizada
- [x] Build en todos los targets
```

**Después de crear el PR**:
1. Esperar que el pipeline termine
2. Verificar que todos los checks pasen
3. Resolver comentarios de Copilot (si los hay)
4. Solicitar review

**Estado**: ⬜ Pendiente

---

## RESUMEN SPRINT 2

| Fase | Tareas | Duración | Estado |
|------|--------|----------|--------|
| Fase 1 | T01-T04 | 4-5 horas | ⬜ |
| Fase 2 | T05-T06 | 6-8 horas | ⬜ |
| Fase 3 | T07-T08 | 4-5 horas | ⬜ |
| Fase 4 | T09-T12 | 3-4 horas | ⬜ |

**Total estimado**: 3 días  
**Commits esperados**: ~10  
**PRs**: 1

---

## REFERENCIAS

- **Reglas de desarrollo**: `centralizar_auth/REGLAS-DESARROLLO.md`
- **Estado actual**: `centralizar_auth/ESTADO-ACTUAL.md`
- **Sprint anterior**: `centralizar_auth/sprints/sprint-1-api-admin/`

---
