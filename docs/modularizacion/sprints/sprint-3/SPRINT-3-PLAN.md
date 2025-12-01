# Sprint 3 - Infraestructura Nivel 2: DataLayer & SecurityKit

**Duración**: 6 días (5 días desarrollo + 1 día buffer)  
**Complejidad**: ⚠️ ALTA - Módulos más complejos con interdependencias  
**Fecha Inicio**: TBD  
**Fecha Fin**: TBD

---

## 🎯 Objetivos del Sprint

Este sprint crea los módulos de infraestructura más complejos del proyecto, unificando Storage, Networking, Auth y Security en dos packages robustos.

### Módulos a Crear

1. **EduGoDataLayer** (~5,000 líneas)
   - Storage (SwiftData models + Cache helpers)
   - Networking (APIClient + Interceptors + Endpoints)
   - Sync (OfflineQueue + NetworkSyncCoordinator)
   - DTOs (LoginDTO, UserDTO, FeatureFlagDTO)
   - DataSources (LocalDataSource)

2. **EduGoSecurityKit** (~4,000 líneas)
   - Auth (JWT + Token management)
   - Network Security (SSL Pinning + SecureSessionDelegate)
   - Validation (SecurityValidator)
   - Errors (SecurityError)

### Objetivos Clave

- ✅ Migrar toda la capa de datos a módulo independiente
- ✅ Centralizar lógica de seguridad en un solo módulo
- ✅ Resolver interdependencias sin crear ciclos
- ✅ Mantener auth flow end-to-end funcional
- ✅ Tests de integración exhaustivos (críticos)

---

## 📋 Pre-requisitos

### Módulos Disponibles
- ✅ EduGoFoundation
- ✅ EduGoDesignSystem
- ✅ EduGoDomainCore
- ✅ EduGoObservability
- ✅ EduGoSecureStorage

### Conocimientos Requeridos
- SwiftData y persistencia
- URLSession y networking avanzado
- SSL Pinning
- JWT y token management
- Resolución de dependencias complejas

### Estado del Código
- Auth flow completamente funcional
- Interceptors implementados
- OfflineQueue operativo
- Tests existentes para referencia

---

## 🗂️ Estructura a Crear

### 1. EduGoDataLayer

```
Modules/EduGoDataLayer/
├── Package.swift
├── Sources/
│   └── EduGoDataLayer/
│       ├── Storage/
│       │   ├── SwiftData/
│       │   │   ├── CachedUser.swift
│       │   │   ├── CachedFeatureFlag.swift
│       │   │   ├── CachedHTTPResponse.swift
│       │   │   ├── SyncQueueItem.swift
│       │   │   └── AppSettings.swift
│       │   └── Cache/
│       │       ├── ResponseCache.swift
│       │       └── LocalDataSource.swift
│       ├── Networking/
│       │   ├── Client/
│       │   │   ├── APIClient.swift
│       │   │   ├── Endpoint.swift
│       │   │   └── HTTPMethod.swift
│       │   ├── Interceptors/
│       │   │   ├── RequestInterceptor.swift
│       │   │   ├── ResponseInterceptor.swift
│       │   │   ├── LoggingInterceptor.swift
│       │   │   ├── SecurityGuardInterceptor.swift
│       │   │   └── AuthInterceptor.swift
│       │   ├── Endpoints/
│       │   │   └── AuthEndpoints.swift
│       │   ├── Security/
│       │   │   └── SecureSessionDelegate.swift
│       │   └── Monitoring/
│       │       ├── NetworkMonitor.swift
│       │       └── RetryPolicy.swift
│       ├── Sync/
│       │   ├── OfflineQueue.swift
│       │   └── NetworkSyncCoordinator.swift
│       └── DTOs/
│           ├── Auth/
│           │   ├── LoginDTO.swift
│           │   ├── RefreshDTO.swift
│           │   ├── LogoutDTO.swift
│           │   └── DummyJSONDTO.swift
│           └── FeatureFlags/
│               ├── FeatureFlagDTO.swift
│               └── FeatureFlagsResponseDTO.swift
└── Tests/
    └── EduGoDataLayerTests/
        ├── Network/
        │   ├── APIClientTests.swift
        │   └── InterceptorsTests.swift
        ├── Sync/
        │   └── OfflineQueueTests.swift
        └── Storage/
            └── CacheTests.swift
```

**Dependencias**:
```swift
dependencies: [
    .product(name: "EduGoFoundation", package: "EduGoFoundation"),
    .product(name: "EduGoObservability", package: "EduGoObservability"),
    .product(name: "EduGoSecureStorage", package: "EduGoSecureStorage"),
    .product(name: "EduGoDomainCore", package: "EduGoDomainCore"),
    // EduGoSecurityKit se agregará después de resolver interdependencias
]
```

### 2. EduGoSecurityKit

```
Modules/EduGoSecurityKit/
├── Package.swift
├── Sources/
│   └── EduGoSecurityKit/
│       ├── Auth/
│       │   ├── JWT/
│       │   │   ├── JWTDecoder.swift
│       │   │   └── JWTPayload.swift
│       │   ├── Token/
│       │   │   └── TokenRefreshCoordinator.swift
│       │   └── Session/
│       │       └── AuthTokenProvider.swift (protocol)
│       ├── Network/
│       │   └── SSLPinning/
│       │       └── CertificatePinner.swift
│       ├── Validation/
│       │   └── SecurityValidator.swift
│       └── Errors/
│           └── SecurityError.swift
└── Tests/
    └── EduGoSecurityKitTests/
        ├── Auth/
        │   ├── JWTDecoderTests.swift
        │   └── TokenRefreshCoordinatorTests.swift
        └── Network/
            └── CertificatePinnerTests.swift
```

**Dependencias**:
```swift
dependencies: [
    .product(name: "EduGoFoundation", package: "EduGoFoundation"),
    .product(name: "EduGoObservability", package: "EduGoObservability"),
    .product(name: "EduGoSecureStorage", package: "EduGoSecureStorage"),
    .product(name: "EduGoDomainCore", package: "EduGoDomainCore"),
    // EduGoDataLayer se agregará para acceso a APIClient
]
```

---

## 📝 Tareas Detalladas

### Fase 1: Preparación (0.5 días)

#### T01 - Análisis de Interdependencias
**Estimación**: 2 horas

**Objetivo**: Diseñar estrategia para resolver interdependencias sin crear ciclos.

**Problema**:
- `AuthInterceptor` (DataLayer) necesita `TokenRefreshCoordinator` (SecurityKit)
- `TokenRefreshCoordinator` (SecurityKit) necesita `APIClient` (DataLayer)
- Esto crea una dependencia circular potencial

**Solución**:
1. **Interfaces públicas en módulos separados**:
   - `AuthTokenProvider` protocol en SecurityKit
   - `APIClient` protocol en DataLayer
   
2. **Inyección de dependencias**:
   - TokenRefreshCoordinator recibe APIClient vía DI
   - AuthInterceptor recibe TokenRefreshCoordinator vía DI
   - Ningún módulo "importa" al otro, ambos definen protocolos

3. **Orden de migración**:
   - Primero: EduGoDataLayer (sin AuthInterceptor)
   - Segundo: EduGoSecurityKit (con APIClient como dependencia)
   - Tercero: Agregar AuthInterceptor a DataLayer

**Entregables**:
- Diagrama de dependencias resuelto
- Decisiones documentadas en `/docs/modularizacion/sprints/sprint-3/DECISIONES.md`

---

#### T02 - Crear Estructura Base de Packages
**Estimación**: 1 hora

**Pasos**:
```bash
cd Modules

# DataLayer
mkdir -p EduGoDataLayer/Sources/EduGoDataLayer/{Storage,Networking,Sync,DTOs}
mkdir -p EduGoDataLayer/Tests/EduGoDataLayerTests

# SecurityKit
mkdir -p EduGoSecurityKit/Sources/EduGoSecurityKit/{Auth,Network,Validation,Errors}
mkdir -p EduGoSecurityKit/Tests/EduGoSecurityKitTests
```

**Package.swift inicial** (DataLayer):
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EduGoDataLayer",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoDataLayer",
            targets: ["EduGoDataLayer"]
        )
    ],
    dependencies: [
        .package(path: "../EduGoFoundation"),
        .package(path: "../EduGoObservability"),
        .package(path: "../EduGoSecureStorage"),
        .package(path: "../EduGoDomainCore")
    ],
    targets: [
        .target(
            name: "EduGoDataLayer",
            dependencies: [
                .product(name: "EduGoFoundation", package: "EduGoFoundation"),
                .product(name: "EduGoObservability", package: "EduGoObservability"),
                .product(name: "EduGoSecureStorage", package: "EduGoSecureStorage"),
                .product(name: "EduGoDomainCore", package: "EduGoDomainCore")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EduGoDataLayerTests",
            dependencies: ["EduGoDataLayer"]
        )
    ]
)
```

**Package.swift inicial** (SecurityKit):
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EduGoSecurityKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoSecurityKit",
            targets: ["EduGoSecurityKit"]
        )
    ],
    dependencies: [
        .package(path: "../EduGoFoundation"),
        .package(path: "../EduGoObservability"),
        .package(path: "../EduGoSecureStorage"),
        .package(path: "../EduGoDomainCore")
    ],
    targets: [
        .target(
            name: "EduGoSecurityKit",
            dependencies: [
                .product(name: "EduGoFoundation", package: "EduGoFoundation"),
                .product(name: "EduGoObservability", package: "EduGoObservability"),
                .product(name: "EduGoSecureStorage", package: "EduGoSecureStorage"),
                .product(name: "EduGoDomainCore", package: "EduGoDomainCore")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EduGoSecurityKitTests",
            dependencies: ["EduGoSecurityKit"]
        )
    ]
)
```

**Validación**:
```bash
cd EduGoDataLayer && swift build
cd ../EduGoSecurityKit && swift build
```

---

### Fase 2: EduGoDataLayer - Storage (1 día)

#### T03 - Migrar SwiftData Models
**Estimación**: 3 horas

**Archivos a migrar**:
```
apple-app/Data/Models/Cache/CachedUser.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Storage/SwiftData/CachedUser.swift

apple-app/Data/Models/Cache/CachedFeatureFlag.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Storage/SwiftData/CachedFeatureFlag.swift

apple-app/Data/Models/Cache/CachedHTTPResponse.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Storage/SwiftData/CachedHTTPResponse.swift

apple-app/Data/Models/Cache/SyncQueueItem.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Storage/SwiftData/SyncQueueItem.swift

apple-app/Data/Models/Cache/AppSettings.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Storage/SwiftData/AppSettings.swift
```

**Consideraciones**:
- Todos son `@Model` de SwiftData
- Mantener `import SwiftData`
- Agregar `import EduGoDomainCore` para entidades
- Verificar que compile en todas las plataformas

**Comando migración**:
```bash
# Copiar archivos
cp apple-app/Data/Models/Cache/*.swift \
   Modules/EduGoDataLayer/Sources/EduGoDataLayer/Storage/SwiftData/

# Ajustar imports en cada archivo
# Cambiar: import Foundation
# Agregar: import SwiftData
#         import EduGoDomainCore
```

**Validación**:
```bash
cd Modules/EduGoDataLayer
swift build  # Debe compilar sin errores
```

---

#### T04 - Migrar Cache Helpers
**Estimación**: 2 horas

**Archivos**:
```
apple-app/Data/Network/ResponseCache.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Storage/Cache/ResponseCache.swift

apple-app/Data/DataSources/LocalDataSource.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Storage/Cache/LocalDataSource.swift
```

**Ajustes**:
- `ResponseCache`: Ya está bien aislado
- `LocalDataSource`: Verificar dependencias con SwiftData models

**Validación**:
```bash
cd Modules/EduGoDataLayer
swift build
```

---

### Fase 3: EduGoDataLayer - Networking (1.5 días)

#### T05 - Migrar Core Networking (Client Base)
**Estimación**: 4 horas

**Archivos**:
```
apple-app/Data/Network/HTTPMethod.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Networking/Client/HTTPMethod.swift

apple-app/Data/Network/Endpoint.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Networking/Client/Endpoint.swift

apple-app/Data/Network/APIClient.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Networking/Client/APIClient.swift (TEMPORAL - sin AuthInterceptor)
```

**Consideraciones CRÍTICAS**:
- **NO migrar AuthInterceptor todavía** (depende de SecurityKit)
- Comentar uso de AuthInterceptor en APIClient
- Agregar `import EduGoObservability` para Logger
- Agregar `import EduGoSecureStorage` para KeychainService (SecureSessionDelegate)

**Ajustes en APIClient.swift**:
```swift
// TEMPORAL: Comentar AuthInterceptor hasta que SecurityKit esté listo
// private let authInterceptor: AuthInterceptor

init(
    // ...
    requestInterceptors: [RequestInterceptor] = []  // Sin AuthInterceptor por ahora
) {
    // ...
}
```

---

#### T06 - Migrar Interceptors (Excepto Auth)
**Estimación**: 2 horas

**Archivos**:
```
apple-app/Data/Network/Interceptors/RequestInterceptor.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Networking/Interceptors/RequestInterceptor.swift

apple-app/Data/Network/Interceptors/LoggingInterceptor.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Networking/Interceptors/LoggingInterceptor.swift

apple-app/Data/Network/Interceptors/SecurityGuardInterceptor.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Networking/Interceptors/SecurityGuardInterceptor.swift

(AuthInterceptor.swift - SE MIGRA EN T12)
```

**Nota**: Dejar `ResponseInterceptor` por ahora si no existe, se puede agregar después.

---

#### T07 - Migrar Endpoints y Monitoring
**Estimación**: 2 horas

**Archivos**:
```
apple-app/Data/Network/Endpoints/AuthEndpoints.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Networking/Endpoints/AuthEndpoints.swift

apple-app/Data/Network/NetworkMonitor.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Networking/Monitoring/NetworkMonitor.swift

apple-app/Data/Network/RetryPolicy.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Networking/Monitoring/RetryPolicy.swift

apple-app/Data/Network/SecureSessionDelegate.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Networking/Security/SecureSessionDelegate.swift
```

**Ajustes**:
- `SecureSessionDelegate`: Necesita `CertificatePinner` de SecurityKit (temporal: comentar o usar protocol)
- `AuthEndpoints`: Verificar que `Endpoint` esté disponible

---

### Fase 4: EduGoDataLayer - Sync y DTOs (0.5 días)

#### T08 - Migrar Sync Components
**Estimación**: 2 horas

**Archivos**:
```
apple-app/Data/Network/OfflineQueue.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Sync/OfflineQueue.swift

apple-app/Data/Network/NetworkSyncCoordinator.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Sync/NetworkSyncCoordinator.swift
```

**Dependencias**:
- `NetworkMonitor` (ya migrado en T07)
- `ConflictResolver` (en DomainCore)
- `LocalDataSource` (ya migrado en T04)

---

#### T09 - Migrar DTOs
**Estimación**: 1.5 horas

**Archivos**:
```
apple-app/Data/DTOs/Auth/*.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/DTOs/Auth/

apple-app/Data/DTOs/FeatureFlags/*.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/DTOs/FeatureFlags/
```

**Archivos específicos**:
- `LoginDTO.swift`
- `RefreshDTO.swift`
- `LogoutDTO.swift`
- `DummyJSONDTO.swift`
- `FeatureFlagDTO.swift`
- `FeatureFlagsResponseDTO.swift`

**Validación**:
```bash
cd Modules/EduGoDataLayer
swift build  # Debe compilar completamente
./run.sh test  # Correr tests si existen
```

---

### Fase 5: EduGoSecurityKit (1.5 días)

#### T10 - Migrar JWT Components
**Estimación**: 3 horas

**Archivos**:
```
apple-app/Data/Services/Auth/JWTDecoder.swift
→ EduGoSecurityKit/Sources/EduGoSecurityKit/Auth/JWT/JWTDecoder.swift

(Crear JWTPayload.swift si está separado del JWTDecoder)
```

**Dependencias**:
- `import EduGoFoundation` (para Result, AppError)
- `import EduGoDomainCore` (para User entity)

**Validación**:
```bash
cd Modules/EduGoSecurityKit
swift build
```

---

#### T11 - Migrar Token Management
**Estimación**: 3 horas

**CRÍTICO**: Este paso introduce la primera dependencia DataLayer → SecurityKit.

**Archivos**:
```
apple-app/Data/Services/Auth/TokenRefreshCoordinator.swift
→ EduGoSecurityKit/Sources/EduGoSecurityKit/Auth/Token/TokenRefreshCoordinator.swift
```

**Ajustes en Package.swift de SecurityKit**:
```swift
dependencies: [
    // ... existentes ...
    .package(path: "../EduGoDataLayer")  // ← NUEVO
],
targets: [
    .target(
        name: "EduGoSecurityKit",
        dependencies: [
            // ... existentes ...
            .product(name: "EduGoDataLayer", package: "EduGoDataLayer")  // ← NUEVO
        ],
        // ...
    )
]
```

**Imports necesarios**:
```swift
import EduGoDataLayer  // Para APIClient, Endpoint, HTTPMethod
import EduGoSecureStorage  // Para KeychainService
import EduGoObservability  // Para Logger (si usa)
```

**Validación**:
```bash
cd Modules/EduGoSecurityKit
swift build  # Debe resolver dependencia circular correctamente
```

---

#### T12 - Migrar SSL Pinning y Validators
**Estimación**: 2 horas

**Archivos**:
```
apple-app/Data/Services/Security/CertificatePinner.swift
→ EduGoSecurityKit/Sources/EduGoSecurityKit/Network/SSLPinning/CertificatePinner.swift

apple-app/Data/Services/Security/SecurityValidator.swift
→ EduGoSecurityKit/Sources/EduGoSecurityKit/Validation/SecurityValidator.swift

apple-app/Data/Services/Security/SecurityError.swift
→ EduGoSecurityKit/Sources/EduGoSecurityKit/Errors/SecurityError.swift
```

**Nota**: `BiometricAuthService` ya fue migrado en Sprint 2 a EduGoSecureStorage.

---

### Fase 6: Cerrar Ciclo - AuthInterceptor (0.5 días)

#### T13 - Migrar AuthInterceptor y Actualizar DataLayer
**Estimación**: 3 horas

**CRÍTICO**: Este es el paso que cierra el ciclo de dependencias.

**Paso 1**: Actualizar Package.swift de DataLayer
```swift
dependencies: [
    // ... existentes ...
    .package(path: "../EduGoSecurityKit")  // ← NUEVO
],
targets: [
    .target(
        name: "EduGoDataLayer",
        dependencies: [
            // ... existentes ...
            .product(name: "EduGoSecurityKit", package: "EduGoSecurityKit")  // ← NUEVO
        ],
        // ...
    )
]
```

**Paso 2**: Migrar AuthInterceptor
```
apple-app/Data/Network/Interceptors/AuthInterceptor.swift
→ EduGoDataLayer/Sources/EduGoDataLayer/Networking/Interceptors/AuthInterceptor.swift
```

**Imports necesarios**:
```swift
import EduGoSecurityKit  // Para TokenRefreshCoordinator
import EduGoObservability  // Para Logger (si usa)
```

**Paso 3**: Descomentar uso de AuthInterceptor en APIClient.swift

**Validación CRÍTICA**:
```bash
# Compilar ambos módulos
cd Modules/EduGoDataLayer && swift build
cd ../EduGoSecurityKit && swift build

# Verificar que no hay dependencia circular
# Si hay circular dependency, Swift Package Manager fallará
```

**Resultado esperado**: Ambos módulos compilan sin errores, sin circular dependency warning.

---

### Fase 7: Integración con App Principal (1 día)

#### T14 - Actualizar Repositories para Usar DataLayer
**Estimación**: 4 horas

**Archivos a actualizar**:
```
apple-app/Data/Repositories/AuthRepositoryImpl.swift
apple-app/Data/Repositories/FeatureFlagRepositoryImpl.swift
apple-app/Data/Repositories/PreferencesRepositoryImpl.swift
```

**Cambios**:
```swift
// ANTES
// (imports locales)

// DESPUÉS
import EduGoDataLayer
import EduGoSecurityKit
import EduGoObservability
import EduGoSecureStorage
```

**Nota**: Los repositorios NO se migran a módulos todavía (eso es Sprint 4). Solo se actualizan para usar los nuevos módulos.

**Validación**:
```bash
./run.sh  # Debe compilar sin errores
```

---

#### T15 - Actualizar DI Container
**Estimación**: 2 horas

**Archivo**: `apple-app/apple_appApp.swift`

**Cambios**:
```swift
import EduGoDataLayer
import EduGoSecurityKit

// Configurar dependencias
let apiClient = DefaultAPIClient(
    baseURL: AppEnvironment.apiBaseURL,
    // ...
    requestInterceptors: [
        LoggingInterceptor(logger: LoggerFactory.network),
        SecurityGuardInterceptor(),
        AuthInterceptor(tokenCoordinator: tokenCoordinator)
    ]
)

let jwtDecoder = JWTDecoder()
let tokenCoordinator = TokenRefreshCoordinator(
    apiClient: apiClient,
    keychainService: DefaultKeychainService.shared,
    jwtDecoder: jwtDecoder
)
```

**Validación**:
```bash
./run.sh  # App debe iniciar correctamente
```

---

### Fase 8: Validación y Tests (1 día)

#### T16 - Validación Multi-Plataforma
**Estimación**: 2 horas

**CRÍTICO**: Compilar para TODAS las plataformas.

```bash
# iOS
./run.sh
xcodebuild -scheme EduGo-Dev \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build

# macOS
./run.sh macos
xcodebuild -scheme EduGo-Dev \
  -destination 'platform=macOS' \
  build

# Tests
./run.sh test
```

**Checklist**:
- [ ] iOS compila sin errores
- [ ] macOS compila sin errores
- [ ] Tests pasan
- [ ] No hay warnings de concurrencia
- [ ] No hay circular dependency warnings

---

#### T17 - Tests de Integración Auth Flow
**Estimación**: 4 horas

**CRÍTICO**: El auth flow es el más complejo, debe funcionar end-to-end.

**Tests a crear/actualizar**:
```
apple-appTests/Integration/AuthFlowIntegrationTests.swift
```

**Casos de prueba**:
```swift
func testLoginFlow() async throws {
    // 1. Login con credenciales
    // 2. Verificar que se guarda token
    // 3. Verificar que APIClient usa token
    // 4. Hacer request autenticado
}

func testTokenRefreshFlow() async throws {
    // 1. Login
    // 2. Forzar token expirado
    // 3. Hacer request (debe auto-refresh)
    // 4. Verificar nuevo token
}

func testLogoutFlow() async throws {
    // 1. Login
    // 2. Logout
    // 3. Verificar limpieza de tokens
    // 4. Verificar request falla con unauthorized
}

func testOfflineQueueFlow() async throws {
    // 1. Simular offline
    // 2. Hacer request (debe encolar)
    // 3. Simular online
    // 4. Verificar procesamiento de cola
}
```

**Validación**:
```bash
./run.sh test
# Todos los tests de integración deben pasar
```

---

#### T18 - Documentación
**Estimación**: 2 horas

**Archivos a crear/actualizar**:

1. **README de DataLayer**:
```
Modules/EduGoDataLayer/README.md
```

Contenido:
- Propósito del módulo
- Componentes principales
- Uso de APIClient
- Uso de OfflineQueue
- Ejemplos de código

2. **README de SecurityKit**:
```
Modules/EduGoSecurityKit/README.md
```

Contenido:
- Propósito del módulo
- JWT handling
- Token refresh strategy
- SSL Pinning
- Ejemplos de código

3. **Decisiones de diseño**:
```
docs/modularizacion/sprints/sprint-3/DECISIONES.md
```

Contenido:
- Cómo se resolvió la dependencia circular
- Por qué DataLayer y SecurityKit se dependen mutuamente
- Alternativas consideradas y descartadas
- Lecciones aprendidas

---

### Fase 9: Tracking y PR (0.5 días)

#### T19 - Actualizar Tracking
**Estimación**: 1 hora

**Archivos**:
```
docs/modularizacion/tracking/SPRINT-3-TRACKING.md
docs/modularizacion/tracking/MODULARIZACION-PROGRESS.md
```

**Actualizar**:
- Estado de todas las tareas
- Problemas encontrados
- Tiempo real vs estimado
- Progreso general (Sprint 3 completado)

---

#### T20 - Crear PR y Merge
**Estimación**: 2 horas

**Branch**: `feature/sprint-3-data-security`

**PR Checklist**:
- [ ] Código compila en iOS, macOS
- [ ] Tests pasan
- [ ] Sin warnings de concurrencia
- [ ] Sin circular dependencies
- [ ] Auth flow funciona end-to-end
- [ ] Documentación actualizada
- [ ] TRACKING.md actualizado

**PR Title**:
```
feat(modularizacion): Sprint 3 - DataLayer y SecurityKit
```

**PR Description**:
```markdown
## Sprint 3 - Infraestructura Nivel 2

Migración de Storage, Networking, Auth y Security a módulos SPM independientes.

### Módulos Creados
- ✅ EduGoDataLayer (~5,000 líneas)
- ✅ EduGoSecurityKit (~4,000 líneas)

### Componentes Migrados
**DataLayer**:
- Storage (SwiftData models, Cache)
- Networking (APIClient, Interceptors, Endpoints)
- Sync (OfflineQueue, NetworkSyncCoordinator)
- DTOs (Auth, FeatureFlags)

**SecurityKit**:
- Auth (JWT, TokenRefresh)
- Network Security (SSL Pinning)
- Validation (SecurityValidator)

### Resolución de Interdependencias
- DataLayer depende de SecurityKit (TokenRefreshCoordinator)
- SecurityKit depende de DataLayer (APIClient)
- Resuelto mediante protocolos e inyección de dependencias
- Sin dependencias circulares

### Testing
- ✅ Tests de integración auth flow
- ✅ Tests de offline queue
- ✅ Validación multi-plataforma (iOS, macOS)

### Files Changed
- ~120 archivos modificados
- ~9,000 líneas migradas

Closes #XXX
```

---

## ⚠️ Configuración Manual Xcode

**IMPORTANTE**: Este sprint SÍ REQUIERE configuración manual en Xcode debido a las dependencias complejas.

Ver guía detallada: [`docs/modularizacion/guias-xcode/GUIA-SPRINT-3.md`](../guias-xcode/GUIA-SPRINT-3.md)

### Pasos Esenciales

1. **Agregar EduGoDataLayer al proyecto**
   - File → Add Package Dependencies
   - Add Local... → Seleccionar `Modules/EduGoDataLayer`
   - Target: `apple-app`

2. **Agregar EduGoSecurityKit al proyecto**
   - File → Add Package Dependencies
   - Add Local... → Seleccionar `Modules/EduGoSecurityKit`
   - Target: `apple-app`

3. **Verificar orden de linking**
   - Build Phases → Link Binary With Libraries
   - Asegurar que SecurityKit esté ANTES de DataLayer (si hay problemas)

4. **Limpiar build**
   - Product → Clean Build Folder (Cmd+Shift+K)
   - Eliminar DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`

5. **Validar dependencias**
   - Build para iOS
   - Build para macOS
   - Verificar que no hay warnings de circular dependencies

---

## 📊 Estimación de Tiempos

| Fase | Tareas | Estimación |
|------|--------|------------|
| Preparación | T01-T02 | 0.5 días |
| DataLayer - Storage | T03-T04 | 1 día |
| DataLayer - Networking | T05-T07 | 1.5 días |
| DataLayer - Sync/DTOs | T08-T09 | 0.5 días |
| SecurityKit | T10-T12 | 1.5 días |
| Cerrar Ciclo | T13 | 0.5 días |
| Integración | T14-T15 | 1 día |
| Validación/Tests | T16-T18 | 1 día |
| Tracking/PR | T19-T20 | 0.5 días |
| **TOTAL DESARROLLO** | | **8 días** |
| **Buffer** | | **1 día** |
| **TOTAL SPRINT** | | **9 días** |

**Nota**: El buffer es más grande que sprints anteriores debido a la complejidad de las interdependencias.

### Distribución Recomendada

**Días 1-2**: Storage y Networking base (T01-T07)
- Crear packages
- Migrar Storage
- Migrar Networking (sin AuthInterceptor)

**Días 3-4**: SecurityKit completo (T08-T12)
- Migrar Sync/DTOs
- Migrar JWT
- Migrar Token management
- Migrar SSL Pinning

**Día 5**: Cerrar ciclo (T13)
- Migrar AuthInterceptor
- Resolver dependencias complejas

**Días 6-7**: Integración (T14-T17)
- Actualizar repositories
- Actualizar DI
- Tests de integración

**Día 8**: Documentación y validación final (T18-T19)

**Día 9**: Buffer y PR (T20)

---

## ✅ Definition of Done

### Código
- [ ] EduGoDataLayer compila sin errores (iOS, macOS)
- [ ] EduGoSecurityKit compila sin errores (iOS, macOS)
- [ ] App principal compila con nuevos módulos
- [ ] Sin warnings de concurrencia Swift 6
- [ ] Sin circular dependency warnings
- [ ] SwiftLint pasa sin errores

### Funcionalidad
- [ ] Auth flow funciona end-to-end:
  - [ ] Login exitoso
  - [ ] Token refresh automático
  - [ ] Logout limpia sesión
  - [ ] Requests autenticados funcionan
- [ ] OfflineQueue funciona:
  - [ ] Encola requests cuando offline
  - [ ] Procesa cola cuando online
- [ ] SSL Pinning configurado (aunque no validado en dev)

### Tests
- [ ] Tests de integración auth flow pasan
- [ ] Tests de OfflineQueue pasan
- [ ] Tests de JWTDecoder pasan
- [ ] Tests de TokenRefreshCoordinator pasan
- [ ] Coverage mínimo 70% en componentes críticos

### Multi-Plataforma
- [ ] iOS 18 compila y ejecuta
- [ ] macOS 15 compila y ejecuta
- [ ] Tests pasan en ambas plataformas

### Documentación
- [ ] README de EduGoDataLayer completo
- [ ] README de EduGoSecurityKit completo
- [ ] DECISIONES.md documenta resolución de interdependencias
- [ ] SPRINT-3-TRACKING.md actualizado
- [ ] MODULARIZACION-PROGRESS.md actualizado

### Clean Up
- [ ] Archivos originales eliminados de `apple-app/Data/`
- [ ] Imports actualizados en app principal
- [ ] Sin código comentado (excepto TODOs documentados)
- [ ] Sin `print()` statements

### PR
- [ ] Branch creado desde `dev`
- [ ] Commits atómicos y descriptivos
- [ ] PR description completa
- [ ] Reviewers asignados
- [ ] CI/CD pasa (cuando esté configurado)

---

## 🔗 Referencias

### Documentación Proyecto
- [Plan General de Modularización](../../PLAN-MODULARIZACION.md)
- [Guía Xcode Sprint 3](../../guias-xcode/GUIA-SPRINT-3.md)
- [Tracking Sprint 3](../../tracking/SPRINT-3-TRACKING.md)
- [Decisiones Sprint 3](./DECISIONES.md)

### Sprints Anteriores
- [Sprint 0 - Setup](../sprint-0/SPRINT-0-PLAN.md)
- [Sprint 1 - Foundation](../sprint-1/SPRINT-1-PLAN.md)
- [Sprint 2 - Observability & Storage](../sprint-2/SPRINT-2-PLAN.md)

### Guías Técnicas
- [Arquitectura del Proyecto](../../../01-arquitectura.md)
- [Swift 6 Concurrency Rules](../../../SWIFT6-CONCURRENCY-RULES.md)
- [Repository Pattern Guide](../../../guides/repository-pattern.md)
- [Networking Guide](../../../guides/networking-guide.md)
- [SwiftData Guide](../../../guides/swiftdata-guide.md)

### Apple Documentation
- [Swift Package Manager](https://swift.org/package-manager/)
- [Local Package Dependencies](https://developer.apple.com/documentation/xcode/organizing-your-code-with-local-packages)
- [SwiftData](https://developer.apple.com/documentation/swiftdata)
- [URLSession](https://developer.apple.com/documentation/foundation/urlsession)

---

**Última actualización**: 2025-11-30  
**Autor**: Claude (Anthropic)  
**Versión**: 1.0
