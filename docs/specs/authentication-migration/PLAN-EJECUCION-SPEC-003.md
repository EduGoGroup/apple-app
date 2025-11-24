# Plan de Ejecución: SPEC-003 - Authentication Real API Migration

**Fecha**: 2025-01-24  
**Versión**: 1.0  
**Estimación**: 28 horas (3-4 días)  
**Tipo**: 🤖 **100% AUTOMATIZADO** (como SPEC-002)  
**Prioridad**: 🟠 P1 - ALTA

---

## 📋 Resumen Ejecutivo

Este plan migra la autenticación desde DummyJSON al API real de EduGo, siguiendo el patrón exitoso de SPEC-002 (100% automatizado, sin configuración manual de Xcode).

### Estrategia

- ✅ **100% programático** - Sin pasos manuales en Xcode
- ✅ **Feature flag** - Toggle entre DummyJSON/Real API
- ✅ **Backward compatible** - No rompe funcionalidad actual
- ✅ **Testing first** - TDD approach
- ✅ **Logging integrado** - Usa sistema de SPEC-002

---

## 🎯 Objetivos

### Funcionales

1. ✅ Migrar DTOs de DummyJSON → API Real
2. ✅ Implementar JWT decoder local
3. ✅ Implementar token refresh automático (actor-based)
4. ✅ Implementar biometric authentication
5. ✅ Feature flag DummyJSON/Real API
6. ✅ Actualizar AuthRepositoryImpl

### No Funcionales

1. ✅ Zero configuración manual de Xcode
2. ✅ Tests 100% pasando
3. ✅ Builds exitosos en 3 schemes
4. ✅ Documentación completa
5. ✅ Logging profesional integrado

---

## 📊 Análisis de Dependencias

### Dependencias Completadas

- ✅ **SPEC-001**: Environment system (apiBaseURL disponible)
- ✅ **SPEC-002**: Logging system (LoggerFactory disponible)

### Bloqueantes

**NINGUNO** - API backend es suficiente para implementar.

### Gaps Backend (Opcionales)

- ⚠️ GET /v1/auth/me NO existe → **Workaround**: Decodificar JWT localmente
- ⚠️ POST /v1/auth/logout requiere refresh_token → **Workaround**: Guardar refresh token

---

## 🔄 Estrategia de Migración

### Approach: Feature Flag + Adapter Pattern

```swift
// Environment.swift
enum AuthenticationMode {
    case dummyJSON  // Para desarrollo/testing
    case realAPI    // Para staging/production
}

extension AppEnvironment {
    static var authMode: AuthenticationMode {
        #if DEBUG
        return .dummyJSON  // Default en desarrollo
        #else
        return .realAPI    // Producción usa API real
        #endif
    }
}
```

### Ventajas

- ✅ Desarrollo continuo con DummyJSON
- ✅ Testing paralelo con API real
- ✅ Rollback inmediato si hay problemas
- ✅ AB testing posible

---

## 📋 Fases de Ejecución

### FASE 0: Preparación (1h)

**Objetivo**: Crear rama y estructura de archivos.

**Tareas**:
- [x] Crear rama `feat/auth-real-api`
- [ ] Crear carpetas en Domain y Data
- [ ] Actualizar documentación de SPEC-003

**Archivos a crear**:
```
Domain/
├── Entities/
│   └── UserRole.swift                    # NEW
├── Models/
│   └── Auth/
│       └── TokenInfo.swift               # NEW

Data/
├── DTOs/
│   └── Auth/
│       ├── LoginDTO.swift                # REPLACE AuthDTO.swift
│       ├── RefreshDTO.swift              # NEW
│       └── LogoutDTO.swift               # NEW
├── Services/
│   ├── Auth/
│   │   ├── JWTDecoder.swift              # NEW
│   │   ├── TokenRefreshCoordinator.swift # NEW
│   │   └── BiometricAuthService.swift    # NEW
│   └── Network/
│       └── Interceptors/
│           └── AuthInterceptor.swift     # NEW

apple-appTests/
├── Data/
│   ├── Services/
│   │   ├── JWTDecoderTests.swift         # NEW
│   │   ├── TokenRefreshCoordinatorTests.swift # NEW
│   │   └── BiometricAuthServiceTests.swift # NEW
│   └── Repositories/
│       └── AuthRepositoryImplTests.swift  # ENHANCE
```

**Comandos**:
```bash
git checkout dev
git pull origin dev
git checkout -b feat/auth-real-api
```

**Criterios de aceptación**:
- [ ] Rama creada desde dev actualizado
- [ ] Estructura de carpetas creada

---

### FASE 1: Domain Layer - Models & Entities (3h)

**Objetivo**: Crear entidades de dominio agnósticas del API.

#### 1.1 UserRole Enum (30 min)

**Archivo**: `Domain/Entities/UserRole.swift`

```swift
/// Roles de usuario en el sistema EduGo
enum UserRole: String, Codable, Sendable {
    case student = "student"
    case teacher = "teacher"
    case admin = "admin"
    case parent = "parent"
    
    var displayName: String {
        switch self {
        case .student: return "Estudiante"
        case .teacher: return "Profesor"
        case .admin: return "Administrador"
        case .parent: return "Padre/Tutor"
        }
    }
    
    var permissions: Set<Permission> {
        // TODO: Implementar en SPEC futura
        []
    }
}
```

**Tests**:
```swift
@Test func roleFromString() {
    let role = UserRole(rawValue: "student")
    #expect(role == .student)
}

@Test func roleDisplayName() {
    #expect(UserRole.teacher.displayName == "Profesor")
}
```

---

#### 1.2 TokenInfo Model (1h)

**Archivo**: `Domain/Models/Auth/TokenInfo.swift`

```swift
import Foundation

/// Información de tokens de autenticación con expiración
struct TokenInfo: Codable, Sendable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    
    // MARK: - Computed Properties
    
    /// Token expiró
    var isExpired: Bool {
        Date() >= expiresAt
    }
    
    /// Token necesita refresh (expira en < 5 min)
    var needsRefresh: Bool {
        let fiveMinutesFromNow = Date().addingTimeInterval(300)
        return fiveMinutesFromNow >= expiresAt
    }
    
    /// Tiempo restante hasta expiración
    var timeUntilExpiration: TimeInterval {
        expiresAt.timeIntervalSinceNow
    }
    
    // MARK: - Initializers
    
    init(accessToken: String, refreshToken: String, expiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
    
    /// Crea TokenInfo desde expiresIn (segundos)
    init(accessToken: String, refreshToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
    }
}

// MARK: - Testing

#if DEBUG
extension TokenInfo {
    static func fixture(
        accessToken: String = "mock_access_token",
        refreshToken: String = "mock_refresh_token",
        expiresIn: TimeInterval = 900
    ) -> TokenInfo {
        TokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(expiresIn)
        )
    }
    
    static var expired: TokenInfo {
        TokenInfo(
            accessToken: "expired_token",
            refreshToken: "expired_refresh",
            expiresAt: Date().addingTimeInterval(-3600) // Expiró hace 1 hora
        )
    }
    
    static var needingRefresh: TokenInfo {
        TokenInfo(
            accessToken: "soon_to_expire",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(240) // Expira en 4 min
        )
    }
}
#endif
```

**Tests**:
```swift
@Test func tokenIsExpired() {
    let token = TokenInfo.expired
    #expect(token.isExpired == true)
}

@Test func tokenNeedsRefresh() {
    let token = TokenInfo.needingRefresh
    #expect(token.needsRefresh == true)
}

@Test func tokenFromExpiresIn() {
    let token = TokenInfo(
        accessToken: "token",
        refreshToken: "refresh",
        expiresIn: 900
    )
    #expect(token.timeUntilExpiration > 890)
    #expect(token.timeUntilExpiration <= 900)
}
```

---

#### 1.3 Update User Entity (1h)

**Archivo**: `Domain/Entities/User.swift`

```swift
// ANTES
struct User: Identifiable, Codable, Sendable {
    let id: String
    let email: String
    let displayName: String
    let photoURL: URL?
    let isEmailVerified: Bool
}

// DESPUÉS
struct User: Identifiable, Codable, Sendable, Equatable {
    let id: String              // UUID string
    let email: String
    let displayName: String
    let role: UserRole
    let isEmailVerified: Bool
    
    // MARK: - Computed Properties
    
    var isStudent: Bool { role == .student }
    var isTeacher: Bool { role == .teacher }
    var isAdmin: Bool { role == .admin }
    
    // MARK: - Initializers
    
    init(
        id: String,
        email: String,
        displayName: String,
        role: UserRole,
        isEmailVerified: Bool = false
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.role = role
        self.isEmailVerified = isEmailVerified
    }
}

// MARK: - Testing

#if DEBUG
extension User {
    static func fixture(
        id: String = "550e8400-e29b-41d4-a716-446655440000",
        email: String = "test@edugo.com",
        displayName: String = "Test User",
        role: UserRole = .student
    ) -> User {
        User(
            id: id,
            email: email,
            displayName: displayName,
            role: role,
            isEmailVerified: true
        )
    }
    
    static var studentFixture: User {
        fixture(role: .student)
    }
    
    static var teacherFixture: User {
        fixture(role: .teacher, displayName: "Prof. García")
    }
}
#endif
```

**Cambios**:
- ✅ Agregar `role: UserRole`
- ✅ Remover `photoURL` (no lo provee API actual)
- ✅ Agregar helpers `isStudent`, `isTeacher`, `isAdmin`
- ✅ Conformar `Equatable` para testing

**Tests**:
```swift
@Test func userRoleHelpers() {
    let student = User.studentFixture
    #expect(student.isStudent == true)
    #expect(student.isTeacher == false)
}

@Test func userEquality() {
    let user1 = User.fixture(id: "123")
    let user2 = User.fixture(id: "123")
    #expect(user1 == user2)
}
```

---

#### 1.4 AuthRepository Protocol Update (30 min)

**Archivo**: `Domain/Repositories/AuthRepository.swift`

```swift
// AGREGAR nuevo método
protocol AuthRepository: Sendable {
    // Existentes
    func login(email: String, password: String) async -> Result<User, AppError>
    func logout() async -> Result<Void, AppError>
    func getCurrentUser() async -> Result<User, AppError>
    func refreshSession() async -> Result<User, AppError>
    func hasActiveSession() async -> Bool
    
    // NUEVOS
    func loginWithBiometrics() async -> Result<User, AppError>
    func getTokenInfo() async -> Result<TokenInfo, AppError>
}
```

**Criterios de aceptación FASE 1**:
- [ ] UserRole creado con tests
- [ ] TokenInfo creado con tests
- [ ] User actualizado (role, sin photoURL)
- [ ] AuthRepository actualizado
- [ ] Tests pasando (15+)
- [ ] Build exitoso

---

### FASE 2: Data Layer - DTOs (4h)

**Objetivo**: Crear DTOs adaptados al API real de EduGo.

#### 2.1 LoginDTO (1h)

**Archivo**: `Data/DTOs/Auth/LoginDTO.swift`

```swift
import Foundation

// MARK: - Login Request

struct LoginRequest: Codable, Sendable {
    let email: String
    let password: String
}

// MARK: - Login Response

struct LoginResponse: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let user: UserDTO
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case user
    }
    
    func toTokenInfo() -> TokenInfo {
        TokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }
    
    func toDomain() -> User {
        user.toDomain()
    }
}

// MARK: - User DTO

struct UserDTO: Codable, Sendable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let fullName: String
    let role: String
    
    enum CodingKeys: String, CodingKey {
        case id, email, role
        case firstName = "first_name"
        case lastName = "last_name"
        case fullName = "full_name"
    }
    
    func toDomain() -> User {
        User(
            id: id,
            email: email,
            displayName: fullName,
            role: UserRole(rawValue: role) ?? .student,
            isEmailVerified: true // Asumimos true si login exitoso
        )
    }
}

// MARK: - Testing

#if DEBUG
extension LoginResponse {
    static func fixture() -> LoginResponse {
        LoginResponse(
            accessToken: "eyJhbGc...",
            refreshToken: "550e8400-...",
            expiresIn: 900,
            tokenType: "Bearer",
            user: UserDTO.fixture()
        )
    }
}

extension UserDTO {
    static func fixture() -> UserDTO {
        UserDTO(
            id: "550e8400-e29b-41d4-a716-446655440000",
            email: "test@edugo.com",
            firstName: "Juan",
            lastName: "Pérez",
            fullName: "Juan Pérez",
            role: "student"
        )
    }
}
#endif
```

**Tests**:
```swift
@Test func loginResponseDecoding() throws {
    let json = """
    {
        "access_token": "eyJhbGc...",
        "refresh_token": "550e8400-...",
        "expires_in": 900,
        "token_type": "Bearer",
        "user": {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "email": "test@edugo.com",
            "first_name": "Juan",
            "last_name": "Pérez",
            "full_name": "Juan Pérez",
            "role": "student"
        }
    }
    """
    
    let data = json.data(using: .utf8)!
    let response = try JSONDecoder().decode(LoginResponse.self, from: data)
    
    #expect(response.accessToken == "eyJhbGc...")
    #expect(response.user.email == "test@edugo.com")
}

@Test func userDTOToDomain() {
    let dto = UserDTO.fixture()
    let user = dto.toDomain()
    
    #expect(user.email == "test@edugo.com")
    #expect(user.displayName == "Juan Pérez")
    #expect(user.role == .student)
}
```

---

#### 2.2 RefreshDTO (1h)

**Archivo**: `Data/DTOs/Auth/RefreshDTO.swift`

```swift
import Foundation

// MARK: - Refresh Request

struct RefreshRequest: Codable, Sendable {
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

// MARK: - Refresh Response

struct RefreshResponse: Codable, Sendable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
    
    /// Actualiza TokenInfo existente con nuevo access token
    func updateTokenInfo(_ current: TokenInfo) -> TokenInfo {
        TokenInfo(
            accessToken: accessToken,
            refreshToken: current.refreshToken, // NO cambia
            expiresIn: expiresIn
        )
    }
}

// MARK: - Testing

#if DEBUG
extension RefreshResponse {
    static func fixture() -> RefreshResponse {
        RefreshResponse(
            accessToken: "new_access_token",
            expiresIn: 900,
            tokenType: "Bearer"
        )
    }
}
#endif
```

**Tests**:
```swift
@Test func refreshResponseDecoding() throws {
    let json = """
    {
        "access_token": "new_token",
        "expires_in": 900,
        "token_type": "Bearer"
    }
    """
    
    let data = json.data(using: .utf8)!
    let response = try JSONDecoder().decode(RefreshResponse.self, from: data)
    
    #expect(response.accessToken == "new_token")
    #expect(response.expiresIn == 900)
}

@Test func refreshUpdatesTokenInfo() {
    let current = TokenInfo.fixture(
        accessToken: "old_token",
        refreshToken: "refresh_123"
    )
    
    let response = RefreshResponse.fixture()
    let updated = response.updateTokenInfo(current)
    
    #expect(updated.accessToken == "new_access_token")
    #expect(updated.refreshToken == "refresh_123") // No cambió
}
```

---

#### 2.3 LogoutDTO (30 min)

**Archivo**: `Data/DTOs/Auth/LogoutDTO.swift`

```swift
import Foundation

// MARK: - Logout Request

struct LogoutRequest: Codable, Sendable {
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

// MARK: - Testing

#if DEBUG
extension LogoutRequest {
    static func fixture() -> LogoutRequest {
        LogoutRequest(refreshToken: "refresh_token_123")
    }
}
#endif
```

**Nota**: Logout no tiene response body (204 No Content).

---

#### 2.4 DummyJSON DTOs (Legacy) (30 min)

**Archivo**: `Data/DTOs/Auth/DummyJSONDTO.swift`

```swift
import Foundation

// MARK: - DummyJSON DTOs (Deprecated - Solo para feature flag)

struct DummyJSONLoginRequest: Codable, Sendable {
    let username: String
    let password: String
    let expiresInMins: Int?
}

struct DummyJSONLoginResponse: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let id: Int
    let username: String
    let email: String
    let firstName: String
    let lastName: String
    let gender: String
    let image: String
    
    func toDomain() -> User {
        User(
            id: String(id),
            email: email,
            displayName: "\(firstName) \(lastName)",
            role: .student, // DummyJSON no tiene roles
            isEmailVerified: true
        )
    }
}
```

**Propósito**: Mantener compatibilidad con DummyJSON durante feature flag.

---

#### 2.5 Delete Old AuthDTO.swift

**Acción**: Eliminar `Data/DTOs/AuthDTO.swift` (reemplazado por nuevos DTOs).

**Criterios de aceptación FASE 2**:
- [ ] LoginDTO creado con tests
- [ ] RefreshDTO creado con tests
- [ ] LogoutDTO creado
- [ ] DummyJSONDTO creado (legacy)
- [ ] AuthDTO.swift eliminado
- [ ] Tests pasando (10+)
- [ ] Build exitoso

---

### FASE 3: JWT Decoder (3h)

**Objetivo**: Decodificar y validar JWT localmente.

#### 3.1 JWTDecoder Protocol & Implementation (2h)

**Archivo**: `Data/Services/Auth/JWTDecoder.swift`

```swift
import Foundation

// MARK: - Protocol

protocol JWTDecoder: Sendable {
    func decode(_ token: String) throws -> JWTPayload
}

// MARK: - Payload

struct JWTPayload: Sendable, Equatable {
    let sub: String       // User ID
    let email: String
    let role: String
    let exp: Date         // Expiration
    let iat: Date         // Issued at
    let iss: String       // Issuer
    
    var isExpired: Bool {
        Date() >= exp
    }
    
    var toDomainUser: User {
        User(
            id: sub,
            email: email,
            displayName: email.components(separatedBy: "@").first ?? "User",
            role: UserRole(rawValue: role) ?? .student,
            isEmailVerified: true
        )
    }
}

// MARK: - Errors

enum JWTError: Error, LocalizedError {
    case invalidFormat
    case invalidBase64
    case missingClaims
    case invalidIssuer
    case expired
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "JWT format inválido (debe tener 3 segmentos)"
        case .invalidBase64:
            return "Base64 inválido en payload"
        case .missingClaims:
            return "Claims requeridos faltantes"
        case .invalidIssuer:
            return "Issuer no es edugo-mobile"
        case .expired:
            return "Token expirado"
        }
    }
}

// MARK: - Implementation

final class DefaultJWTDecoder: JWTDecoder {
    private let logger = LoggerFactory.auth
    private let expectedIssuer = "edugo-mobile"
    
    func decode(_ token: String) throws -> JWTPayload {
        logger.debug("Decoding JWT token")
        
        // 1. Separar en segmentos (header.payload.signature)
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3 else {
            logger.error("JWT format invalid", metadata: ["segments": segments.count.description])
            throw JWTError.invalidFormat
        }
        
        // 2. Decodificar payload (segmento 1)
        let payloadSegment = segments[1]
        guard let payloadData = base64URLDecode(payloadSegment) else {
            logger.error("Failed to decode base64URL payload")
            throw JWTError.invalidBase64
        }
        
        // 3. Parsear JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        let dto = try decoder.decode(JWTPayloadDTO.self, from: payloadData)
        
        // 4. Validar issuer
        guard dto.iss == expectedIssuer else {
            logger.error("Invalid issuer", metadata: [
                "expected": expectedIssuer,
                "actual": dto.iss ?? "nil"
            ])
            throw JWTError.invalidIssuer
        }
        
        // 5. Construir payload
        let payload = JWTPayload(
            sub: dto.sub,
            email: dto.email,
            role: dto.role,
            exp: Date(timeIntervalSince1970: dto.exp),
            iat: Date(timeIntervalSince1970: dto.iat),
            iss: dto.iss ?? ""
        )
        
        logger.debug("JWT decoded successfully", metadata: [
            "userId": payload.sub,
            "role": payload.role
        ])
        
        return payload
    }
    
    // MARK: - Base64URL Decoding
    
    private func base64URLDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Agregar padding si falta
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        return Data(base64Encoded: base64)
    }
}

// MARK: - DTO Internal

private struct JWTPayloadDTO: Codable {
    let sub: String
    let email: String
    let role: String
    let exp: TimeInterval
    let iat: TimeInterval
    let iss: String?
}

// MARK: - Testing

#if DEBUG
extension JWTPayload {
    static func fixture() -> JWTPayload {
        JWTPayload(
            sub: "550e8400-e29b-41d4-a716-446655440000",
            email: "test@edugo.com",
            role: "student",
            exp: Date().addingTimeInterval(900),
            iat: Date(),
            iss: "edugo-mobile"
        )
    }
    
    static var expired: JWTPayload {
        JWTPayload(
            sub: "550e8400-e29b-41d4-a716-446655440000",
            email: "test@edugo.com",
            role: "student",
            exp: Date().addingTimeInterval(-3600), // Expiró hace 1h
            iat: Date().addingTimeInterval(-4500),
            iss: "edugo-mobile"
        )
    }
}

final class MockJWTDecoder: JWTDecoder {
    var payloadToReturn: JWTPayload?
    var errorToThrow: Error?
    
    func decode(_ token: String) throws -> JWTPayload {
        if let error = errorToThrow {
            throw error
        }
        return payloadToReturn ?? .fixture()
    }
}
#endif
```

---

#### 3.2 Tests (1h)

**Archivo**: `apple-appTests/Data/Services/JWTDecoderTests.swift`

```swift
import Testing
@testable import apple_app

@Suite("JWT Decoder Tests")
struct JWTDecoderTests {
    
    let decoder = DefaultJWTDecoder()
    
    // Token real de prueba (generado con HS256, secret: "test-secret")
    // Payload: {"sub":"550e8400","email":"test@edugo.com","role":"student","exp":9999999999,"iat":1706054400,"iss":"edugo-mobile"}
    let validToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NTBlODQwMCIsImVtYWlsIjoidGVzdEBlZHVnby5jb20iLCJyb2xlIjoic3R1ZGVudCIsImV4cCI6OTk5OTk5OTk5OSwiaWF0IjoxNzA2MDU0NDAwLCJpc3MiOiJlZHVnby1tb2JpbGUifQ.SIGNATURE"
    
    @Test func decodeValidToken() throws {
        let payload = try decoder.decode(validToken)
        
        #expect(payload.sub == "550e8400")
        #expect(payload.email == "test@edugo.com")
        #expect(payload.role == "student")
        #expect(payload.iss == "edugo-mobile")
    }
    
    @Test func decodeInvalidFormat() {
        let invalidToken = "not.a.valid.jwt.token"
        
        #expect(throws: JWTError.self) {
            try decoder.decode(invalidToken)
        }
    }
    
    @Test func decodeInvalidBase64() {
        let invalidToken = "header.!!invalid-base64!!.signature"
        
        #expect(throws: JWTError.self) {
            try decoder.decode(invalidToken)
        }
    }
    
    @Test func payloadIsExpired() {
        let payload = JWTPayload.expired
        #expect(payload.isExpired == true)
    }
    
    @Test func payloadToDomainUser() {
        let payload = JWTPayload.fixture()
        let user = payload.toDomainUser
        
        #expect(user.id == payload.sub)
        #expect(user.email == payload.email)
        #expect(user.role.rawValue == payload.role)
    }
}
```

**Criterios de aceptación FASE 3**:
- [ ] JWTDecoder protocol creado
- [ ] DefaultJWTDecoder implementado
- [ ] Base64URL decode funcional
- [ ] MockJWTDecoder para tests
- [ ] Tests pasando (5+)
- [ ] Build exitoso

---

### FASE 4: Token Refresh Coordinator (4h)

**Objetivo**: Refresh automático con actor para evitar race conditions.

#### 4.1 TokenRefreshCoordinator (3h)

**Archivo**: `Data/Services/Auth/TokenRefreshCoordinator.swift`

```swift
import Foundation

/// Actor que coordina el refresh de tokens evitando múltiples requests concurrentes
///
/// Basado en: https://www.donnywals.com/building-a-token-refresh-flow-with-async-await-and-swift-concurrency/
actor TokenRefreshCoordinator {
    
    // MARK: - Dependencies
    
    private let apiClient: APIClient
    private let keychainService: KeychainService
    private let jwtDecoder: JWTDecoder
    private let logger = LoggerFactory.auth
    
    // MARK: - State
    
    private var refreshTask: Task<TokenInfo, Error>?
    
    // MARK: - Initialization
    
    init(
        apiClient: APIClient,
        keychainService: KeychainService,
        jwtDecoder: JWTDecoder
    ) {
        self.apiClient = apiClient
        self.keychainService = keychainService
        self.jwtDecoder = jwtDecoder
    }
    
    // MARK: - Public API
    
    /// Obtiene un token válido, refrescándolo si es necesario
    ///
    /// Esta función asegura que solo haya un refresh en progreso a la vez.
    /// Si múltiples requests concurrentes llaman a esta función, todos
    /// esperarán al mismo Task de refresh.
    ///
    /// - Returns: TokenInfo válido
    /// - Throws: AppError si no hay tokens o el refresh falla
    func getValidToken() async throws -> TokenInfo {
        logger.debug("TokenRefreshCoordinator: Getting valid token")
        
        // 1. Si hay refresh en progreso, esperar
        if let task = refreshTask {
            logger.debug("Refresh in progress, waiting...")
            return try await task.value
        }
        
        // 2. Obtener token actual
        guard let currentToken = try? getCurrentTokenInfo() else {
            logger.warning("No current token found")
            throw AppError.network(.unauthorized)
        }
        
        // 3. Si válido, retornar
        if !currentToken.needsRefresh {
            logger.debug("Current token is valid")
            return currentToken
        }
        
        // 4. Iniciar refresh
        logger.info("Token needs refresh, starting refresh flow")
        
        let task = Task {
            try await performRefresh(currentToken.refreshToken)
        }
        
        refreshTask = task
        
        defer {
            refreshTask = nil
        }
        
        return try await task.value
    }
    
    /// Fuerza un refresh inmediato
    func forceRefresh() async throws -> TokenInfo {
        logger.info("Force refresh requested")
        
        guard let currentToken = try? getCurrentTokenInfo() else {
            throw AppError.network(.unauthorized)
        }
        
        return try await performRefresh(currentToken.refreshToken)
    }
    
    // MARK: - Private Methods
    
    private func getCurrentTokenInfo() throws -> TokenInfo {
        // 1. Leer tokens de Keychain
        guard let accessToken = try keychainService.getToken(for: "access_token") else {
            throw AppError.network(.unauthorized)
        }
        
        guard let refreshToken = try keychainService.getToken(for: "refresh_token") else {
            throw AppError.network(.unauthorized)
        }
        
        // 2. Decodificar JWT para obtener expiración
        let payload = try jwtDecoder.decode(accessToken)
        
        return TokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: payload.exp
        )
    }
    
    private func performRefresh(_ refreshToken: String) async throws -> TokenInfo {
        logger.debug("Performing token refresh")
        
        do {
            // 1. Llamar API de refresh
            let response: RefreshResponse = try await apiClient.execute(
                endpoint: .refresh,
                method: .post,
                body: RefreshRequest(refreshToken: refreshToken)
            )
            
            // 2. Actualizar TokenInfo
            let newTokenInfo = TokenInfo(
                accessToken: response.accessToken,
                refreshToken: refreshToken, // NO cambia en API real
                expiresIn: response.expiresIn
            )
            
            // 3. Guardar en Keychain
            try keychainService.saveToken(newTokenInfo.accessToken, for: "access_token")
            
            logger.info("Token refresh successful")
            logger.logToken(newTokenInfo.accessToken, label: "NewAccessToken")
            
            return newTokenInfo
            
        } catch {
            logger.error("Token refresh failed", metadata: [
                "error": error.localizedDescription
            ])
            
            // Limpiar tokens si refresh falla
            try? keychainService.deleteToken(for: "access_token")
            try? keychainService.deleteToken(for: "refresh_token")
            
            throw AppError.network(.unauthorized)
        }
    }
}

// MARK: - Testing

#if DEBUG
actor MockTokenRefreshCoordinator {
    var tokenToReturn: TokenInfo?
    var errorToThrow: Error?
    var getValidTokenCallCount = 0
    
    func getValidToken() async throws -> TokenInfo {
        getValidTokenCallCount += 1
        
        if let error = errorToThrow {
            throw error
        }
        
        return tokenToReturn ?? .fixture()
    }
    
    func forceRefresh() async throws -> TokenInfo {
        try await getValidToken()
    }
}
#endif
```

---

#### 4.2 Tests (1h)

**Archivo**: `apple-appTests/Data/Services/TokenRefreshCoordinatorTests.swift`

```swift
import Testing
@testable import apple_app

@Suite("Token Refresh Coordinator Tests")
struct TokenRefreshCoordinatorTests {
    
    @Test func getValidTokenWhenFresh() async throws {
        // Given: Token válido que no necesita refresh
        let mockKeychain = MockKeychainService()
        let mockDecoder = MockJWTDecoder()
        let mockAPI = MockAPIClient()
        
        let freshPayload = JWTPayload.fixture() // Expira en 15 min
        mockDecoder.payloadToReturn = freshPayload
        
        mockKeychain.tokens = [
            "access_token": "valid_token",
            "refresh_token": "refresh_123"
        ]
        
        let coordinator = TokenRefreshCoordinator(
            apiClient: mockAPI,
            keychainService: mockKeychain,
            jwtDecoder: mockDecoder
        )
        
        // When
        let token = try await coordinator.getValidToken()
        
        // Then
        #expect(token.accessToken == "valid_token")
        #expect(mockAPI.executeCallCount == 0) // No llamó API
    }
    
    @Test func getValidTokenTriggersRefresh() async throws {
        // Given: Token que necesita refresh
        let mockKeychain = MockKeychainService()
        let mockDecoder = MockJWTDecoder()
        let mockAPI = MockAPIClient()
        
        // Payload que expira en 2 minutos (necesita refresh)
        let expiringPayload = JWTPayload(
            sub: "123",
            email: "test@test.com",
            role: "student",
            exp: Date().addingTimeInterval(120),
            iat: Date(),
            iss: "edugo-mobile"
        )
        mockDecoder.payloadToReturn = expiringPayload
        
        mockKeychain.tokens = [
            "access_token": "expiring_token",
            "refresh_token": "refresh_123"
        ]
        
        mockAPI.mockResponse = RefreshResponse(
            accessToken: "new_token",
            expiresIn: 900,
            tokenType: "Bearer"
        )
        
        let coordinator = TokenRefreshCoordinator(
            apiClient: mockAPI,
            keychainService: mockKeychain,
            jwtDecoder: mockDecoder
        )
        
        // When
        let token = try await coordinator.getValidToken()
        
        // Then
        #expect(token.accessToken == "new_token")
        #expect(mockAPI.executeCallCount == 1)
        #expect(mockKeychain.tokens["access_token"] == "new_token")
    }
    
    @Test func concurrentRefreshesUsesSameTask() async throws {
        // Given: Token que necesita refresh
        let mockKeychain = MockKeychainService()
        let mockDecoder = MockJWTDecoder()
        let mockAPI = MockAPIClient()
        
        // Simular delay en API
        mockAPI.delay = 1.0
        
        let expiringPayload = JWTPayload(
            sub: "123",
            email: "test@test.com",
            role: "student",
            exp: Date().addingTimeInterval(120),
            iat: Date(),
            iss: "edugo-mobile"
        )
        mockDecoder.payloadToReturn = expiringPayload
        
        mockKeychain.tokens = [
            "access_token": "expiring_token",
            "refresh_token": "refresh_123"
        ]
        
        mockAPI.mockResponse = RefreshResponse(
            accessToken: "new_token",
            expiresIn: 900,
            tokenType: "Bearer"
        )
        
        let coordinator = TokenRefreshCoordinator(
            apiClient: mockAPI,
            keychainService: mockKeychain,
            jwtDecoder: mockDecoder
        )
        
        // When: 3 requests concurrentes
        async let token1 = coordinator.getValidToken()
        async let token2 = coordinator.getValidToken()
        async let token3 = coordinator.getValidToken()
        
        let tokens = try await [token1, token2, token3]
        
        // Then: Solo 1 llamada al API
        #expect(mockAPI.executeCallCount == 1)
        #expect(tokens.allSatisfy { $0.accessToken == "new_token" })
    }
}
```

**Criterios de aceptación FASE 4**:
- [ ] TokenRefreshCoordinator implementado (actor)
- [ ] Evita múltiples refreshes concurrentes
- [ ] Integra con Keychain y JWTDecoder
- [ ] Tests pasando (3+)
- [ ] Build exitoso

---

### FASE 5: Biometric Authentication (3h)

**Objetivo**: Implementar Face ID / Touch ID.

#### 5.1 BiometricAuthService (2h)

**Archivo**: `Data/Services/Auth/BiometricAuthService.swift`

```swift
import LocalAuthentication
import Foundation

// MARK: - Protocol

protocol BiometricAuthService: Sendable {
    var isAvailable: Bool { get async }
    var biometryType: LABiometryType { get async }
    func authenticate(reason: String) async throws -> Bool
}

// MARK: - Errors

enum BiometricError: Error, LocalizedError {
    case notAvailable
    case authenticationFailed
    case userCancelled
    case biometryLocked
    case biometryNotEnrolled
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Autenticación biométrica no disponible"
        case .authenticationFailed:
            return "Autenticación falló"
        case .userCancelled:
            return "Usuario canceló la autenticación"
        case .biometryLocked:
            return "Biometría bloqueada (demasiados intentos)"
        case .biometryNotEnrolled:
            return "No hay Face ID / Touch ID configurado"
        }
    }
}

// MARK: - Implementation

final class LocalAuthenticationService: BiometricAuthService, @unchecked Sendable {
    private let logger = LoggerFactory.auth
    
    var isAvailable: Bool {
        get async {
            let context = LAContext()
            var error: NSError?
            let canEvaluate = context.canEvaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                error: &error
            )
            
            if let error = error {
                logger.debug("Biometric not available", metadata: [
                    "error": error.localizedDescription
                ])
            }
            
            return canEvaluate
        }
    }
    
    var biometryType: LABiometryType {
        get async {
            let context = LAContext()
            _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            return context.biometryType
        }
    }
    
    func authenticate(reason: String) async throws -> Bool {
        logger.info("Biometric authentication requested")
        
        let context = LAContext()
        context.localizedCancelTitle = "Cancelar"
        context.localizedFallbackTitle = "Usar contraseña"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                logger.info("Biometric authentication succeeded")
            }
            
            return success
            
        } catch let error as LAError {
            logger.error("Biometric authentication failed", metadata: [
                "error": error.localizedDescription,
                "code": error.code.rawValue.description
            ])
            
            throw mapLAError(error)
        }
    }
    
    // MARK: - Error Mapping
    
    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .userCancel:
            return .userCancelled
        case .biometryLockout:
            return .biometryLocked
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .biometryNotAvailable:
            return .notAvailable
        default:
            return .authenticationFailed
        }
    }
}

// MARK: - Testing

#if DEBUG
final class MockBiometricService: BiometricAuthService {
    var isAvailableValue = true
    var biometryTypeValue: LABiometryType = .faceID
    var authenticateResult: Bool = true
    var authenticateError: Error?
    var authenticateCallCount = 0
    
    var isAvailable: Bool {
        get async { isAvailableValue }
    }
    
    var biometryType: LABiometryType {
        get async { biometryTypeValue }
    }
    
    func authenticate(reason: String) async throws -> Bool {
        authenticateCallCount += 1
        
        if let error = authenticateError {
            throw error
        }
        
        return authenticateResult
    }
}
#endif
```

---

#### 5.2 Tests (1h)

**Archivo**: `apple-appTests/Data/Services/BiometricAuthServiceTests.swift`

```swift
import Testing
@testable import apple_app

@Suite("Biometric Auth Service Tests")
struct BiometricAuthServiceTests {
    
    @Test func mockBiometricSuccess() async throws {
        let mock = MockBiometricService()
        mock.authenticateResult = true
        
        let result = try await mock.authenticate(reason: "Login")
        
        #expect(result == true)
        #expect(mock.authenticateCallCount == 1)
    }
    
    @Test func mockBiometricFailure() async throws {
        let mock = MockBiometricService()
        mock.authenticateError = BiometricError.authenticationFailed
        
        #expect(throws: BiometricError.self) {
            try await mock.authenticate(reason: "Login")
        }
    }
    
    @Test func mockBiometricAvailability() async {
        let mock = MockBiometricService()
        mock.isAvailableValue = false
        
        let available = await mock.isAvailable
        
        #expect(available == false)
    }
}
```

**Nota**: Tests de `LocalAuthenticationService` real requieren dispositivo físico.

**Criterios de aceptación FASE 5**:
- [ ] BiometricAuthService protocol creado
- [ ] LocalAuthenticationService implementado
- [ ] Maneja todos los errores de LAError
- [ ] MockBiometricService para tests
- [ ] Tests pasando (3+)
- [ ] Build exitoso

---

### FASE 6: AuthRepositoryImpl Update (4h)

**Objetivo**: Actualizar repositorio para usar API real y nuevos servicios.

#### 6.1 Actualizar AuthRepositoryImpl (3h)

**Archivo**: `Data/Repositories/AuthRepositoryImpl.swift`

**Cambios principales**:

1. Agregar nuevas dependencias
2. Implementar feature flag
3. Actualizar login para API real
4. Actualizar refresh para usar TokenRefreshCoordinator
5. Implementar logout con API
6. Implementar loginWithBiometrics
7. Implementar getTokenInfo

**Código** (ver implementación completa en archivo separado por extensión).

---

#### 6.2 Tests Actualizados (1h)

**Archivo**: `apple-appTests/Data/Repositories/AuthRepositoryImplTests.swift`

**Tests a agregar**:

```swift
@Test func loginWithRealAPI() async throws {
    // Given
    let mockAPI = MockAPIClient()
    mockAPI.mockResponse = LoginResponse(
        accessToken: "token",
        refreshToken: "refresh",
        expiresIn: 900,
        tokenType: "Bearer",
        user: UserDTO.fixture()
    )
    
    let mockJWT = MockJWTDecoder()
    mockJWT.payloadToReturn = JWTPayload.fixture()
    
    let repo = AuthRepositoryImpl(
        apiClient: mockAPI,
        jwtDecoder: mockJWT,
        authMode: .realAPI
    )
    
    // When
    let result = await repo.login(email: "test@test.com", password: "123")
    
    // Then
    guard case .success(let user) = result else {
        Issue.record("Expected success")
        return
    }
    
    #expect(user.email == "test@edugo.com")
}

@Test func loginWithBiometricsSuccess() async throws {
    // Given
    let mockBiometric = MockBiometricService()
    mockBiometric.authenticateResult = true
    
    let mockKeychain = MockKeychainService()
    mockKeychain.tokens = [
        "stored_email": "test@test.com",
        "stored_password": "password123"
    ]
    
    // ... configurar mock API, etc
    
    let repo = AuthRepositoryImpl(
        biometricService: mockBiometric,
        // ...
    )
    
    // When
    let result = await repo.loginWithBiometrics()
    
    // Then
    guard case .success = result else {
        Issue.record("Expected success")
        return
    }
    
    #expect(mockBiometric.authenticateCallCount == 1)
}

@Test func logoutCallsAPI() async throws {
    // Given
    let mockAPI = MockAPIClient()
    let mockKeychain = MockKeychainService()
    mockKeychain.tokens = [
        "access_token": "token",
        "refresh_token": "refresh"
    ]
    
    let repo = AuthRepositoryImpl(
        apiClient: mockAPI,
        keychainService: mockKeychain,
        authMode: .realAPI
    )
    
    // When
    let result = await repo.logout()
    
    // Then
    guard case .success = result else {
        Issue.record("Expected success")
        return
    }
    
    // Verificar que llamó logout endpoint
    #expect(mockAPI.lastEndpoint == .logout)
    
    // Verificar que eliminó tokens
    #expect(mockKeychain.tokens["access_token"] == nil)
    #expect(mockKeychain.tokens["refresh_token"] == nil)
}
```

**Criterios de aceptación FASE 6**:
- [ ] AuthRepositoryImpl actualizado
- [ ] Feature flag implementado
- [ ] Todos los métodos actualizados
- [ ] loginWithBiometrics implementado
- [ ] Tests actualizados (10+)
- [ ] Build exitoso

---

### FASE 7: Endpoints & Environment (2h)

**Objetivo**: Actualizar endpoints y configuración de ambientes.

#### 7.1 Update Endpoint.swift (30 min)

**Archivo**: `Data/Network/Endpoint.swift`

```swift
enum Endpoint: Sendable {
    case login
    case logout
    case refresh
    case currentUser
    
    // MARK: - Path
    
    var path: String {
        let basePath: String
        
        switch AppEnvironment.authMode {
        case .dummyJSON:
            basePath = "/auth"
        case .realAPI:
            basePath = "/v1/auth"
        }
        
        switch self {
        case .login:
            return "\(basePath)/login"
        case .logout:
            return "\(basePath)/logout"
        case .refresh:
            return "\(basePath)/refresh"
        case .currentUser:
            return "\(basePath)/me"
        }
    }
    
    // MARK: - Full URL
    
    func url(baseURL: URL) -> URL {
        switch AppEnvironment.authMode {
        case .dummyJSON:
            // DummyJSON tiene su propia base URL
            return URL(string: "https://dummyjson.com\(path)")!
        case .realAPI:
            // Usar baseURL del environment
            return baseURL.appendingPathComponent(path)
        }
    }
}
```

---

#### 7.2 Update Environment.swift (1h)

**Archivo**: `App/Environment.swift`

```swift
// AGREGAR
enum AuthenticationMode {
    case dummyJSON  // Para desarrollo/testing
    case realAPI    // Para staging/production
}

extension AppEnvironment {
    /// Modo de autenticación (DummyJSON vs Real API)
    static var authMode: AuthenticationMode {
        // Leer de .xcconfig (opcional)
        if let modeString = infoDictionary["AUTH_MODE"] as? String {
            return modeString.lowercased() == "real" ? .realAPI : .dummyJSON
        }
        
        // Fallback: DummyJSON en debug, Real en producción
        #if DEBUG
        return .dummyJSON
        #else
        return .realAPI
        #endif
    }
}
```

---

#### 7.3 Update .xcconfig Files (30 min)

**Archivo**: `Configs/Development.xcconfig`

```ini
#include "Base.xcconfig"

// Environment
ENVIRONMENT_NAME = Development

// API Configuration
API_BASE_URL = http:/$()/localhost:8080
AUTH_MODE = dummy  // O "real" para testing local

// ... resto igual
```

**Archivo**: `Configs/Staging.xcconfig`

```ini
#include "Base.xcconfig"

// Environment
ENVIRONMENT_NAME = Staging

// API Configuration
API_BASE_URL = https:/$()/api-staging.edugo.com
AUTH_MODE = real  // Siempre real en staging

// ... resto igual
```

**Archivo**: `Configs/Production.xcconfig`

```ini
#include "Base.xcconfig"

// Environment
ENVIRONMENT_NAME = Production

// API Configuration
API_BASE_URL = https:/$()/api.edugo.com
AUTH_MODE = real  // Siempre real en producción

// ... resto igual
```

**Criterios de aceptación FASE 7**:
- [ ] Endpoint.swift actualizado con versionado
- [ ] Environment.swift con authMode
- [ ] .xcconfig files actualizados
- [ ] Build exitoso en 3 schemes
- [ ] Paths correctos según modo

---

### FASE 8: Auth Interceptor (3h)

**Objetivo**: Auto-inyectar tokens en requests.

#### 8.1 RequestInterceptor Protocol (30 min)

**Archivo**: `Data/Network/Interceptors/RequestInterceptor.swift`

```swift
import Foundation

/// Protocol para interceptar y modificar requests HTTP
protocol RequestInterceptor: Sendable {
    func intercept(_ request: URLRequest) async throws -> URLRequest
}
```

---

#### 8.2 AuthInterceptor Implementation (2h)

**Archivo**: `Data/Network/Interceptors/AuthInterceptor.swift`

```swift
import Foundation

final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {
    
    // MARK: - Dependencies
    
    private let tokenCoordinator: TokenRefreshCoordinator
    private let logger = LoggerFactory.auth
    
    // MARK: - Initialization
    
    init(tokenCoordinator: TokenRefreshCoordinator) {
        self.tokenCoordinator = tokenCoordinator
    }
    
    // MARK: - RequestInterceptor
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        // 1. Verificar si necesita auth
        guard requiresAuth(request) else {
            return request
        }
        
        logger.debug("Intercepting request for authentication")
        
        // 2. Obtener token válido (auto-refresh si necesita)
        let tokenInfo = try await tokenCoordinator.getValidToken()
        
        // 3. Inyectar en header
        var mutableRequest = request
        mutableRequest.setValue(
            "Bearer \(tokenInfo.accessToken)",
            forHTTPHeaderField: "Authorization"
        )
        
        logger.debug("Token injected in request")
        
        return mutableRequest
    }
    
    // MARK: - Private Methods
    
    private func requiresAuth(_ request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        
        let path = url.path
        
        // Endpoints que NO requieren auth
        let publicPaths = [
            "/auth/login",
            "/v1/auth/login",
            "/auth/refresh",
            "/v1/auth/refresh"
        ]
        
        return !publicPaths.contains(where: { path.contains($0) })
    }
}

// MARK: - Testing

#if DEBUG
final class MockAuthInterceptor: RequestInterceptor {
    var interceptCallCount = 0
    var tokenToInject: String?
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        interceptCallCount += 1
        
        guard let token = tokenToInject else {
            return request
        }
        
        var mutableRequest = request
        mutableRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return mutableRequest
    }
}
#endif
```

---

#### 8.3 Integrate with APIClient (30 min)

**Archivo**: `Data/Network/APIClient.swift`

```swift
// MODIFICAR execute() para usar interceptor

// ANTES
func execute<T: Decodable, U: Encodable>(
    endpoint: Endpoint,
    method: HTTPMethod,
    body: U?
) async throws -> T {
    var request = createRequest(endpoint: endpoint, method: method, body: body)
    
    // ❌ Hardcoded token injection
    if let token = try? keychainService.getToken(for: "access_token") {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    // ... resto
}

// DESPUÉS
private let interceptor: RequestInterceptor?

func execute<T: Decodable, U: Encodable>(
    endpoint: Endpoint,
    method: HTTPMethod,
    body: U?
) async throws -> T {
    var request = createRequest(endpoint: endpoint, method: method, body: body)
    
    // ✅ Usar interceptor
    if let interceptor = interceptor {
        request = try await interceptor.intercept(request)
    }
    
    // ... resto
}
```

**Criterios de aceptación FASE 8**:
- [ ] RequestInterceptor protocol creado
- [ ] AuthInterceptor implementado
- [ ] Integrado con TokenRefreshCoordinator
- [ ] APIClient usa interceptor
- [ ] Tests pasando
- [ ] Build exitoso

---

### FASE 9: Dependency Injection (2h)

**Objetivo**: Registrar todos los nuevos servicios en DI container.

#### 9.1 Update DependencyContainer (1h)

**Archivo**: `Core/DI/DependencyContainer.swift`

```swift
// AGREGAR registros

// MARK: - Auth Services (SPEC-003)

container.register(JWTDecoder.self, scope: .singleton) { _ in
    DefaultJWTDecoder()
}

container.register(BiometricAuthService.self, scope: .singleton) { _ in
    LocalAuthenticationService()
}

container.register(TokenRefreshCoordinator.self, scope: .singleton) { container in
    TokenRefreshCoordinator(
        apiClient: container.resolve(APIClient.self),
        keychainService: container.resolve(KeychainService.self),
        jwtDecoder: container.resolve(JWTDecoder.self)
    )
}

container.register(RequestInterceptor.self, scope: .singleton) { container in
    AuthInterceptor(
        tokenCoordinator: container.resolve(TokenRefreshCoordinator.self)
    )
}

// MARK: - Update APIClient

container.register(APIClient.self, scope: .singleton) { container in
    DefaultAPIClient(
        baseURL: AppEnvironment.apiBaseURL,
        timeout: AppEnvironment.apiTimeout,
        interceptor: container.resolve(RequestInterceptor.self)
    )
}

// MARK: - Update AuthRepository

container.register(AuthRepository.self, scope: .singleton) { container in
    AuthRepositoryImpl(
        apiClient: container.resolve(APIClient.self),
        keychainService: container.resolve(KeychainService.self),
        jwtDecoder: container.resolve(JWTDecoder.self),
        tokenCoordinator: container.resolve(TokenRefreshCoordinator.self),
        biometricService: container.resolve(BiometricAuthService.self)
    )
}
```

---

#### 9.2 Update Use Cases (1h)

**Archivo**: `Domain/UseCases/Auth/LoginUseCase.swift`

```swift
// AGREGAR nuevo método

protocol LoginUseCase: Sendable {
    func execute(email: String, password: String) async -> Result<User, AppError>
    func executeWithBiometrics() async -> Result<User, AppError>  // NUEVO
}

final class DefaultLoginUseCase: LoginUseCase {
    // ...
    
    func executeWithBiometrics() async -> Result<User, AppError> {
        logger.info("Biometric login attempt")
        return await authRepository.loginWithBiometrics()
    }
}
```

**Criterios de aceptación FASE 9**:
- [ ] Todos los servicios registrados en DI
- [ ] APIClient actualizado con interceptor
- [ ] AuthRepository con todas las dependencias
- [ ] LoginUseCase con biometric support
- [ ] Build exitoso

---

### FASE 10: Testing & Integration (4h)

**Objetivo**: Tests end-to-end y verificación de integración.

#### 10.1 Integration Tests (2h)

**Archivo**: `apple-appTests/Integration/AuthFlowTests.swift`

```swift
import Testing
@testable import apple_app

@Suite("Auth Flow Integration Tests")
struct AuthFlowIntegrationTests {
    
    @Test func fullLoginFlowWithRealAPI() async throws {
        // Given: Container con mocks
        let container = TestDependencyContainer()
        
        let mockAPI = MockAPIClient()
        mockAPI.mockResponse = LoginResponse.fixture()
        
        let mockJWT = MockJWTDecoder()
        mockJWT.payloadToReturn = JWTPayload.fixture()
        
        container.register(APIClient.self, mock: mockAPI)
        container.register(JWTDecoder.self, mock: mockJWT)
        
        let loginUseCase = container.resolve(LoginUseCase.self)
        
        // When: Login
        let result = await loginUseCase.execute(
            email: "test@test.com",
            password: "123"
        )
        
        // Then
        guard case .success(let user) = result else {
            Issue.record("Expected success")
            return
        }
        
        #expect(user.email == "test@edugo.com")
    }
    
    @Test func tokenRefreshFlowIntegration() async throws {
        // Given: Token expirado
        let container = TestDependencyContainer()
        
        let mockKeychain = MockKeychainService()
        mockKeychain.tokens = [
            "access_token": "expired_token",
            "refresh_token": "refresh_123"
        ]
        
        let mockJWT = MockJWTDecoder()
        mockJWT.payloadToReturn = JWTPayload(
            sub: "123",
            email: "test@test.com",
            role: "student",
            exp: Date().addingTimeInterval(120), // Expira en 2 min
            iat: Date(),
            iss: "edugo-mobile"
        )
        
        let mockAPI = MockAPIClient()
        mockAPI.mockResponse = RefreshResponse.fixture()
        
        container.register(KeychainService.self, mock: mockKeychain)
        container.register(JWTDecoder.self, mock: mockJWT)
        container.register(APIClient.self, mock: mockAPI)
        
        let coordinator = container.resolve(TokenRefreshCoordinator.self)
        
        // When: Obtener token válido
        let token = try await coordinator.getValidToken()
        
        // Then: Debe haber refrescado
        #expect(token.accessToken == "new_access_token")
        #expect(mockAPI.executeCallCount == 1)
    }
}
```

---

#### 10.2 Manual Testing Checklist (2h)

**Checklist**:

- [ ] **Login con DummyJSON**
  - [ ] Login exitoso con `emilys`/`emilyspass`
  - [ ] Token guardado en Keychain
  - [ ] Navegación a HomeView

- [ ] **Login con API Real** (si backend está corriendo)
  - [ ] Login exitoso con credenciales reales
  - [ ] JWT decodificado correctamente
  - [ ] User info correcta

- [ ] **Token Refresh**
  - [ ] Simular token expirado
  - [ ] Refresh automático funciona
  - [ ] Request original se reintenta

- [ ] **Biometric Auth** (en dispositivo físico)
  - [ ] Face ID / Touch ID se activa
  - [ ] Login exitoso tras autenticación
  - [ ] Fallback a password funciona

- [ ] **Logout**
  - [ ] Logout con DummyJSON (solo local)
  - [ ] Logout con API Real (llama endpoint)
  - [ ] Tokens eliminados de Keychain
  - [ ] Navegación a LoginView

- [ ] **Feature Flag**
  - [ ] Cambiar entre DummyJSON/Real
  - [ ] Build exitoso en ambos modos
  - [ ] Funcionalidad correcta en ambos

**Criterios de aceptación FASE 10**:
- [ ] Integration tests pasando (5+)
- [ ] Manual testing completado
- [ ] Zero crashes
- [ ] Builds exitosos en 3 schemes

---

### FASE 11: Documentación (2h)

**Objetivo**: Documentar cambios y crear guías.

#### 11.1 Crear SPEC-003-COMPLETADO.md

**Archivo**: `docs/specs/authentication-migration/SPEC-003-COMPLETADO.md`

**Contenido**:
- Resumen de cambios
- Nuevos componentes creados
- Guía de uso
- Troubleshooting
- Migration guide

---

#### 11.2 Actualizar README.md

**Archivo**: `README.md`

**Agregar sección**:

```markdown
## 🔐 Autenticación

### API Backend

Soporta dos modos:

1. **DummyJSON** (desarrollo): https://dummyjson.com
2. **API Real** (staging/prod): Configurado en .xcconfig

### Feature Flag

Cambiar en `Configs/*.xcconfig`:

```ini
AUTH_MODE = dummy  # O "real"
```

### Biometric Login

Face ID / Touch ID habilitado automáticamente si:

- Dispositivo lo soporta
- Usuario tiene credenciales guardadas
- Primera autenticación exitosa

### Testing

```bash
# Login con DummyJSON
Username: emilys
Password: emilyspass

# Login con API Real
Email: <tu-email>
Password: <tu-password>
```
```

---

#### 11.3 Crear Migration Guide

**Archivo**: `docs/guides/auth-migration-guide.md`

**Para otros desarrolladores**:

1. Pull latest dev
2. Update Configs/*.xcconfig
3. Levantar API backend (opcional)
4. Build y probar

**Criterios de aceptación FASE 11**:
- [ ] SPEC-003-COMPLETADO.md creado
- [ ] README.md actualizado
- [ ] Migration guide creado
- [ ] Troubleshooting documentado

---

## 📊 Resumen de Estimaciones

| Fase | Descripción | Estimación |
|------|-------------|------------|
| 0 | Preparación | 1h |
| 1 | Domain Layer | 3h |
| 2 | DTOs | 4h |
| 3 | JWT Decoder | 3h |
| 4 | Token Refresh Coordinator | 4h |
| 5 | Biometric Auth | 3h |
| 6 | AuthRepositoryImpl Update | 4h |
| 7 | Endpoints & Environment | 2h |
| 8 | Auth Interceptor | 3h |
| 9 | Dependency Injection | 2h |
| 10 | Testing & Integration | 4h |
| 11 | Documentación | 2h |
| **TOTAL** | | **35h** |

**Ajustado**: 28-32 horas (3-4 días)

---

## ✅ Criterios de Éxito Final

### Funcionales

- [ ] Login con API Real funcional
- [ ] JWT decoder local implementado
- [ ] Token refresh automático
- [ ] Biometric auth funcional
- [ ] Feature flag DummyJSON/Real
- [ ] Logout con revocación servidor

### Técnicos

- [ ] Zero configuración manual Xcode
- [ ] Tests 100% pasando (50+)
- [ ] Builds exitosos en 3 schemes
- [ ] Zero crashes
- [ ] Logging profesional integrado
- [ ] Documentación completa

### Performance

- [ ] JWT decode < 10ms
- [ ] Token refresh < 500ms
- [ ] Biometric auth < 2s
- [ ] Zero race conditions

---

## 🚀 Estrategia de Rollout

### Fase Alpha (Desarrollo)

- Feature flag = DummyJSON
- Testing local con API real opcional
- Iteración rápida

### Fase Beta (Staging)

- Feature flag = Real API
- Testing con backend real
- Validar todos los flujos

### Fase Production

- Feature flag = Real API
- Monitoreo de errores
- Rollback a DummyJSON si necesario

---

## 📝 Commits Recomendados

```bash
# Fase 1
git commit -m "feat(auth): add TokenInfo and UserRole models (SPEC-003 Phase 1)"

# Fase 2
git commit -m "feat(auth): add DTOs for real API integration (SPEC-003 Phase 2)"

# Fase 3
git commit -m "feat(auth): implement JWT decoder (SPEC-003 Phase 3)"

# Fase 4
git commit -m "feat(auth): add TokenRefreshCoordinator actor (SPEC-003 Phase 4)"

# Fase 5
git commit -m "feat(auth): implement biometric authentication (SPEC-003 Phase 5)"

# Fase 6
git commit -m "feat(auth): update AuthRepositoryImpl for real API (SPEC-003 Phase 6)"

# Fase 7
git commit -m "feat(auth): add endpoints and feature flag (SPEC-003 Phase 7)"

# Fase 8
git commit -m "feat(auth): implement AuthInterceptor (SPEC-003 Phase 8)"

# Fase 9
git commit -m "feat(auth): update DI container (SPEC-003 Phase 9)"

# Fase 10
git commit -m "test(auth): add integration tests (SPEC-003 Phase 10)"

# Fase 11
git commit -m "docs(auth): add SPEC-003 documentation (SPEC-003 Phase 11)"
```

---

## 🎯 Próximos Pasos

Después de completar SPEC-003:

1. **Crear branch**: `git checkout -b feat/auth-real-api`
2. **Ejecutar fases secuencialmente**
3. **Commitear atómicamente**
4. **Crear PR a `dev`**
5. **Merge y celebrar** 🎉

---

**Estado**: ✅ PLAN LISTO PARA EJECUTAR  
**Tipo**: 🤖 100% AUTOMATIZADO  
**Bloqueantes**: NINGUNO  
**Riesgo**: BAJO
