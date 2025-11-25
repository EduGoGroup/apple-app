# Análisis de Requerimiento: Authentication - Real API Migration

**Fecha**: 2025-11-23  
**Versión**: 1.0  
**Estado**: 📋 Propuesta  
**Prioridad**: 🟠 P1 - ALTA  
**Autor**: Cascade AI  
**Dependencias**: SPEC-001, SPEC-002

---

## 📋 Resumen Ejecutivo

Migrar `AuthRepositoryImpl` desde DummyJSON a API real con JWT validation local, token refresh automático via interceptor, y biometric authentication.

---

## 🎯 Objetivo

- JWT validation y decoding local
- Token refresh automático (sin múltiples requests concurrentes)
- Request interceptor para auto-inject tokens
- Biometric authentication (Face ID / Touch ID)
- Feature flag para toggle DummyJSON/RealAPI

---

## 🔍 Problemática Actual

### 1. DummyJSON en Producción

**Archivo**: `Data/Repositories/AuthRepositoryImpl.swift`

```swift
let response: LoginResponse = try await apiClient.execute(
    endpoint: .login,  // ❌ va a https://dummyjson.com
    method: .post,
    body: request
)
```

**Problemas**:
- ❌ No es API real
- ❌ No valida JWT localmente
- ❌ Refresh manual (no automático)
- ❌ No hay biometric auth

---

### 2. Token Injection Manual

**Archivo**: `Data/Network/APIClient.swift` (líneas 60-62)

```swift
// Agregar token de autenticación si existe
if let token = try? DefaultKeychainService.shared.getToken(for: "access_token") {
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
}
```

**Problemas**:
- ❌ Hardcoded en APIClient
- ❌ No verifica si token expiró
- ❌ No refresh automático
- ❌ Uso directo de DefaultKeychainService (tight coupling)

---

### 3. No Hay JWT Validation Local

**Problema**: App no valida JWT localmente

```swift
// ❌ No valida expiración
try keychainService.saveToken(response.accessToken, for: accessTokenKey)
```

**Impacto**:
- ❌ Requests con tokens expirados
- ❌ 401 errors innecesarios
- ❌ Mala UX

---

### 4. Refresh Manual

**Problema**: Refresh se llama manualmente

```swift
func refreshSession() async -> Result<User, AppError> {
    // Usuario debe llamar esto explícitamente
}
```

**Debería ser**:
- ✅ Automático cuando token expira
- ✅ Transparente para el usuario
- ✅ Sin múltiples refreshes concurrentes

---

## 💼 Casos de Uso

### CU-001: Login con API Real

**Actor**: Usuario  
**Flujo**:
1. Usuario ingresa email/password
2. App envía POST /auth/login
3. Backend valida y retorna JWT + refresh token
4. App decodifica JWT localmente
5. App guarda tokens en Keychain
6. App navega a home

**Resultado**: Login exitoso con tokens válidos

---

### CU-002: Auto-refresh de Token

**Actor**: Sistema  
**Escenario**: Token está por expirar  

**Flujo**:
1. APIClient detecta token expira en < 5 min
2. TokenRefreshCoordinator inicia refresh
3. POST /auth/refresh con refresh token
4. Backend retorna nuevo access token
5. App actualiza token en Keychain
6. Request original se ejecuta con nuevo token

**Resultado**: Refresh transparente, usuario no se entera

---

### CU-003: Biometric Login

**Actor**: Usuario recurrente  
**Flujo**:
1. App muestra "Login con Face ID"
2. Usuario aprueba Face ID
3. App lee credentials de Keychain
4. Auto-login sin pedir password

**Resultado**: Login rápido y seguro

---

## 📊 Requerimientos Funcionales

### RF-001: Real API Contract

| Endpoint | Method | Request | Response |
|----------|--------|---------|----------|
| `/auth/login` | POST | `{email, password}` | `{accessToken, refreshToken, user}` |
| `/auth/refresh` | POST | `{refreshToken}` | `{accessToken}` |
| `/auth/me` | GET | Header: `Authorization` | `{user}` |
| `/auth/logout` | POST | Header: `Authorization` | `{success}` |

---

### RF-002: TokenInfo Model

```swift
struct TokenInfo: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
    
    var needsRefresh: Bool {
        // Refresh si expira en < 5 minutos
        Date().addingTimeInterval(300) >= expiresAt
    }
}
```

---

### RF-003: JWT Decoder

```swift
protocol JWTDecoder: Sendable {
    func decode(_ token: String) throws -> JWTPayload
}

struct JWTPayload {
    let userId: String
    let email: String
    let expiresAt: Date
    let issuedAt: Date
}
```

---

### RF-004: Token Refresh Coordinator

```swift
actor TokenRefreshCoordinator {
    private var refreshTask: Task<TokenInfo, Error>?
    
    func refreshTokenIfNeeded() async throws -> TokenInfo {
        // Evita múltiples refreshes concurrentes
        if let task = refreshTask {
            return try await task.value
        }
        
        let task = Task {
            // Refresh logic
        }
        
        refreshTask = task
        defer { refreshTask = nil }
        
        return try await task.value
    }
}
```

**Basado en**: [Donny Wals - Token Refresh Flow](https://www.donnywals.com/building-a-token-refresh-flow-with-async-await-and-swift-concurrency/)

---

### RF-005: Auth Interceptor

```swift
final class AuthInterceptor: RequestInterceptor {
    private let tokenCoordinator: TokenRefreshCoordinator
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        // 1. Lee token de Keychain
        // 2. Valida si expiró
        // 3. Si needsRefresh, llama coordinator
        // 4. Inyecta token en header
        var mutableRequest = request
        mutableRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return mutableRequest
    }
}
```

---

### RF-006: Biometric Authentication

```swift
protocol BiometricAuthService: Sendable {
    var isAvailable: Bool { get }
    var biometryType: BiometryType { get } // faceID, touchID, none
    
    func authenticate(reason: String) async throws -> Bool
}

final class LocalAuthenticationService: BiometricAuthService {
    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
    }
}
```

---

### RF-007: Feature Flag

```swift
enum AuthenticationMode {
    case dummyJSON  // Para desarrollo/testing
    case realAPI    // Para staging/production
}

// En Environment.swift
static var authMode: AuthenticationMode {
    #if DEBUG
    return .dummyJSON
    #else
    return .realAPI
    #endif
}
```

---

## 📊 Requerimientos No Funcionales

### RNF-001: Performance
- Token refresh < 500ms
- JWT decode < 10ms
- Biometric auth < 2s

### RNF-002: Security
- JWT validation local (no confiar ciegamente)
- Biometric en Secure Enclave
- Tokens solo en Keychain
- No loggear tokens completos

### RNF-003: UX
- Refresh transparente (sin interrumpir)
- Biometric como opción (no forzar)
- Fallback a password si biometric falla

### RNF-004: Testing
- Feature flag para toggle APIs
- Mock JWTDecoder
- Mock BiometricService
- Integration tests con DummyJSON

---

## 🎯 Criterios de Aceptación

### ✅ CA-001: API Integration
- [ ] POST /auth/login implementado
- [ ] POST /auth/refresh implementado
- [ ] GET /auth/me implementado
- [ ] POST /auth/logout implementado
- [ ] Feature flag DummyJSON/RealAPI

### ✅ CA-002: JWT Handling
- [ ] TokenInfo model con expiresAt
- [ ] JWTDecoder funcional
- [ ] Validación local de expiración
- [ ] Tests de JWT parsing

### ✅ CA-003: Auto-refresh
- [ ] TokenRefreshCoordinator (actor)
- [ ] AuthInterceptor auto-inject
- [ ] Sin múltiples refreshes concurrentes
- [ ] Tests de concurrent refresh

### ✅ CA-004: Biometric Auth
- [ ] BiometricAuthService implementado
- [ ] Face ID / Touch ID functional
- [ ] Fallback a password
- [ ] Tests con mock

---

## 📚 Referencias

### Industry Standards
- [JWT.io - Introduction to JWT](https://jwt.io/introduction)
- [RFC 7519 - JSON Web Token](https://tools.ietf.org/html/rfc7519)
- [OAuth 2.0 Token Refresh](https://oauth.net/2/grant-types/refresh-token/)

### Swift Implementation
- [Donny Wals - Token Refresh with async/await](https://www.donnywals.com/building-a-token-refresh-flow-with-async-await-and-swift-concurrency/)
- [Apple - Local Authentication](https://developer.apple.com/documentation/localauthentication)

---

**Próximos Pasos**: Ver [02-analisis-diseno.md](02-analisis-diseno.md) para diseño técnico detallado
