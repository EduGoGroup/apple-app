# Análisis de Requerimiento: Professional Logging System

**Fecha**: 2025-11-23  
**Versión**: 1.0  
**Estado**: 📋 Propuesta  
**Prioridad**: 🔴 P0 - CRÍTICO  
**Autor**: Cascade AI

---

## 📋 Resumen Ejecutivo

Reemplazar `print()` statements por un sistema de logging profesional basado en OSLog (framework nativo de Apple) con abstracción protocol-based, niveles de log, categorías, y redacción automática de datos sensibles.

---

## 🎯 Objetivo

Implementar un sistema de logging que permita:
- Logging estructurado con niveles (debug, info, warning, error, critical)
- Categorización por subsistema (network, auth, data, ui, business)
- Redacción automática de información sensible (tokens, passwords)
- Filtrado en Console.app por categoría y nivel
- Testing con mock loggers
- Zero `print()` statements en producción

---

## 🔍 Problemática Actual

### 1. Print Statements en Producción

**Archivo**: `Data/Repositories/AuthRepositoryImpl.swift` (líneas 54, 57, 60-61)

```swift
func login(email: String, password: String) async -> Result<User, AppError> {
    do {
        // ... login logic ...
    } catch let error as NetworkError {
        print("❌ Login NetworkError: \(error)")  // ❌ PRINT en producción
        return .failure(.network(error))
    } catch let error as KeychainError {
        print("❌ Login KeychainError: \(error)")  // ❌ PRINT en producción
        return .failure(.system(.system(error.localizedDescription)))
    } catch {
        print("❌ Login Unknown Error: \(error)")  // ❌ PRINT en producción
        print("❌ Error Type: \(type(of: error))") // ❌ PRINT en producción
        return .failure(.system(.system("Error: \(error.localizedDescription)")))
    }
}
```

**Problemas**:
- ❌ Print va a stdout (no filtrable)
- ❌ No tiene nivel de severidad
- ❌ No se puede deshabilitar en producción
- ❌ No es estructurado (difícil parsear)

---

### 2. Sin Logging en Componentes Críticos

**Archivo**: `Data/Network/APIClient.swift` - **0 logs**

```swift
func execute<T: Decodable>(...) async throws -> T {
    // Construir URL
    let url = baseURL.appendingPathComponent(endpoint.path)
    
    // Crear request
    var request = URLRequest(url: url)
    // ... setup request ...
    
    // Ejecutar request
    let (data, response) = try await session.data(for: request)
    // ❌ NO HAY LOGGING de request/response
    
    // Validar respuesta
    guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkError.serverError(0)
    }
    
    // ❌ NO HAY LOGGING de status code
}
```

**Impacto**:
- ❌ Imposible debuggear issues de red
- ❌ No hay visibilidad de requests/responses
- ❌ Difícil reproducir bugs

---

### 3. Sin Logging en KeychainService

**Archivo**: `Data/Services/KeychainService.swift` - **0 logs**

```swift
func saveToken(_ token: String, for key: String) throws {
    // ❌ NO HAY LOGGING de guardado de token
    guard let data = token.data(using: .utf8) else {
        throw KeychainError.invalidData
    }
    
    let query: [String: Any] = [...]
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
        throw KeychainError.unableToSave  // ❌ NO HAY LOGGING del error
    }
    // ❌ NO HAY LOGGING de éxito
}
```

**Impacto**:
- ❌ No se sabe cuándo se guardan/leen tokens
- ❌ Errores de Keychain son silenciosos
- ❌ Difícil debuggear auth issues

---

### 4. Sin Categorización

**Problema**: Todos los logs mezclados, imposible filtrar

```
Console.app:
print("View Appeared")           // UI
print("❌ Network Error")        // Network  
print("User logged in")          // Auth
print("Saving to database")      // Data
```

No se puede filtrar por:
- ❌ Subsystem (auth vs network)
- ❌ Categoría (ui vs data)
- ❌ Nivel (debug vs error)

---

### 5. Sin Redacción de Datos Sensibles

**Riesgo**: Datos sensibles en logs

```swift
let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
print("Token: \(token)")  // ❌ Token completo en logs

let email = "user@example.com"
print("User: \(email)")   // ❌ Email en logs

let password = "secretPass123"
print("Password: \(password)")  // ❌ PASSWORD EN LOGS!!!
```

**Impacto**:
- ❌ Violación de privacidad
- ❌ Logs accesibles desde Console.app
- ❌ Riesgo de seguridad

---

## 💼 Casos de Uso

### CU-001: Desarrollador Debuggea Network Issue

**Actor**: Desarrollador iOS  
**Escenario**: API call está fallando  

**Flujo Deseado**:
1. Abre Console.app
2. Filtra por `subsystem:com.edugo.app AND category:network`
3. Ve todos los requests/responses
4. Identifica request problemático
5. Ve headers, body, status code
6. Tokens redactados automáticamente

**Resultado**: Bug identificado en < 5 minutos

**Situación Actual**:
- ❌ No hay logs de network
- ❌ Requiere agregar prints temporales
- ❌ Debuggeo toma > 30 minutos

---

### CU-002: QA Reporta Auth Issue

**Actor**: QA Tester  
**Escenario**: Login falla inconsistentemente  

**Flujo Deseado**:
1. QA envía logs filtrados por `category:auth`
2. Dev ve secuencia: login → saveToken → error
3. Identifica KeychainError específico
4. Token está redactado (solo muestra primeros/últimos 4 chars)

**Resultado**: Issue reproducible y entendible

**Situación Actual**:
- ❌ Solo prints genéricos
- ❌ No se sabe qué falló en Keychain
- ❌ Tokens expuestos en logs

---

### CU-003: Monitoreo de Producción

**Actor**: DevOps  
**Escenario**: Monitorear errores en prod  

**Flujo Deseado**:
1. Console.app filtra por `level:error`
2. Ve solo errores críticos
3. Cada error tiene metadata (user_id, session_id, etc.)
4. Datos sensibles redactados

**Resultado**: Monitoreo efectivo sin ruido

**Situación Actual**:
- ❌ No hay filtrado por nivel
- ❌ Prints mezclados con logs del sistema
- ❌ No hay metadata estructurada

---

## 📊 Requerimientos Funcionales

### RF-001: Protocol-Based Logger
**Prioridad**: CRÍTICA  

```swift
protocol Logger: Sendable {
    func debug(_ message: String, metadata: [String: String]?)
    func info(_ message: String, metadata: [String: String]?)
    func notice(_ message: String, metadata: [String: String]?)
    func warning(_ message: String, metadata: [String: String]?)
    func error(_ message: String, metadata: [String: String]?)
    func critical(_ message: String, metadata: [String: String]?)
}
```

---

### RF-002: OSLog Implementation
**Prioridad**: CRÍTICA  

```swift
final class OSLogger: Logger {
    private let logger: os.Logger
    init(subsystem: String, category: LogCategory)
}
```

Según [Apple Documentation](https://developer.apple.com/documentation/os/logging):
> "The unified logging system provides a comprehensive and efficient way to log messages in your app."

---

### RF-003: Log Categories
**Prioridad**: ALTA  

| Categoría | Propósito | Ejemplos |
|-----------|-----------|----------|
| `network` | Requests HTTP | "Request started: GET /users" |
| `auth` | Autenticación | "Login successful", "Token refreshed" |
| `data` | Persistencia | "Saved to Keychain", "Database error" |
| `ui` | User interactions | "View appeared", "Button tapped" |
| `business` | Use cases | "LoginUseCase executed" |
| `system` | App lifecycle | "App launched", "Memory warning" |

---

### RF-004: Privacy & Redaction
**Prioridad**: CRÍTICA  

```swift
extension Logger {
    func logToken(_ token: String) {
        // Redactar: "eyJhbGc..." → "eyJh...VCJ9"
        let redacted = "\(token.prefix(4))...\(token.suffix(4))"
        debug("Token: \(redacted)")
    }
    
    func logEmail(_ email: String) {
        // Redactar: "user@example.com" → "us***@example.com"
        let parts = email.split(separator: "@")
        let redacted = "\(parts[0].prefix(2))***@\(parts[1])"
        debug("Email: \(redacted)")
    }
}
```

---

### RF-005: LoggerFactory
**Prioridad**: ALTA  

```swift
enum LoggerFactory {
    static let network = make(category: .network)
    static let auth = make(category: .auth)
    static let data = make(category: .data)
    static let ui = make(category: .ui)
    static let business = make(category: .business)
    static let system = make(category: .system)
    
    private static func make(category: LogCategory) -> Logger {
        OSLogger(subsystem: Bundle.main.bundleIdentifier!, category: category)
    }
}
```

---

### RF-006: Testing Support
**Prioridad**: ALTA  

```swift
final class MockLogger: Logger {
    var messages: [(level: String, message: String, metadata: [String: String]?)] = []
    
    func debug(_ message: String, metadata: [String: String]?) {
        messages.append(("debug", message, metadata))
    }
}
```

---

## 📊 Requerimientos No Funcionales

### RNF-001: Performance
- Logging overhead < 1ms por llamada
- No impact en app launch time
- Async logging para operaciones costosas

### RNF-002: Privacy (GDPR/CCPA)
- Redacción automática de PII
- Tokens nunca en plain text
- Passwords NUNCA loggeados (ni redactados)

### RNF-003: Usabilidad
- API simple y consistente
- Default parameters (#file, #function, #line)
- SwiftUI preview-safe

### RNF-004: Mantenibilidad
- Zero print() en producción
- Logs filtrables en Console.app
- Testing con MockLogger

---

## 🎯 Criterios de Aceptación

### ✅ CA-001: Sistema de Logging
- [ ] Logger protocol definido
- [ ] OSLogger implementation
- [ ] LoggerFactory con 6 categorías
- [ ] Zero print() statements

### ✅ CA-002: Integration
- [ ] Logging en AuthRepositoryImpl
- [ ] Logging en APIClient
- [ ] Logging en KeychainService
- [ ] Logging en ViewModels (opcional)

### ✅ CA-003: Privacy
- [ ] Token redaction implementado
- [ ] Email redaction implementado
- [ ] Password logging prohibido
- [ ] Tests de redaction

### ✅ CA-004: Testing
- [ ] MockLogger implementado
- [ ] Tests unitarios de Logger
- [ ] Tests de integration
- [ ] Console.app filtering documentado

---

## 📚 Referencias

### Apple Documentation
- [Unified Logging (OSLog)](https://developer.apple.com/documentation/os/logging)
- [Logger API](https://developer.apple.com/documentation/os/logger)
- [Privacy in Logging](https://developer.apple.com/documentation/os/logging/generating_log_messages_from_your_code#3665948)

### Artículos Técnicos
- [SwiftLee - OSLog and Unified Logging](https://www.avanderlee.com/debugging/oslog-unified-logging/)
- [Donny Wals - OSLog Best Practices](https://www.donnywals.com/)

### Best Practices
- [Swift.org - Log Levels](https://www.swift.org/documentation/server/guides/libraries/log-levels.html)

---

**Próximos Pasos**: Ver [02-analisis-diseno.md](02-analisis-diseno.md) para diseño técnico detallado
