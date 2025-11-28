# Análisis de Diseño: Professional Logging System

**Fecha**: 2025-11-23  
**Versión**: 1.0  
**Estado**: 📐 Diseño Técnico  
**Prioridad**: 🔴 P0 - CRÍTICO  
**Autor**: Cascade AI

---

## 📋 Resumen

Diseño técnico del sistema de logging basado en OSLog con abstracción protocol-based, categorización, y redacción automática de datos sensibles.

---

## 🏗️ Arquitectura del Sistema

```
┌──────────────────────────────────────────────────────────────┐
│                     Application Layer                         │
│                                                               │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────┐     │
│  │AuthRepository │  │   APIClient   │  │KeychainService│    │
│  └───────┬───────┘  └───────┬───────┘  └──────┬───────┘     │
│          │                   │                 │             │
│          └───────────────────┴─────────────────┘             │
│                              ↓                               │
│                     ┌────────────────┐                       │
│                     │ LoggerFactory  │                       │
│                     └────────────────┘                       │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│                   Logging Abstraction Layer                   │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐     │
│  │          Logger Protocol (Sendable)                 │     │
│  │  • debug(_ message, metadata)                       │     │
│  │  • info(_ message, metadata)                        │     │
│  │  • warning(_ message, metadata)                     │     │
│  │  • error(_ message, metadata)                       │     │
│  │  • critical(_ message, metadata)                    │     │
│  └─────────────────────────────────────────────────────┘     │
│                              ↓                               │
│  ┌────────────────┐  ┌──────────────┐  ┌────────────────┐   │
│  │   OSLogger     │  │  MockLogger  │  │ InMemoryLogger │   │
│  │  (Production)  │  │  (Testing)   │  │   (Testing)    │   │
│  └────────────────┘  └──────────────┘  └────────────────┘   │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│                      OSLog Framework                          │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐     │
│  │              os.Logger (Native)                     │     │
│  │  • Subsystem: com.edugo.app                         │     │
│  │  • Categories: network, auth, data, ui, business    │     │
│  │  • Levels: debug, info, notice, warning, error      │     │
│  │  • Privacy: automatic redaction                     │     │
│  └─────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────┘
                              ↓
                      Console.app / Xcode
```

---

## 📁 Estructura de Archivos

```
apple-app/
├── Core/
│   └── Logging/                         # ← Nueva carpeta
│       ├── Logger.swift                 # Protocol
│       ├── LogCategory.swift            # Enum de categorías
│       ├── OSLogger.swift               # Implementation
│       ├── LoggerFactory.swift          # Factory
│       ├── LoggerExtensions.swift       # Privacy helpers
│       └── MockLogger.swift             # Testing
│
apple-appTests/
├── CoreTests/
│   └── LoggingTests/
│       ├── OSLoggerTests.swift
│       ├── LoggerFactoryTests.swift
│       └── PrivacyTests.swift
```

---

## 🧩 Componentes del Sistema

### 1. Logger Protocol

**Archivo**: `Core/Logging/Logger.swift`

```swift
//
//  Logger.swift
//  apple-app
//
//  Created on 23-11-25.
//

import Foundation
import os

/// Protocol para logging estructurado
/// Permite diferentes implementations (OSLog, terceros, testing)
protocol Logger: Sendable {
    /// Log mensaje de debug (solo desarrollo)
    /// - Parameters:
    ///   - message: Mensaje a loggear
    ///   - metadata: Metadata adicional (opcional)
    ///   - file: Archivo donde se llama (auto)
    ///   - function: Función donde se llama (auto)
    ///   - line: Línea donde se llama (auto)
    func debug(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    )
    
    /// Log mensaje informativo
    func info(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    )
    
    /// Log mensaje de notificación (importante pero no error)
    func notice(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    )
    
    /// Log advertencia (potencial problema)
    func warning(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    )
    
    /// Log error (problema que requiere atención)
    func error(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    )
    
    /// Log crítico (fallo severo del sistema)
    func critical(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    )
}

// MARK: - Convenience Extensions

extension Logger {
    func debug(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        debug(message, metadata: metadata, file: file, function: function, line: line)
    }
    
    func info(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        info(message, metadata: metadata, file: file, function: function, line: line)
    }
    
    func warning(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        warning(message, metadata: metadata, file: file, function: function, line: line)
    }
    
    func error(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        error(message, metadata: metadata, file: file, function: function, line: line)
    }
    
    func critical(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        critical(message, metadata: metadata, file: file, function: function, line: line)
    }
}
```

---

### 2. LogCategory Enum

**Archivo**: `Core/Logging/LogCategory.swift`

```swift
//
//  LogCategory.swift
//  apple-app
//
//  Created on 23-11-25.
//

import Foundation

/// Categorías de logging para organizar logs
enum LogCategory: String {
    /// Logs de networking (requests, responses)
    case network
    
    /// Logs de autenticación (login, logout, tokens)
    case auth
    
    /// Logs de persistencia (database, keychain, userdefaults)
    case data
    
    /// Logs de UI (view lifecycle, user interactions)
    case ui
    
    /// Logs de business logic (use cases)
    case business
    
    /// Logs del sistema (lifecycle, memory, errors)
    case system
}
```

---

### 3. OSLogger Implementation

**Archivo**: `Core/Logging/OSLogger.swift`

```swift
//
//  OSLogger.swift
//  apple-app
//
//  Created on 23-11-25.
//

import Foundation
import os

/// Implementation de Logger usando OSLog
final class OSLogger: Logger, @unchecked Sendable {
    private let logger: os.Logger
    private let category: LogCategory
    
    init(subsystem: String, category: LogCategory) {
        self.logger = os.Logger(subsystem: subsystem, category: category.rawValue)
        self.category = category
    }
    
    // MARK: - Logger Implementation
    
    func debug(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatMessage(message, metadata: metadata, file: file, function: function, line: line)
        logger.debug("\(formattedMessage)")
    }
    
    func info(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatMessage(message, metadata: metadata, file: file, function: function, line: line)
        logger.info("\(formattedMessage)")
    }
    
    func notice(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatMessage(message, metadata: metadata, file: file, function: function, line: line)
        logger.notice("\(formattedMessage)")
    }
    
    func warning(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatMessage(message, metadata: metadata, file: file, function: function, line: line)
        logger.warning("\(formattedMessage)")
    }
    
    func error(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatMessage(message, metadata: metadata, file: file, function: function, line: line)
        logger.error("\(formattedMessage)")
    }
    
    func critical(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatMessage(message, metadata: metadata, file: file, function: function, line: line)
        logger.critical("\(formattedMessage)")
    }
    
    // MARK: - Private Helpers
    
    private func formatMessage(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) -> String {
        let filename = (file as NSString).lastPathComponent
        var formatted = "[\(filename):\(line)] \(function) - \(message)"
        
        if let metadata = metadata, !metadata.isEmpty {
            let metadataString = metadata
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ", ")
            formatted += " | \(metadataString)"
        }
        
        return formatted
    }
}
```

---

### 4. LoggerFactory

**Archivo**: `Core/Logging/LoggerFactory.swift`

```swift
//
//  LoggerFactory.swift
//  apple-app
//
//  Created on 23-11-25.
//

import Foundation

/// Factory para crear loggers por categoría
enum LoggerFactory {
    /// Subsystem único de la app
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.edugo.app"
    
    /// Logger para networking
    static let network = make(category: .network)
    
    /// Logger para autenticación
    static let auth = make(category: .auth)
    
    /// Logger para persistencia
    static let data = make(category: .data)
    
    /// Logger para UI
    static let ui = make(category: .ui)
    
    /// Logger para business logic
    static let business = make(category: .business)
    
    /// Logger para sistema
    static let system = make(category: .system)
    
    /// Crea un logger para la categoría especificada
    private static func make(category: LogCategory) -> Logger {
        OSLogger(subsystem: subsystem, category: category)
    }
}
```

---

### 5. Privacy Extensions

**Archivo**: `Core/Logging/LoggerExtensions.swift`

```swift
//
//  LoggerExtensions.swift
//  apple-app
//
//  Created on 23-11-25.
//

import Foundation

extension Logger {
    /// Log un token JWT con redacción automática
    /// - Parameter token: Token a loggear
    ///
    /// Ejemplo: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." → "eyJh...VCJ9"
    func logToken(_ token: String, label: String = "Token") {
        let redacted = redactToken(token)
        debug("\(label): \(redacted)")
    }
    
    /// Log un email con redacción parcial
    /// - Parameter email: Email a loggear
    ///
    /// Ejemplo: "user@example.com" → "us***@example.com"
    func logEmail(_ email: String, label: String = "Email") {
        let redacted = redactEmail(email)
        debug("\(label): \(redacted)")
    }
    
    /// Log un ID de usuario (parcialmente redactado)
    /// - Parameter userId: User ID a loggear
    ///
    /// Ejemplo: "550e8400-e29b-41d4-a716-446655440000" → "550e***0000"
    func logUserId(_ userId: String, label: String = "UserID") {
        let redacted = redactId(userId)
        debug("\(label): \(redacted)")
    }
    
    // MARK: - Private Redaction Functions
    
    private func redactToken(_ token: String) -> String {
        guard token.count > 8 else { return "***" }
        return "\(token.prefix(4))...\(token.suffix(4))"
    }
    
    private func redactEmail(_ email: String) -> String {
        let parts = email.split(separator: "@")
        guard parts.count == 2 else { return "***" }
        
        let username = String(parts[0])
        let domain = String(parts[1])
        let redactedUsername = username.count > 2 ? "\(username.prefix(2))***" : "***"
        
        return "\(redactedUsername)@\(domain)"
    }
    
    private func redactId(_ id: String) -> String {
        guard id.count > 8 else { return "***" }
        return "\(id.prefix(4))***\(id.suffix(4))"
    }
}

// MARK: - Password Protection

extension Logger {
    /// ⚠️ NUNCA loggear passwords
    /// Este método existe solo para documentar la prohibición
    @available(*, unavailable, message: "Never log passwords, even redacted")
    func logPassword(_ password: String) {
        fatalError("Passwords must never be logged")
    }
}
```

---

### 6. MockLogger (Testing)

**Archivo**: `Core/Logging/MockLogger.swift`

```swift
//
//  MockLogger.swift
//  apple-app
//
//  Created on 23-11-25.
//

import Foundation

/// Logger para testing que almacena mensajes en memoria
final class MockLogger: Logger {
    struct LogEntry {
        let level: String
        let message: String
        let metadata: [String: String]?
        let file: String
        let function: String
        let line: Int
    }
    
    private(set) var entries: [LogEntry] = []
    
    func debug(_ message: String, metadata: [String: String]?, file: String, function: String, line: Int) {
        entries.append(LogEntry(level: "debug", message: message, metadata: metadata, file: file, function: function, line: line))
    }
    
    func info(_ message: String, metadata: [String: String]?, file: String, function: String, line: Int) {
        entries.append(LogEntry(level: "info", message: message, metadata: metadata, file: file, function: function, line: line))
    }
    
    func notice(_ message: String, metadata: [String: String]?, file: String, function: String, line: Int) {
        entries.append(LogEntry(level: "notice", message: message, metadata: metadata, file: file, function: function, line: line))
    }
    
    func warning(_ message: String, metadata: [String: String]?, file: String, function: String, line: Int) {
        entries.append(LogEntry(level: "warning", message: message, metadata: metadata, file: file, function: function, line: line))
    }
    
    func error(_ message: String, metadata: [String: String]?, file: String, function: String, line: Int) {
        entries.append(LogEntry(level: "error", message: message, metadata: metadata, file: file, function: function, line: line))
    }
    
    func critical(_ message: String, metadata: [String: String]?, file: String, function: String, line: Int) {
        entries.append(LogEntry(level: "critical", message: message, metadata: metadata, file: file, function: function, line: line))
    }
    
    // MARK: - Testing Helpers
    
    func clear() {
        entries.removeAll()
    }
    
    func contains(level: String, message: String) -> Bool {
        entries.contains { $0.level == level && $0.message.contains(message) }
    }
    
    func count(level: String) -> Int {
        entries.filter { $0.level == level }.count
    }
}
```

---

## 🔄 Migration Examples

### Before (❌ Print Statements)

```swift
// AuthRepositoryImpl.swift
func login(email: String, password: String) async -> Result<User, AppError> {
    do {
        let response: LoginResponse = try await apiClient.execute(...)
        try keychainService.saveToken(response.accessToken, for: accessTokenKey)
        return .success(response.toDomain())
        
    } catch let error as NetworkError {
        print("❌ Login NetworkError: \(error)")
        return .failure(.network(error))
    }
}
```

### After (✅ Structured Logging)

```swift
// AuthRepositoryImpl.swift
private let logger = LoggerFactory.auth

func login(email: String, password: String) async -> Result<User, AppError> {
    logger.info("Login attempt started")
    logger.logEmail(email)
    
    do {
        let response: LoginResponse = try await apiClient.execute(...)
        
        logger.debug("Login API response received", metadata: [
            "userId": response.id.description
        ])
        
        try keychainService.saveToken(response.accessToken, for: accessTokenKey)
        logger.info("Login successful")
        return .success(response.toDomain())
        
    } catch let error as NetworkError {
        logger.error("Login failed - Network error", metadata: [
            "error": error.localizedDescription,
            "errorType": String(describing: type(of: error))
        ])
        return .failure(.network(error))
    }
}
```

---

## 📊 Console.app Filtering

### Filtrar por Subsystem

```
subsystem:com.edugo.app
```

### Filtrar por Category

```
category:network
category:auth
```

### Filtrar por Level

```
level:error
level:debug
```

### Combinaciones

```
subsystem:com.edugo.app AND category:network AND level:error
```

---

## 🧪 Testing Strategy

```swift
// AuthRepositoryTests.swift
func testLoginLogsCorrectly() async {
    // Given
    let mockLogger = MockLogger()
    let repository = AuthRepositoryImpl(..., logger: mockLogger)
    
    // When
    let result = await repository.login(email: "test@example.com", password: "pass")
    
    // Then
    XCTAssertTrue(mockLogger.contains(level: "info", message: "Login attempt started"))
    XCTAssertTrue(mockLogger.contains(level: "info", message: "Login successful"))
    XCTAssertEqual(mockLogger.count(level: "error"), 0)
}
```

---

**Próximos Pasos**: Ver [03-tareas.md](03-tareas.md) para plan de implementación
