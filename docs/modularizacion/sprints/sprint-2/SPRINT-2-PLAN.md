# Sprint 2: Infraestructura Nivel 1 - Observability & Security

**Duración**: 5 días (4 días desarrollo + 1 día buffer)  
**Fecha Inicio Estimada**: 2025-12-09  
**Fecha Fin Estimada**: 2025-12-13

---

## 🎯 Objetivos del Sprint

1. Crear módulo **EduGoObservability** (~2,655 líneas)
   - Migrar sistema de Logging completo
   - Migrar sistema de Analytics
   - Integrar Performance monitoring
2. Crear módulo **EduGoSecureStorage** (~300 líneas)
   - Migrar KeychainService
   - Migrar BiometricAuthService
   - Preparar infraestructura de encriptación
3. Actualizar app principal para usar los nuevos módulos
4. Mantener 100% de tests pasando en todas las plataformas

**Criterio de Éxito**: Proyecto compila con 5 módulos (Foundation + DesignSystem + DomainCore + Observability + SecureStorage) en iOS + macOS con tests al 100%

---

## 📋 Pre-requisitos

- [x] Sprint 0 completado (Setup SPM)
- [x] Sprint 1 completado (EduGoFoundation, EduGoDesignSystem, EduGoDomainCore)
- [ ] Módulos disponibles: EduGoFoundation, EduGoDesignSystem, EduGoDomainCore
- [ ] Rama `dev` actualizada
- [ ] Xcode 16.2+ instalado
- [ ] Lectura de `REGLAS-MODULARIZACION.md`

---

## 🗂️ Estructura a Crear

### 1. EduGoObservability Package

```
Packages/EduGoObservability/
├── Package.swift
├── Sources/
│   └── EduGoObservability/
│       ├── Logging/
│       │   ├── Core/
│       │   │   ├── Logger.swift               # Protocol (migrar desde Core/Logging/)
│       │   │   ├── LogCategory.swift          # Enum de categorías
│       │   │   └── LoggerFactory.swift        # Factory
│       │   ├── Providers/
│       │   │   ├── OSLogger.swift             # OSLog implementation
│       │   │   ├── MockLogger.swift           # Testing logger
│       │   │   └── LoggerExtensions.swift     # Extensions convenientes
│       │   └── Formatters/
│       │       └── (futuro: JSONFormatter, etc)
│       ├── Analytics/
│       │   ├── Core/
│       │   │   ├── AnalyticsEvent.swift       # Migrar desde Domain/Services/Analytics/
│       │   │   ├── AnalyticsService.swift     # Protocol
│       │   │   ├── AnalyticsUserProperty.swift
│       │   │   └── AnalyticsManager.swift     # Migrar desde Data/Services/Analytics/
│       │   ├── Providers/
│       │   │   ├── AnalyticsProvider.swift
│       │   │   ├── FirebaseAnalyticsProvider.swift
│       │   │   ├── ConsoleAnalyticsProvider.swift
│       │   │   └── NoOpAnalyticsProvider.swift
│       │   └── Privacy/
│       │       └── AnalyticsManager+ATT.swift  # App Tracking Transparency
│       └── Performance/
│           ├── LaunchTimeTracker.swift        # Migrar desde Data/Services/Performance/
│           ├── MemoryMonitor.swift
│           ├── NetworkMetricsTracker.swift
│           └── DefaultPerformanceMonitor.swift
└── Tests/
    └── EduGoObservabilityTests/
        ├── LoggerTests.swift
        ├── AnalyticsTests.swift
        └── PerformanceTests.swift
```

**Archivos a migrar**:
- `apple-app/Core/Logging/` → `Logging/Core/` y `Logging/Providers/` (6 archivos, ~850 líneas)
- `apple-app/Domain/Services/Analytics/` → `Analytics/Core/` (3 archivos, ~378 líneas)
- `apple-app/Data/Services/Analytics/` → `Analytics/Core/` y `Analytics/Providers/` (6 archivos, ~756 líneas)
- `apple-app/Data/Services/Performance/` → `Performance/` (4 archivos, ~671 líneas)

**Total estimado**: ~2,655 líneas

---

### 2. EduGoSecureStorage Package

```
Packages/EduGoSecureStorage/
├── Package.swift
├── Sources/
│   └── EduGoSecureStorage/
│       ├── Keychain/
│       │   ├── KeychainService.swift          # Migrar desde Data/Services/
│       │   └── KeychainError.swift            # (si existe separado)
│       ├── Biometric/
│       │   └── BiometricAuthService.swift     # Migrar desde Data/Services/Auth/
│       └── Encryption/
│           └── (futuro: CryptoKit wrappers)
└── Tests/
    └── EduGoSecureStorageTests/
        ├── KeychainServiceTests.swift
        └── BiometricAuthServiceTests.swift
```

**Archivos a migrar**:
- `apple-app/Data/Services/KeychainService.swift` → `Keychain/` (~134 líneas)
- `apple-app/Data/Services/Auth/BiometricAuthService.swift` → `Biometric/` (~166 líneas)

**Total estimado**: ~300 líneas

---

## 📝 Tareas Detalladas

### Tarea 1: Preparación (30 min)

**Objetivo**: Configurar entorno para Sprint 2

**Pasos**:

1. Verificar estado del proyecto:
   ```bash
   git checkout dev
   git pull origin dev
   git status
   ```

2. Verificar módulos del Sprint 1:
   ```bash
   ls -la Packages/
   # Debe mostrar: EduGoFoundation, EduGoDesignSystem, EduGoDomainCore
   ```

3. Crear rama del sprint:
   ```bash
   git checkout -b feature/modularization-sprint-2-observability-security
   ```

4. Limpiar DerivedData:
   ```bash
   ./scripts/clean-all.sh
   ```

5. Compilar estado inicial:
   ```bash
   ./scripts/validate-all-platforms.sh
   ```

**Validación**:
- [ ] Estás en rama `feature/modularization-sprint-2-observability-security`
- [ ] 3 módulos del Sprint 1 presentes
- [ ] Proyecto compila en iOS y macOS
- [ ] Tests pasan al 100%

---

### Tarea 2: Crear EduGoObservability Package (60 min)

**Objetivo**: Crear estructura del módulo Observability

**Pasos**:

1. Crear estructura de carpetas:
   ```bash
   cd Packages
   mkdir -p EduGoObservability/Sources/EduGoObservability/{Logging/{Core,Providers,Formatters},Analytics/{Core,Providers,Privacy},Performance}
   mkdir -p EduGoObservability/Tests/EduGoObservabilityTests
   ```

2. Crear `Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EduGoObservability",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoObservability",
            targets: ["EduGoObservability"]
        )
    ],
    dependencies: [
        .package(path: "../EduGoFoundation"),
        .package(path: "../EduGoDomainCore")
    ],
    targets: [
        .target(
            name: "EduGoObservability",
            dependencies: [
                "EduGoFoundation",
                "EduGoDomainCore"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EduGoObservabilityTests",
            dependencies: ["EduGoObservability"]
        )
    ]
)
```

3. Commitear estructura:
   ```bash
   git add Packages/EduGoObservability/
   git commit -m "feat(observability): Create EduGoObservability package structure"
   ```

**Validación**:
- [ ] Estructura de carpetas creada
- [ ] Package.swift válido
- [ ] Commit realizado

---

### Tarea 3: Migrar Logging a EduGoObservability (90 min)

**Objetivo**: Mover sistema completo de logging al nuevo módulo

**Pasos**:

1. **Copiar archivos de Logging**:
   ```bash
   # Core
   cp apple-app/Core/Logging/Logger.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Logging/Core/
   
   cp apple-app/Core/Logging/LogCategory.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Logging/Core/
   
   cp apple-app/Core/Logging/LoggerFactory.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Logging/Core/
   
   # Providers
   cp apple-app/Core/Logging/OSLogger.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Logging/Providers/
   
   cp apple-app/Core/Logging/MockLogger.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Logging/Providers/
   
   cp apple-app/Core/Logging/LoggerExtensions.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Logging/Providers/
   ```

2. **Ajustar imports en archivos migrados**:
   - Abrir cada archivo en Xcode
   - Cambiar imports según necesidad:
     ```swift
     // ANTES
     import Foundation
     
     // DESPUÉS (si usa extensions de Foundation)
     import Foundation
     import EduGoFoundation  // Si usa helpers/extensions
     ```

3. **Compilar módulo**:
   ```bash
   cd Packages/EduGoObservability
   swift build
   ```

4. **Corregir errores de compilación**:
   - Resolver dependencias faltantes
   - Ajustar niveles de acceso (`public` para APIs expuestas)
   - Verificar conformidad con Swift 6 Concurrency

5. **Commitear migración**:
   ```bash
   git add Packages/EduGoObservability/
   git commit -m "feat(observability): Migrate logging system to EduGoObservability"
   ```

**Validación**:
- [ ] 6 archivos de logging migrados
- [ ] Módulo compila sin errores
- [ ] APIs marcadas como `public`
- [ ] Commit realizado

---

### Tarea 4: Migrar Analytics y Performance a EduGoObservability (90 min)

**Objetivo**: Completar módulo Observability con Analytics y Performance

**Pasos Analytics**:

1. **Copiar archivos Domain**:
   ```bash
   # Core Analytics (Domain)
   cp apple-app/Domain/Services/Analytics/AnalyticsEvent.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Analytics/Core/
   
   cp apple-app/Domain/Services/Analytics/AnalyticsService.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Analytics/Core/
   
   cp apple-app/Domain/Services/Analytics/AnalyticsUserProperty.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Analytics/Core/
   ```

2. **Copiar archivos Data**:
   ```bash
   # Manager
   cp apple-app/Data/Services/Analytics/AnalyticsManager.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Analytics/Core/
   
   cp apple-app/Data/Services/Analytics/AnalyticsManager+ATT.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Analytics/Privacy/
   
   # Providers
   cp apple-app/Data/Services/Analytics/Providers/AnalyticsProvider.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Analytics/Providers/
   
   cp apple-app/Data/Services/Analytics/Providers/FirebaseAnalyticsProvider.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Analytics/Providers/
   
   cp apple-app/Data/Services/Analytics/Providers/ConsoleAnalyticsProvider.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Analytics/Providers/
   
   cp apple-app/Data/Services/Analytics/Providers/NoOpAnalyticsProvider.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Analytics/Providers/
   ```

**Pasos Performance**:

3. **Copiar archivos Performance**:
   ```bash
   cp apple-app/Data/Services/Performance/LaunchTimeTracker.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Performance/
   
   cp apple-app/Data/Services/Performance/MemoryMonitor.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Performance/
   
   cp apple-app/Data/Services/Performance/NetworkMetricsTracker.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Performance/
   
   cp apple-app/Data/Services/Performance/DefaultPerformanceMonitor.swift \
      Packages/EduGoObservability/Sources/EduGoObservability/Performance/
   ```

4. **Ajustar imports y dependencias**:
   - Actualizar imports en archivos migrados
   - Usar `EduGoDomainCore` para domain errors
   - Marcar APIs públicas con `public`

5. **Compilar módulo completo**:
   ```bash
   cd Packages/EduGoObservability
   swift build
   ```

6. **Commitear**:
   ```bash
   git add Packages/EduGoObservability/
   git commit -m "feat(observability): Add Analytics and Performance monitoring"
   ```

**Validación**:
- [ ] 9 archivos de Analytics migrados
- [ ] 4 archivos de Performance migrados
- [ ] Módulo compila sin errores
- [ ] Commit realizado

---

### Tarea 5: Crear EduGoSecureStorage Package (45 min)

**Objetivo**: Crear módulo de almacenamiento seguro

**Pasos**:

1. **Crear estructura**:
   ```bash
   cd Packages
   mkdir -p EduGoSecureStorage/Sources/EduGoSecureStorage/{Keychain,Biometric,Encryption}
   mkdir -p EduGoSecureStorage/Tests/EduGoSecureStorageTests
   ```

2. **Crear Package.swift**:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EduGoSecureStorage",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoSecureStorage",
            targets: ["EduGoSecureStorage"]
        )
    ],
    dependencies: [
        .package(path: "../EduGoFoundation"),
        .package(path: "../EduGoDomainCore"),
        .package(path: "../EduGoObservability")  // Para logging
    ],
    targets: [
        .target(
            name: "EduGoSecureStorage",
            dependencies: [
                "EduGoFoundation",
                "EduGoDomainCore",
                "EduGoObservability"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EduGoSecureStorageTests",
            dependencies: ["EduGoSecureStorage"]
        )
    ]
)
```

3. **Commitear estructura**:
   ```bash
   git add Packages/EduGoSecureStorage/
   git commit -m "feat(security): Create EduGoSecureStorage package structure"
   ```

**Validación**:
- [ ] Estructura creada
- [ ] Package.swift válido
- [ ] Commit realizado

---

### Tarea 6: Migrar Keychain y Biometric a EduGoSecureStorage (60 min)

**Objetivo**: Mover servicios de seguridad al nuevo módulo

**Pasos**:

1. **Copiar archivos**:
   ```bash
   # Keychain
   cp apple-app/Data/Services/KeychainService.swift \
      Packages/EduGoSecureStorage/Sources/EduGoSecureStorage/Keychain/
   
   # Biometric
   cp apple-app/Data/Services/Auth/BiometricAuthService.swift \
      Packages/EduGoSecureStorage/Sources/EduGoSecureStorage/Biometric/
   ```

2. **Ajustar imports**:
   ```swift
   // En KeychainService.swift y BiometricAuthService.swift
   import Foundation
   import Security  // Para Keychain
   import LocalAuthentication  // Para biometría
   import EduGoFoundation
   import EduGoDomainCore
   import EduGoObservability  // Para logging
   ```

3. **Marcar APIs públicas**:
   - `KeychainService` → `public final class`
   - Métodos públicos → `public func`
   - `BiometricAuthService` → `public final class`

4. **Compilar**:
   ```bash
   cd Packages/EduGoSecureStorage
   swift build
   ```

5. **Crear placeholder de Encryption**:
   ```bash
   touch Packages/EduGoSecureStorage/Sources/EduGoSecureStorage/Encryption/.gitkeep
   ```

6. **Commitear**:
   ```bash
   git add Packages/EduGoSecureStorage/
   git commit -m "feat(security): Migrate Keychain and Biometric services"
   ```

**Validación**:
- [ ] 2 archivos migrados
- [ ] Módulo compila
- [ ] APIs públicas correctas
- [ ] Commit realizado

---

### Tarea 7: Actualizar Dependencias en App Principal (45 min)

**Objetivo**: Conectar app con nuevos módulos

**Pasos**:

1. **Agregar packages en Xcode**:
   - Abrir `apple-app.xcodeproj`
   - File → Add Package Dependencies → Add Local
   - Seleccionar `Packages/EduGoObservability`
   - Seleccionar `Packages/EduGoSecureStorage`
   - En target `apple-app`, agregar en "Frameworks and Libraries":
     - `EduGoObservability`
     - `EduGoSecureStorage`

2. **Actualizar imports en archivos que usaban el código migrado**:

   Ejemplo en archivos que usan logging:
   ```swift
   // ANTES
   // (imports implícitos dentro del target)
   
   // DESPUÉS
   import EduGoObservability
   ```

   Ejemplo en archivos que usan Analytics:
   ```swift
   import EduGoObservability  // Para AnalyticsManager, AnalyticsEvent
   ```

   Ejemplo en archivos que usan Keychain:
   ```swift
   import EduGoSecureStorage  // Para KeychainService, BiometricAuthService
   ```

3. **Buscar y actualizar todos los imports**:
   ```bash
   # Buscar archivos que usan Logger
   grep -r "LoggerFactory" apple-app/ --include="*.swift" | cut -d: -f1 | sort -u
   
   # Buscar archivos que usan Analytics
   grep -r "AnalyticsManager\|AnalyticsEvent" apple-app/ --include="*.swift" | cut -d: -f1 | sort -u
   
   # Buscar archivos que usan Keychain
   grep -r "KeychainService\|BiometricAuthService" apple-app/ --include="*.swift" | cut -d: -f1 | sort -u
   ```

4. **Compilar app**:
   ```bash
   ./scripts/validate-all-platforms.sh
   ```

**Validación**:
- [ ] Packages agregados en Xcode
- [ ] Imports actualizados
- [ ] App compila en iOS y macOS
- [ ] Sin warnings de módulos faltantes

**⚠️ NO commitear aún** - Esperamos completar todos los cambios

---

### Tarea 8: Refactorizar Código Existente (90 min)

**Objetivo**: Adaptar código que depende de los archivos migrados

**Pasos**:

1. **Actualizar DependencyContainer**:
   
   En `apple-app/Core/DI/DependencyContainer.swift` o similar:
   ```swift
   import EduGoObservability
   import EduGoSecureStorage
   
   // Actualizar registro de dependencias
   extension DependencyContainer {
       func setupInfrastructure() {
           // Logging
           let logger = LoggerFactory.shared  // Ahora desde EduGoObservability
           
           // Analytics
           let analytics = AnalyticsManager(...)  // Desde EduGoObservability
           
           // Security
           let keychain = KeychainService()  // Desde EduGoSecureStorage
           let biometric = BiometricAuthService(...)  // Desde EduGoSecureStorage
       }
   }
   ```

2. **Actualizar DependencyContainer+Analytics.swift** (si existe):
   ```swift
   // apple-app/Core/DI/DependencyContainer+Analytics.swift
   import EduGoObservability
   
   extension DependencyContainer {
       // Código ya debería funcionar con import correcto
   }
   ```

3. **Eliminar archivos originales del target**:
   
   ⚠️ **IMPORTANTE**: NO borrar físicamente, solo remover del target de Xcode
   
   - Abrir proyecto en Xcode
   - Seleccionar archivos migrados (Core/Logging/, Data/Services/Analytics/, etc.)
   - Click derecho → Delete → "Remove Reference" (NO "Move to Trash")
   
   Esto mantiene archivos en disco pero los excluye de compilación.

4. **Compilar nuevamente**:
   ```bash
   ./scripts/validate-all-platforms.sh
   ```

5. **Resolver errores**:
   - Imports faltantes
   - Niveles de acceso
   - Dependencias circulares (no deberían existir)

6. **Commitear cambios**:
   ```bash
   git add apple-app/
   git commit -m "refactor: Update app to use EduGoObservability and EduGoSecureStorage"
   ```

**Validación**:
- [ ] Imports actualizados en toda la app
- [ ] Archivos originales removidos del target
- [ ] App compila sin errores
- [ ] Commit realizado

---

### Tarea 9: Validación Multi-Plataforma (30 min)

**Objetivo**: Asegurar compilación en todas las plataformas

**Pasos**:

1. **Limpiar todo**:
   ```bash
   ./scripts/clean-all.sh
   ```

2. **Compilar iOS**:
   ```bash
   xcodebuild -scheme EduGo-Dev \
     -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
     clean build
   ```

3. **Compilar macOS**:
   ```bash
   xcodebuild -scheme EduGo-Dev \
     -destination 'platform=macOS' \
     clean build
   ```

4. **Script completo**:
   ```bash
   ./scripts/validate-all-platforms.sh
   ```

5. **Revisar warnings**:
   - Verificar que no hay nuevos warnings
   - Documentar warnings conocidos si existen

**Validación**:
- [ ] iOS compila sin errores
- [ ] macOS compila sin errores
- [ ] Sin nuevos warnings críticos
- [ ] Script de validación exitoso

---

### Tarea 10: Tests de Integración (60 min)

**Objetivo**: Asegurar que tests existentes pasan con nueva estructura

**Pasos**:

1. **Migrar tests de módulos**:
   
   ```bash
   # LoggerTests
   cp apple-appTests/Core/LoggingTests/LoggerTests.swift \
      Packages/EduGoObservability/Tests/EduGoObservabilityTests/
   
   cp apple-appTests/Core/LoggingTests/PrivacyTests.swift \
      Packages/EduGoObservability/Tests/EduGoObservabilityTests/
   
   # KeychainTests
   cp apple-appTests/DataTests/KeychainServiceTests.swift \
      Packages/EduGoSecureStorage/Tests/EduGoSecureStorageTests/
   
   # BiometricTests
   cp apple-appTests/Data/Services/BiometricAuthServiceTests.swift \
      Packages/EduGoSecureStorage/Tests/EduGoSecureStorageTests/
   ```

2. **Ajustar imports en tests**:
   ```swift
   @testable import EduGoObservability
   @testable import EduGoSecureStorage
   ```

3. **Ejecutar tests de módulos**:
   ```bash
   cd Packages/EduGoObservability
   swift test
   
   cd ../EduGoSecureStorage
   swift test
   ```

4. **Ejecutar tests de app**:
   ```bash
   ./run.sh test
   ```

5. **Corregir fallos**:
   - Actualizar mocks si necesario
   - Ajustar imports en tests
   - Resolver dependencias faltantes

6. **Commitear tests**:
   ```bash
   git add Packages/*/Tests/
   git add apple-appTests/
   git commit -m "test: Migrate and update tests for new modules"
   ```

**Validación**:
- [ ] Tests de EduGoObservability pasan
- [ ] Tests de EduGoSecureStorage pasan
- [ ] Tests de app pasan (100%)
- [ ] Commit realizado

---

### Tarea 11: Documentación (45 min)

**Objetivo**: Documentar los nuevos módulos

**Pasos**:

1. **Crear README para EduGoObservability**:

```bash
cat > Packages/EduGoObservability/README.md << 'EOF'
# EduGoObservability

Sistema unificado de observabilidad para EduGo Apple App.

## Componentes

### 📝 Logging
- **Logger Protocol**: API consistente para logging
- **LoggerFactory**: Factory centralizada
- **OSLogger**: Implementación con os.Logger
- **MockLogger**: Logger para testing

### 📊 Analytics
- **AnalyticsManager**: Gestor principal de analytics
- **AnalyticsEvent**: Eventos tipados
- **Providers**: Firebase, Console, NoOp
- **Privacy**: Soporte ATT (App Tracking Transparency)

### ⚡ Performance
- **LaunchTimeTracker**: Medición de tiempo de launch
- **MemoryMonitor**: Monitoreo de memoria
- **NetworkMetricsTracker**: Métricas de red
- **DefaultPerformanceMonitor**: Monitor unificado

## Dependencias
- `EduGoFoundation` - Extensions y helpers
- `EduGoDomainCore` - Domain errors y entities

## Uso

\`\`\`swift
import EduGoObservability

// Logging
let logger = LoggerFactory.network
await logger.info("Request started")

// Analytics
let analytics = AnalyticsManager(...)
await analytics.track(.userLoggedIn)

// Performance
let monitor = DefaultPerformanceMonitor()
await monitor.start()
\`\`\`

## Testing
\`\`\`bash
swift test
\`\`\`
EOF
```

2. **Crear README para EduGoSecureStorage**:

```bash
cat > Packages/EduGoSecureStorage/README.md << 'EOF'
# EduGoSecureStorage

Almacenamiento seguro y servicios biométricos para EduGo Apple App.

## Componentes

### 🔐 Keychain
- **KeychainService**: CRUD en Keychain de Apple
- Thread-safe con actors
- Soporte multi-plataforma (iOS, macOS)

### 👤 Biometric
- **BiometricAuthService**: Face ID / Touch ID
- Manejo de errores robusto
- Fallback a password

### 🔒 Encryption
- (Futuro) Wrappers de CryptoKit

## Dependencias
- `EduGoFoundation`
- `EduGoDomainCore`
- `EduGoObservability` (para logging)

## Uso

\`\`\`swift
import EduGoSecureStorage

// Keychain
let keychain = KeychainService()
try await keychain.save(token, forKey: "auth_token")

// Biometric
let biometric = BiometricAuthService()
let result = await biometric.authenticate()
\`\`\`

## Testing
\`\`\`bash
swift test
\`\`\`
EOF
```

3. **Actualizar documentación principal**:
   - Editar `docs/modularizacion/PLAN-MAESTRO.md`
   - Marcar Sprint 2 como completado cuando termine

4. **Commitear documentación**:
   ```bash
   git add Packages/*/README.md
   git add docs/
   git commit -m "docs: Add documentation for EduGoObservability and EduGoSecureStorage"
   ```

**Validación**:
- [ ] README de EduGoObservability creado
- [ ] README de EduGoSecureStorage creado
- [ ] Documentación actualizada
- [ ] Commit realizado

---

### Tarea 12: Tracking y Crear PR (30 min)

**Objetivo**: Cerrar Sprint 2 y crear Pull Request

**Pasos**:

1. **Actualizar tracking**:
   ```bash
   # Editar docs/modularizacion/tracking/SPRINT-2-TRACKING.md
   # Marcar todas las tareas como completadas
   # Actualizar métricas
   ```

2. **Revisar diff completo**:
   ```bash
   git log --oneline dev..HEAD
   git diff dev...HEAD --stat
   ```

3. **Compilación final**:
   ```bash
   ./scripts/clean-all.sh
   ./scripts/validate-all-platforms.sh
   ./run.sh test
   ```

4. **Verificar commits**:
   - Commits atómicos y descriptivos
   - Sin código comentado innecesario
   - Sin archivos temporales

5. **Crear PR en GitHub**:
   - Título: `[Sprint 2] Add EduGoObservability and EduGoSecureStorage modules`
   - Descripción:
     ```markdown
     ## Sprint 2: Infraestructura Nivel 1
     
     ### Módulos Creados
     - ✅ EduGoObservability (~2,655 líneas)
       - Logging system completo
       - Analytics con Firebase/Console/NoOp providers
       - Performance monitoring
     - ✅ EduGoSecureStorage (~300 líneas)
       - KeychainService
       - BiometricAuthService
     
     ### Migración
     - Movidos 19 archivos a nuevos módulos
     - Actualizados imports en app principal
     - Tests migrados y pasando al 100%
     
     ### Validación
     - ✅ iOS 18+ compila
     - ✅ macOS 15+ compila
     - ✅ Tests: 100% pasan
     - ✅ Sin nuevos warnings
     
     ### Dependencias
     Usa módulos del Sprint 1:
     - EduGoFoundation
     - EduGoDesignSystem
     - EduGoDomainCore
     ```
   - Labels: `modularization`, `sprint-2`, `infrastructure`
   - Reviewers: Equipo técnico

6. **Commitear tracking**:
   ```bash
   git add docs/modularizacion/tracking/SPRINT-2-TRACKING.md
   git commit -m "docs: Complete Sprint 2 tracking"
   git push origin feature/modularization-sprint-2-observability-security
   ```

**Validación**:
- [ ] Tracking actualizado
- [ ] Diff revisado
- [ ] Compilación final exitosa
- [ ] Tests al 100%
- [ ] PR creado
- [ ] Tracking commiteado

---

## ⚠️ Configuración Manual Xcode

Este sprint NO requiere configuración manual compleja en Xcode.

**Proceso automatizado**:
- Agregar packages locales: File → Add Package Dependencies → Add Local
- Seleccionar carpetas de packages
- Agregar a target en "Frameworks and Libraries"

Ya conocemos este proceso del Sprint 1. 

**⏸️ PAUSAR** solo si encuentras errores inesperados de workspace.

---

## 📊 Estimación de Tiempos

| Tarea | Tiempo Estimado | Notas |
|-------|-----------------|-------|
| 1. Preparación | 30 min | Setup sprint |
| 2. Crear EduGoObservability | 60 min | Estructura + Package.swift |
| 3. Migrar Logging | 90 min | 6 archivos + ajustes |
| 4. Migrar Analytics/Performance | 90 min | 13 archivos + ajustes |
| 5. Crear EduGoSecureStorage | 45 min | Estructura + Package.swift |
| 6. Migrar Keychain/Biometric | 60 min | 2 archivos + ajustes |
| 7. Actualizar dependencias app | 45 min | Xcode + imports |
| 8. Refactorizar código | 90 min | DI + eliminar referencias |
| 9. Validación multi-plataforma | 30 min | iOS + macOS |
| 10. Tests integración | 60 min | Migrar + ejecutar tests |
| 11. Documentación | 45 min | READMEs |
| 12. Tracking y PR | 30 min | Cierre sprint |
| **TOTAL** | **11 horas** | ~3 días (considerando interrupciones) |

**Buffer**: 1.5 días adicionales = **5 días totales**

---

## ✅ Definition of Done

### Módulos
- [ ] EduGoObservability package creado y compila
  - [ ] Logging (6 archivos migrados)
  - [ ] Analytics (9 archivos migrados)
  - [ ] Performance (4 archivos migrados)
- [ ] EduGoSecureStorage package creado y compila
  - [ ] Keychain (1 archivo migrado)
  - [ ] Biometric (1 archivo migrado)

### Integración
- [ ] App principal usa `import EduGoObservability`
- [ ] App principal usa `import EduGoSecureStorage`
- [ ] Archivos originales removidos del target (no borrados)
- [ ] DependencyContainer actualizado

### Calidad
- [ ] Proyecto compila en iOS 18+
- [ ] Proyecto compila en macOS 15+
- [ ] Tests de módulos pasan (100%)
- [ ] Tests de app pasan (100%)
- [ ] Sin nuevos warnings críticos
- [ ] Swift 6 Concurrency habilitado

### Documentación
- [ ] README.md en EduGoObservability
- [ ] README.md en EduGoSecureStorage
- [ ] Tracking actualizado
- [ ] Plan Maestro actualizado

### Git
- [ ] Commits atómicos y descriptivos
- [ ] PR creado con descripción completa
- [ ] Sin archivos temporales commitados
- [ ] Sin conflictos con `dev`

---

## 🔗 Referencias

- **Reglas**: [REGLAS-MODULARIZACION.md](../../REGLAS-MODULARIZACION.md)
- **Plan Maestro**: [PLAN-MAESTRO.md](../../PLAN-MAESTRO.md)
- **Sprint 1**: [SPRINT-1-PLAN.md](../sprint-1/SPRINT-1-PLAN.md)
- **Tracking**: [SPRINT-2-TRACKING.md](../../tracking/SPRINT-2-TRACKING.md)

---

## 📝 Notas

### Decisiones Clave

1. **Fusión de Logging y Analytics en EduGoObservability**:
   - Ambos son cross-cutting concerns
   - Comparten concepto de observabilidad
   - Reduce número de módulos (8 en lugar de 9-10)

2. **EduGoSecureStorage depende de EduGoObservability**:
   - Para logging de operaciones de keychain
   - Permite auditar accesos a datos sensibles
   - No genera ciclo (Observability no depende de SecureStorage)

3. **Archivos removidos del target, NO borrados**:
   - Mantiene historial git limpio
   - Permite rollback fácil si necesario
   - Se borrarán físicamente en Sprint final de cleanup

### Riesgos Mitigados

- **Dependencias circulares**: Evitadas con diseño correcto (Observability → Foundation/Domain, SecureStorage → Observability)
- **Tests rotos**: Migrados y ajustados proactivamente
- **Imports rotos**: Búsqueda sistemática con grep antes de refactor

---

**¡Éxito en el Sprint 2!** 🚀
