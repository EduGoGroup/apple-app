# Análisis de Diseño: Authentication - Real API Migration

**Fecha**: 2025-11-23  
**Versión**: 1.0  
**Estado**: 📐 Diseño Técnico  
**Prioridad**: 🟠 P1 - ALTA

---

## 🏗️ Arquitectura

```
┌────────────────────────────────────────────────┐
│         Presentation Layer                     │
│  LoginView → LoginViewModel                    │
└────────────────┬───────────────────────────────┘
                 ↓
┌────────────────────────────────────────────────┐
│         Domain Layer                           │
│  AuthRepository Protocol                       │
└────────────────┬───────────────────────────────┘
                 ↓
┌────────────────────────────────────────────────┐
│         Data Layer                             │
│  ┌──────────────────────────────────────┐     │
│  │   AuthRepositoryImpl                 │     │
│  │   - JWTDecoder                       │     │
│  │   - TokenRefreshCoordinator (actor)  │     │
│  │   - BiometricAuthService             │     │
│  └──────────────────────────────────────┘     │
│                  ↓                             │
│  ┌──────────────────────────────────────┐     │
│  │   APIClient + AuthInterceptor        │     │
│  └──────────────────────────────────────┘     │
└────────────────────────────────────────────────┘
```

---

## 🧩 Componentes Clave

### 1. TokenInfo Model

**Archivo**: `Domain/Models/Auth/TokenInfo.swift`

```swift
struct TokenInfo: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
    
    var needsRefresh: Bool {
        Date().addingTimeInterval(300) >= expiresAt
    }
}
```

---

### 2. JWTDecoder

**Archivo**: `Data/Services/Auth/JWTDecoder.swift`

```swift
protocol JWTDecoder: Sendable {
    func decode(_ token: String) throws -> JWTPayload
}

struct JWTPayload {
    let sub: String       // User ID
    let email: String
    let exp: Date         // Expiration
    let iat: Date         // Issued at
}

final class DefaultJWTDecoder: JWTDecoder {
    func decode(_ token: String) throws -> JWTPayload {
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3 else {
            throw JWTError.invalidFormat
        }
        
        let payload = segments[1]
        guard let data = base64URLDecode(payload) else {
            throw JWTError.invalidBase64
        }
        
        let json = try JSONDecoder().decode(JWTPayloadDTO.self, from: data)
        return json.toDomain()
    }
}
```

---

### 3. TokenRefreshCoordinator

**Archivo**: `Data/Services/Auth/TokenRefreshCoordinator.swift`

```swift
actor TokenRefreshCoordinator {
    private let apiClient: APIClient
    private let keychainService: KeychainService
    private var refreshTask: Task<TokenInfo, Error>?
    
    func getValidToken() async throws -> TokenInfo {
        // 1. Check if refresh in progress
        if let task = refreshTask {
            return try await task.value
        }
        
        // 2. Get current token
        let currentToken = try getCurrentTokenInfo()
        
        // 3. If valid, return
        if !currentToken.needsRefresh {
            return currentToken
        }
        
        // 4. Start refresh
        let task = Task {
            try await performRefresh(currentToken.refreshToken)
        }
        
        refreshTask = task
        defer { refreshTask = nil }
        
        return try await task.value
    }
    
    private func performRefresh(_ refreshToken: String) async throws -> TokenInfo {
        let response: RefreshResponse = try await apiClient.execute(
            endpoint: .refresh,
            method: .post,
            body: RefreshRequest(refreshToken: refreshToken)
        )
        
        let tokenInfo = TokenInfo(
            accessToken: response.accessToken,
            refreshToken: refreshToken,
            expiresAt: response.expiresAt
        )
        
        try keychainService.saveToken(tokenInfo.accessToken, for: "access_token")
        
        return tokenInfo
    }
}
```

---

### 4. AuthInterceptor

**Archivo**: `Data/Network/Interceptors/AuthInterceptor.swift`

```swift
final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {
    private let tokenCoordinator: TokenRefreshCoordinator
    private let logger = LoggerFactory.auth
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        guard requiresAuth(request) else {
            return request
        }
        
        logger.debug("Intercepting request for auth")
        
        let tokenInfo = try await tokenCoordinator.getValidToken()
        
        var mutableRequest = request
        mutableRequest.setValue(
            "Bearer \(tokenInfo.accessToken)",
            forHTTPHeaderField: "Authorization"
        )
        
        return mutableRequest
    }
    
    private func requiresAuth(_ request: URLRequest) -> Bool {
        // Skip auth for login/refresh endpoints
        guard let url = request.url else { return false }
        return !url.path.contains("/auth/login") && !url.path.contains("/auth/refresh")
    }
}
```

---

### 5. BiometricAuthService

**Archivo**: `Data/Services/Auth/BiometricAuthService.swift`

```swift
import LocalAuthentication

protocol BiometricAuthService: Sendable {
    var isAvailable: Bool { get async }
    var biometryType: LABiometryType { get async }
    func authenticate(reason: String) async throws -> Bool
}

final class LocalAuthenticationService: BiometricAuthService {
    private let logger = LoggerFactory.auth
    
    var isAvailable: Bool {
        get async {
            let context = LAContext()
            var error: NSError?
            return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        }
    }
    
    var biometryType: LABiometryType {
        get async {
            LAContext().biometryType
        }
    }
    
    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        
        logger.info("Biometric authentication requested")
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            logger.info("Biometric authentication succeeded")
            return success
            
        } catch {
            logger.error("Biometric authentication failed", metadata: [
                "error": error.localizedDescription
            ])
            throw BiometricError.authenticationFailed
        }
    }
}
```

---

### 6. Updated AuthRepositoryImpl

**Archivo**: `Data/Repositories/AuthRepositoryImpl.swift`

```swift
final class AuthRepositoryImpl: AuthRepository {
    private let apiClient: APIClient
    private let keychainService: KeychainService
    private let jwtDecoder: JWTDecoder
    private let biometricService: BiometricAuthService
    private let logger = LoggerFactory.auth
    
    func login(email: String, password: String) async -> Result<User, AppError> {
        logger.info("Login attempt started")
        
        do {
            let endpoint: Endpoint = Environment.authMode == .dummyJSON 
                ? .login 
                : .realLogin
            
            let response: LoginResponse = try await apiClient.execute(
                endpoint: endpoint,
                method: .post,
                body: LoginRequest(email: email, password: password)
            )
            
            // Decode and validate JWT
            let payload = try jwtDecoder.decode(response.accessToken)
            
            // Save tokens
            let tokenInfo = TokenInfo(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                expiresAt: payload.exp
            )
            
            try await saveTokenInfo(tokenInfo)
            
            logger.info("Login successful", metadata: ["userId": payload.sub])
            
            return .success(response.toDomain())
            
        } catch {
            logger.error("Login failed", metadata: ["error": error.localizedDescription])
            return .failure(mapError(error))
        }
    }
    
    func loginWithBiometrics() async -> Result<User, AppError> {
        logger.info("Biometric login attempt")
        
        guard await biometricService.isAvailable else {
            return .failure(.system(.notAvailable("Biometric authentication not available")))
        }
        
        do {
            let authenticated = try await biometricService.authenticate(
                reason: "Login to EduGo"
            )
            
            guard authenticated else {
                return .failure(.system(.cancelled))
            }
            
            // Read stored credentials
            guard let email = try? keychainService.getToken(for: "stored_email"),
                  let password = try? keychainService.getToken(for: "stored_password") else {
                return .failure(.system(.notFound("No stored credentials")))
            }
            
            // Perform regular login
            return await login(email: email, password: password)
            
        } catch {
            logger.error("Biometric login failed")
            return .failure(mapError(error))
        }
    }
}
```

---

## 🧪 Testing Strategy

```swift
// Mock JWTDecoder
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

// Mock BiometricService
final class MockBiometricService: BiometricAuthService {
    var isAvailableValue = true
    var authenticateResult: Bool = true
    
    var isAvailable: Bool { isAvailableValue }
    
    func authenticate(reason: String) async throws -> Bool {
        authenticateResult
    }
}
```

---

**Próximos Pasos**: Ver [03-tareas.md](03-tareas.md)
