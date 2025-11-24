# Análisis de Diseño: Environment Configuration System

**Fecha**: 2025-11-23  
**Versión**: 1.0  
**Estado**: 📐 Diseño Técnico  
**Prioridad**: 🔴 P0 - CRÍTICO  
**Autor**: Cascade AI

---

## 📋 Resumen

Este documento describe el diseño técnico detallado del sistema de configuración de ambientes basado en `.xcconfig` files, incluyendo arquitectura, estructura de archivos, APIs Swift, y estrategia de migración.

---

## 🏗️ Arquitectura del Sistema

### Vista General

```
┌─────────────────────────────────────────────────────────────┐
│                    Build Time (Xcode)                        │
│                                                              │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐          │
│  │  Scheme  │  →   │  Build   │  →   │ .xcconfig│          │
│  │          │      │  Config  │      │   File   │          │
│  └──────────┘      └──────────┘      └──────────┘          │
│       │                 │                  │                │
│       └─────────────────┴──────────────────┘                │
│                         ↓                                   │
│                   ┌──────────┐                              │
│                   │Info.plist│  (Variables injected)        │
│                   └──────────┘                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Runtime (Swift)                           │
│                                                              │
│  ┌─────────────────────────────────────────────────┐        │
│  │            Environment (Swift Enum)              │        │
│  │                                                  │        │
│  │  ┌──────────────────────────────────────┐      │        │
│  │  │  Read from Bundle.main.infoDictionary │      │        │
│  │  └──────────────────────────────────────┘      │        │
│  │                     ↓                            │        │
│  │  ┌──────────────────────────────────────┐      │        │
│  │  │  Type-Safe Properties                 │      │        │
│  │  │  - apiBaseURL: URL                    │      │        │
│  │  │  - timeout: TimeInterval              │      │        │
│  │  │  - logLevel: LogLevel                 │      │        │
│  │  └──────────────────────────────────────┘      │        │
│  └─────────────────────────────────────────────────┘        │
│                         ↓                                    │
│  ┌─────────────────────────────────────────────────┐        │
│  │         App Code (APIClient, etc.)              │        │
│  │  let url = Environment.current.apiBaseURL       │        │
│  └─────────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Estructura de Archivos

### Organización de .xcconfig Files

```
apple-app/
├── Configs/                                 # ← Nueva carpeta
│   ├── Base.xcconfig                       # Configuración compartida
│   ├── Development.xcconfig                # Ambiente: Desarrollo
│   ├── Staging.xcconfig                    # Ambiente: Staging
│   ├── Production.xcconfig                 # Ambiente: Producción
│   ├── Local.xcconfig                      # Ambiente: Local (localhost)
│   ├── QA.xcconfig                         # Ambiente: QA
│   ├── Docker.xcconfig                     # Ambiente: Docker container
│   └── TestContainer.xcconfig              # Ambiente: Integration tests
│
├── Configs-Templates/                       # ← Templates para commit
│   ├── Development.xcconfig.template
│   ├── Staging.xcconfig.template
│   ├── Production.xcconfig.template
│   ├── Local.xcconfig.template
│   ├── QA.xcconfig.template
│   ├── Docker.xcconfig.template
│   └── TestContainer.xcconfig.template
│
├── App/
│   ├── Environment.swift                    # ← Nueva clase
│   └── Info.plist                          # ← Modificado
│
└── .gitignore                               # ← Actualizado
```

### Archivos a Crear

| Archivo | Propósito | En Git |
|---------|-----------|--------|
| `Configs/Base.xcconfig` | Config compartida | ✅ Sí |
| `Configs/*.xcconfig` | Configs por ambiente | ❌ No (.gitignore) |
| `Configs-Templates/*.xcconfig.template` | Templates | ✅ Sí |
| `App/Environment.swift` | Swift API | ✅ Sí |
| `README-Environment.md` | Documentación | ✅ Sí |

---

## 🧩 Componentes del Sistema

### 1. Base.xcconfig (Configuración Compartida)

**Propósito**: Valores comunes a todos los ambientes

```ruby
// Base.xcconfig
// Configuración compartida entre todos los ambientes

// App Information
PRODUCT_NAME = EduGo
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1

// Deployment
IPHONEOS_DEPLOYMENT_TARGET = 18.0
MACOSX_DEPLOYMENT_TARGET = 15.0
SWIFT_VERSION = 6.0

// Compiler Settings
SWIFT_STRICT_CONCURRENCY = complete
ENABLE_TESTABILITY = YES

// Code Signing
DEVELOPMENT_TEAM = YOUR_TEAM_ID

// Build Settings
GCC_PREPROCESSOR_DEFINITIONS = $(inherited)
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited)

// API Configuration (to be overridden)
API_TIMEOUT = 30
LOG_LEVEL = info
ENABLE_ANALYTICS = false
ENABLE_CRASHLYTICS = false
```

---

### 2. Development.xcconfig

**Propósito**: Configuración para ambiente de desarrollo

```ruby
// Development.xcconfig
#include "Base.xcconfig"

// Environment Info
ENVIRONMENT_NAME = Development

// API Configuration
API_BASE_URL = https:/$()/api.dev.edugo.com
API_TIMEOUT = 60

// Logging
LOG_LEVEL = debug

// Features
ENABLE_ANALYTICS = false
ENABLE_CRASHLYTICS = false

// Bundle Configuration
PRODUCT_BUNDLE_IDENTIFIER = com.edugo.app.dev
PRODUCT_NAME = $(inherited) α
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon-Dev

// Build Settings
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) DEBUG DEVELOPMENT
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) DEBUG=1 DEVELOPMENT=1
```

**Notas**:
- `$(inherited)` mantiene valores de Base.xcconfig
- `https:/$()/` es workaround para comentarios `//` en URLs
- `α` (alpha) en nombre para distinguir visualmente

---

### 3. Staging.xcconfig

```ruby
// Staging.xcconfig
#include "Base.xcconfig"

// Environment Info
ENVIRONMENT_NAME = Staging

// API Configuration
API_BASE_URL = https:/$()/api.staging.edugo.com
API_TIMEOUT = 45

// Logging
LOG_LEVEL = info

// Features
ENABLE_ANALYTICS = true
ENABLE_CRASHLYTICS = true

// Bundle Configuration
PRODUCT_BUNDLE_IDENTIFIER = com.edugo.app.staging
PRODUCT_NAME = $(inherited) β
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon-Staging

// Build Settings
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) STAGING
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) STAGING=1
```

---

### 4. Production.xcconfig

```ruby
// Production.xcconfig
#include "Base.xcconfig"

// Environment Info
ENVIRONMENT_NAME = Production

// API Configuration
API_BASE_URL = https:/$()/api.edugo.com
API_TIMEOUT = 30

// Logging
LOG_LEVEL = warning

// Features
ENABLE_ANALYTICS = true
ENABLE_CRASHLYTICS = true

// Bundle Configuration
PRODUCT_BUNDLE_IDENTIFIER = com.edugo.app
PRODUCT_NAME = $(inherited)
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon

// Build Settings
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) PRODUCTION RELEASE
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) PRODUCTION=1
```

---

### 5. Local.xcconfig

```ruby
// Local.xcconfig
#include "Base.xcconfig"

// Environment Info
ENVIRONMENT_NAME = Local

// API Configuration
API_BASE_URL = http:/$()/localhost:8080
API_TIMEOUT = 90

// Logging
LOG_LEVEL = debug

// Features
ENABLE_ANALYTICS = false
ENABLE_CRASHLYTICS = false

// Bundle Configuration
PRODUCT_BUNDLE_IDENTIFIER = com.edugo.app.local
PRODUCT_NAME = $(inherited) 🏠
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon-Local

// Build Settings
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) DEBUG LOCAL
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) DEBUG=1 LOCAL=1
```

---

### 6. Docker.xcconfig

```ruby
// Docker.xcconfig
#include "Base.xcconfig"

// Environment Info
ENVIRONMENT_NAME = Docker

// API Configuration
API_BASE_URL = http:/$()/host.docker.internal:8080
API_TIMEOUT = 90

// Logging
LOG_LEVEL = debug

// Features
ENABLE_ANALYTICS = false
ENABLE_CRASHLYTICS = false

// Bundle Configuration
PRODUCT_BUNDLE_IDENTIFIER = com.edugo.app.docker
PRODUCT_NAME = $(inherited) 🐳
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon-Docker

// Build Settings
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) DEBUG DOCKER
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) DEBUG=1 DOCKER=1
```

---

### 7. TestContainer.xcconfig

```ruby
// TestContainer.xcconfig
#include "Base.xcconfig"

// Environment Info
ENVIRONMENT_NAME = TestContainer

// API Configuration
API_BASE_URL = http:/$()/localhost:0
API_TIMEOUT = 120

// Logging
LOG_LEVEL = debug

// Features
ENABLE_ANALYTICS = false
ENABLE_CRASHLYTICS = false

// Bundle Configuration
PRODUCT_BUNDLE_IDENTIFIER = com.edugo.app.testcontainer
PRODUCT_NAME = $(inherited) 🧪
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon

// Build Settings
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) DEBUG TESTING
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) DEBUG=1 TESTING=1
```

---

## 📝 Info.plist Configuration

### Inyección de Variables

**Archivo**: `apple-app/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- ... otras configuraciones ... -->
    
    <!-- Environment Configuration -->
    <key>EnvironmentName</key>
    <string>$(ENVIRONMENT_NAME)</string>
    
    <key>APIBaseURL</key>
    <string>$(API_BASE_URL)</string>
    
    <key>APITimeout</key>
    <string>$(API_TIMEOUT)</string>
    
    <key>LogLevel</key>
    <string>$(LOG_LEVEL)</string>
    
    <key>EnableAnalytics</key>
    <string>$(ENABLE_ANALYTICS)</string>
    
    <key>EnableCrashlytics</key>
    <string>$(ENABLE_CRASHLYTICS)</string>
</dict>
</plist>
```

**Nota**: Las variables se reemplazan en build time

---

## 💻 Swift API: Environment.swift

### Diseño de la API

**Archivo**: `apple-app/App/Environment.swift`

```swift
//
//  Environment.swift
//  apple-app
//
//  Created on 23-11-25.
//

import Foundation

/// Sistema de configuración de ambientes basado en .xcconfig files
/// Lee configuración desde Info.plist en runtime
enum Environment {
    
    // MARK: - Environment Type
    
    /// Tipos de ambiente soportados
    enum EnvironmentType: String {
        case development = "Development"
        case staging = "Staging"
        case production = "Production"
        case local = "Local"
        case qa = "QA"
        case docker = "Docker"
        case testContainer = "TestContainer"
        
        var isProduction: Bool {
            self == .production
        }
        
        var isDevelopment: Bool {
            self == .development || self == .local || self == .docker
        }
        
        var isTesting: Bool {
            self == .testContainer
        }
    }
    
    // MARK: - Log Level
    
    /// Niveles de logging
    enum LogLevel: String {
        case debug
        case info
        case notice
        case warning
        case error
        case critical
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .notice: return .default
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
    }
    
    // MARK: - Current Environment
    
    /// Ambiente actual (leído de Info.plist)
    static var current: EnvironmentType {
        guard let envString = infoDictionary["EnvironmentName"] as? String,
              let environment = EnvironmentType(rawValue: envString) else {
            assertionFailure("⚠️ EnvironmentName no encontrado en Info.plist")
            return .development // Fallback seguro
        }
        return environment
    }
    
    // MARK: - API Configuration
    
    /// URL base del API (ej: https://api.dev.edugo.com)
    static var apiBaseURL: URL {
        guard let urlString = infoDictionary["APIBaseURL"] as? String else {
            fatalError("❌ APIBaseURL no encontrado en Info.plist")
        }
        
        // Limpiar el workaround de .xcconfig (https:/$()/domain -> https://domain)
        let cleanedURL = urlString.replacingOccurrences(of: "https:/$()/", with: "https://")
                                   .replacingOccurrences(of: "http:/$()/", with: "http://")
        
        guard let url = URL(string: cleanedURL) else {
            fatalError("❌ APIBaseURL inválido: \(cleanedURL)")
        }
        
        return url
    }
    
    /// Timeout para requests HTTP (en segundos)
    static var apiTimeout: TimeInterval {
        guard let timeoutString = infoDictionary["APITimeout"] as? String,
              let timeout = TimeInterval(timeoutString) else {
            assertionFailure("⚠️ APITimeout no encontrado, usando default 30s")
            return 30
        }
        return timeout
    }
    
    // MARK: - Logging Configuration
    
    /// Nivel de logging configurado
    static var logLevel: LogLevel {
        guard let levelString = infoDictionary["LogLevel"] as? String,
              let level = LogLevel(rawValue: levelString) else {
            assertionFailure("⚠️ LogLevel no encontrado, usando default .info")
            return .info
        }
        return level
    }
    
    // MARK: - Feature Flags
    
    /// Analytics habilitado
    static var analyticsEnabled: Bool {
        guard let value = infoDictionary["EnableAnalytics"] as? String else {
            return false
        }
        return value.lowercased() == "true"
    }
    
    /// Crashlytics habilitado
    static var crashlyticsEnabled: Bool {
        guard let value = infoDictionary["EnableCrashlytics"] as? String else {
            return false
        }
        return value.lowercased() == "true"
    }
    
    // MARK: - Helpers
    
    /// Diccionario de Info.plist
    private static var infoDictionary: [String: Any] {
        Bundle.main.infoDictionary ?? [:]
    }
    
    /// Nombre descriptivo del ambiente
    static var displayName: String {
        current.rawValue
    }
    
    /// Indica si estamos en ambiente de producción
    static var isProduction: Bool {
        current.isProduction
    }
    
    /// Indica si estamos en ambiente de desarrollo
    static var isDevelopment: Bool {
        current.isDevelopment
    }
    
    // MARK: - Debug Info
    
    /// Imprime información de configuración (solo en debug)
    static func printDebugInfo() {
        #if DEBUG
        print("""
        
        🌍 Environment Configuration:
        ════════════════════════════════════════
        Environment:    \(current.rawValue)
        API URL:        \(apiBaseURL.absoluteString)
        Timeout:        \(apiTimeout)s
        Log Level:      \(logLevel.rawValue)
        Analytics:      \(analyticsEnabled ? "✅" : "❌")
        Crashlytics:    \(crashlyticsEnabled ? "✅" : "❌")
        ════════════════════════════════════════
        
        """)
        #endif
    }
}

// MARK: - Deprecations

@available(*, deprecated, message: "Use Environment.current.apiBaseURL instead")
typealias AppConfig = Never
```

---

## 🎨 Xcode Configuration

### Build Configurations

Crear en Xcode Project Settings:

| Configuration | Based On | xcconfig File |
|---------------|----------|---------------|
| Debug-Development | Debug | Development.xcconfig |
| Debug-Staging | Debug | Staging.xcconfig |
| Debug-Local | Debug | Local.xcconfig |
| Debug-Docker | Debug | Docker.xcconfig |
| Debug-QA | Debug | QA.xcconfig |
| Debug-TestContainer | Debug | TestContainer.xcconfig |
| Release-Production | Release | Production.xcconfig |

### Schemes

Crear schemes correspondientes:

| Scheme | Build Configuration | Purpose |
|--------|---------------------|---------|
| EduGo-Dev | Debug-Development | Desarrollo diario |
| EduGo-Staging | Debug-Staging | Testing pre-prod |
| EduGo-Local | Debug-Local | Backend local |
| EduGo-Docker | Debug-Docker | Container local |
| EduGo-QA | Debug-QA | QA testing |
| EduGo-Tests | Debug-TestContainer | Integration tests |
| EduGo | Release-Production | Producción |

---

## 🔒 Secrets Management

### .gitignore Configuration

```gitignore
# Xcode Config Files
Configs/*.xcconfig

# Excepto Base
!Configs/Base.xcconfig
```

### Template System

**Archivo**: `Configs-Templates/Development.xcconfig.template`

```ruby
// Development.xcconfig.template
// Copy este archivo a Configs/Development.xcconfig y llena los valores

#include "Base.xcconfig"

// Environment Info
ENVIRONMENT_NAME = Development

// API Configuration
API_BASE_URL = https:/$()/api.dev.edugo.com
API_TIMEOUT = 60

// Secrets (LLENAR AQUÍ)
// API_KEY = your_dev_api_key_here
// SENTRY_DSN = your_sentry_dsn_here

// ... resto de configuración ...
```

### CI/CD Integration

**GitHub Actions** - Generar .xcconfig en runtime:

```yaml
- name: Generate xcconfig
  run: |
    cat > Configs/Staging.xcconfig << EOF
    #include "Base.xcconfig"
    ENVIRONMENT_NAME = Staging
    API_BASE_URL = https:/\$()/api.staging.edugo.com
    API_KEY = ${{ secrets.STAGING_API_KEY }}
    EOF
```

---

## 🧪 Testing Strategy

### Unit Tests

**Archivo**: `apple-appTests/Core/EnvironmentTests.swift`

```swift
import XCTest
@testable import apple_app

final class EnvironmentTests: XCTestCase {
    
    func testCurrentEnvironmentIsValid() {
        // Given: App está corriendo
        
        // When: Leemos ambiente actual
        let environment = Environment.current
        
        // Then: Debe ser un ambiente válido
        XCTAssertNotNil(environment)
    }
    
    func testAPIBaseURLIsValid() {
        // Given: Configuración cargada
        
        // When: Leemos API URL
        let url = Environment.apiBaseURL
        
        // Then: Debe ser una URL válida
        XCTAssertNotNil(url.scheme)
        XCTAssertNotNil(url.host)
    }
    
    func testAPITimeoutIsPositive() {
        // Given: Configuración cargada
        
        // When: Leemos timeout
        let timeout = Environment.apiTimeout
        
        // Then: Debe ser > 0
        XCTAssertGreaterThan(timeout, 0)
    }
    
    func testLogLevelIsConfigured() {
        // Given: Configuración cargada
        
        // When: Leemos log level
        let logLevel = Environment.logLevel
        
        // Then: Debe ser un nivel válido
        XCTAssertNotNil(logLevel)
    }
}
```

---

## 📊 Migration Strategy

### Fase 1: Setup (Sin Romper Código Existente)
1. Crear carpeta `Configs/`
2. Crear archivos .xcconfig
3. Crear `Environment.swift`
4. Configurar Xcode (build configs + schemes)
5. Actualizar Info.plist

### Fase 2: Coexistencia
1. Mantener `AppConfig.swift`
2. Agregar `@available(*, deprecated)` a AppConfig
3. Tests pasan con ambos sistemas

### Fase 3: Migración Gradual
1. Reemplazar usos de `AppConfig` con `Environment`
2. Actualizar tests
3. Validar en todos los ambientes

### Fase 4: Limpieza
1. Eliminar `AppConfig.swift`
2. Eliminar código deprecated
3. Actualizar documentación

---

## 📚 Referencias Técnicas

### Buenas Prácticas
- [NSHipster - xcconfig Files](https://nshipster.com/xcconfig/)
- [12 Factor App - Config](https://12factor.net/config)
- [Apple - Adding Build Configuration](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project)

### Ejemplos de la Industria
- [Firebase iOS SDK Configuration](https://firebase.google.com/docs/ios/learn-more#multiple_environments)
- [Tuist Environment Configuration](https://docs.tuist.io/guides/environment)

---

**Próximos Pasos**: Ver [03-tareas.md](03-tareas.md) para plan de implementación detallado
