# 📝 Guía de Uso - Sistema de Logging

**SPEC-002**: Professional Logging System  
**Versión**: 1.0  
**Fecha**: 2025-11-23

---

## 🎯 Introducción

Este proyecto usa **OSLog** (framework nativo de Apple) para logging estructurado, reemplazando todos los `print()` statements por un sistema profesional y filtrable.

---

## 🚀 Inicio Rápido

### Uso Básico

```swift
// 1. Obtener logger de la categoría apropiada
private let logger = LoggerFactory.network

// 2. Loggear con el nivel adecuado
logger.info("Request completed successfully")
logger.error("Failed to fetch data", metadata: ["url": url])
```

---

## 📊 Niveles de Log

| Nivel | Cuándo Usar | Ejemplo |
|-------|-------------|---------|
| `debug` | Información detallada para debugging | "Variable X = \(value)" |
| `info` | Eventos normales e informativos | "User logged in", "Request started" |
| `notice` | Eventos significativos pero normales | "Configuration changed" |
| `warning` | Situaciones potencialmente problemáticas | "Token expiring soon" |
| `error` | Errores que requieren atención | "API call failed" |
| `critical` | Fallos severos del sistema | "Database corrupted" |

### Guías de Uso

**Debug**: Solo en desarrollo, información muy detallada
```swift
logger.debug("Processing user data", metadata: [
    "userId": user.id,
    "step": "validation"
])
```

**Info**: Eventos normales del flujo
```swift
logger.info("Login attempt started")
logger.info("Data saved successfully")
```

**Warning**: Cosas que podrían ser problemas
```swift
logger.warning("Token expiring in 5 minutes")
logger.warning("Slow network detected")
```

**Error**: Problemas que requieren atención
```swift
logger.error("API request failed", metadata: [
    "endpoint": "/users",
    "statusCode": "500"
])
```

---

## 🗂️ Categorías de Loggers

### LoggerFactory.network
**Usar en**: APIClient, NetworkService, RequestBuilder

```swift
private let logger = LoggerFactory.network

func execute() async throws {
    logger.info("HTTP Request started", metadata: [
        "method": "GET",
        "url": url
    ])
    
    // ... request ...
    
    logger.info("HTTP Response received", metadata: [
        "statusCode": "200",
        "size": "\(data.count) bytes"
    ])
}
```

### LoggerFactory.auth
**Usar en**: AuthRepository, TokenManager, BiometricService

```swift
private let logger = LoggerFactory.auth

func login() async -> Result<User, AppError> {
    logger.info("Login attempt started")
    logger.logEmail(email)  // Email redactado
    
    // ... login logic ...
    
    logger.logToken(token)  // Token redactado
    logger.info("Login successful")
}
```

### LoggerFactory.data
**Usar en**: KeychainService, UserDefaults, Database

```swift
private let logger = LoggerFactory.data

func saveToken() throws {
    logger.debug("Saving token to Keychain")
    
    // ... save logic ...
    
    logger.info("Token saved successfully")
}
```

### LoggerFactory.ui
**Usar en**: Views, ViewModels, NavigationCoordinator

```swift
private let logger = LoggerFactory.ui

struct LoginView: View {
    var body: some View {
        // ...
        .onAppear {
            logger.debug("LoginView appeared")
        }
    }
}
```

### LoggerFactory.business
**Usar en**: Use Cases

```swift
private let logger = LoggerFactory.business

func execute() async -> Result<User, AppError> {
    logger.info("LoginUseCase execution started")
    
    // ... business logic ...
    
    logger.info("LoginUseCase completed successfully")
}
```

### LoggerFactory.system
**Usar en**: App lifecycle, Memory management

```swift
private let logger = LoggerFactory.system

@main
struct MyApp: App {
    init() {
        logger.info("App launched")
    }
}
```

---

## 🔒 Logging de Datos Sensibles

### ✅ Tokens (Redactados)

```swift
let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

// ❌ MAL - Token completo
logger.debug("Token: \(token)")

// ✅ BIEN - Token redactado
logger.logToken(token)
// Log: "Token: eyJh...VCJ9"
```

### ✅ Emails (Redactados)

```swift
let email = "user@example.com"

// ❌ MAL - Email completo
logger.debug("Email: \(email)")

// ✅ BIEN - Email redactado
logger.logEmail(email)
// Log: "Email: us***@example.com"
```

### ✅ User IDs (Redactados)

```swift
let userId = "550e8400-e29b-41d4-a716-446655440000"

// ✅ BIEN - ID redactado
logger.logUserId(userId)
// Log: "UserID: 550e***0000"
```

### ❌ Passwords (PROHIBIDO)

```swift
let password = "secretPass123"

// ❌ NUNCA hacer esto
logger.logPassword(password)  // ❌ No compila - @unavailable

// ✅ Simplemente NO loggear passwords
logger.info("Password validation completed")  // Sin el password
```

---

## 📱 Filtrado en Console.app

### Abrir Console.app

1. Abrir Console.app (en /Applications/Utilities/)
2. Seleccionar tu Mac o Simulador
3. Usar los filtros

### Filtros Útiles

**Por subsystem**:
```
subsystem:com.edugo.apple-app
```

**Por categoría**:
```
category:network
category:auth
category:data
```

**Por nivel**:
```
level:error
level:debug
```

**Combinaciones**:
```
subsystem:com.edugo.apple-app AND category:network
subsystem:com.edugo.apple-app AND category:auth AND level:error
category:network AND level:error
```

---

## 💡 Mejores Prácticas

### ✅ Hacer

```swift
// 1. Usar el logger apropiado por categoría
private let logger = LoggerFactory.network

// 2. Usar el nivel correcto
logger.info("Normal operation")
logger.error("Something went wrong")

// 3. Incluir metadata útil
logger.error("API failed", metadata: [
    "endpoint": "/users",
    "statusCode": "500"
])

// 4. Usar helpers de privacy
logger.logToken(token)
logger.logEmail(email)

// 5. Logging en puntos clave
func login() {
    logger.info("Login started")  // Inicio
    // ... logic ...
    logger.info("Login completed")  // Fin
}
```

### ❌ Evitar

```swift
// 1. NO usar print()
print("Debug info")  // ❌

// 2. NO loggear passwords
logger.debug("Password: \(password)")  // ❌

// 3. NO loggear tokens sin redactar
logger.debug("Token: \(token)")  // ❌

// 4. NO sobre-loggear
logger.debug("Step 1")
logger.debug("Step 2")  // ❌ Demasiado ruido
logger.debug("Step 3")

// 5. NO usar nivel incorrecto
logger.critical("User clicked button")  // ❌ No es crítico
```

---

## 🧪 Testing con MockLogger

```swift
import Testing
@testable import apple_app

@Test("Login loggea correctamente")
func loginLogsCorrectly() async {
    // Given
    let mockLogger = MockLogger()
    let repository = AuthRepositoryImpl(..., logger: mockLogger)
    
    // When
    let result = await repository.login(email: "test@test.com", password: "pass")
    
    // Then
    #expect(mockLogger.contains(level: "info", message: "Login attempt"))
    #expect(mockLogger.contains(level: "info", message: "Login successful"))
    #expect(mockLogger.count(level: "error") == 0)
}
```

---

## 📊 Ejemplos Completos

### Ejemplo 1: Networking

```swift
final class MyAPIClient {
    private let logger = LoggerFactory.network
    
    func fetchUsers() async throws -> [User] {
        logger.info("Fetching users")
        
        do {
            let users = try await api.get("/users")
            logger.info("Users fetched successfully", metadata: [
                "count": "\(users.count)"
            ])
            return users
            
        } catch {
            logger.error("Failed to fetch users", metadata: [
                "error": error.localizedDescription
            ])
            throw error
        }
    }
}
```

### Ejemplo 2: Authentication

```swift
final class AuthManager {
    private let logger = LoggerFactory.auth
    
    func login(email: String, password: String) async -> Result<User, Error> {
        logger.info("Login attempt started")
        logger.logEmail(email)
        
        // ... authentication ...
        
        if let token = response.token {
            logger.logToken(token, label: "AccessToken")
        }
        
        logger.info("Login completed successfully")
        return .success(user)
    }
}
```

### Ejemplo 3: Data Persistence

```swift
final class UserRepository {
    private let logger = LoggerFactory.data
    
    func save(user: User) throws {
        logger.debug("Saving user to database", metadata: [
            "userId": user.id
        ])
        
        try database.save(user)
        
        logger.info("User saved successfully", metadata: [
            "userId": user.id
        ])
    }
}
```

---

## ❓ FAQ

### ¿Por qué usar OSLog en lugar de print()?

✅ **Ventajas de OSLog**:
- Filtrable por subsystem/categoría/nivel
- Performance optimizado
- Privacy redaction automática
- Integración con Console.app y Xcode
- Logs estructurados

❌ **Problemas de print()**:
- No filtrable
- Sin niveles
- Sin metadata
- Performance impact
- No production-ready

### ¿Cuándo usar debug vs info?

- **debug**: Solo para desarrollo, información muy detallada que no necesitas en producción
- **info**: Eventos normales que quieres saber que ocurrieron

### ¿Cómo veo los logs en producción?

En producción, solo verás logs de nivel `warning`, `error` y `critical` (según configuración de `AppEnvironment.logLevel`).

Para verlos:
1. Conectar dispositivo a Mac
2. Abrir Console.app
3. Seleccionar dispositivo
4. Filtrar: `subsystem:com.edugo.apple-app`

---

## 🔗 Referencias

- [Apple - Unified Logging](https://developer.apple.com/documentation/os/logging)
- [Apple - Logger API](https://developer.apple.com/documentation/os/logger)
- [SPEC-002 Completo](../specs/logging-system/SPEC-002-COMPLETADO.md)

---

**¿Preguntas?** Consulta la especificación completa en [`docs/specs/logging-system/`](../specs/logging-system/)
